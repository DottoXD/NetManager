package pw.dotto.netmanager.Core.Base;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telephony.PhoneStateListener;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import androidx.core.content.ContextCompat;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import pw.dotto.netmanager.Core.Listeners.CellInfoListener;
import pw.dotto.netmanager.Core.Listeners.DataStateListener;
import pw.dotto.netmanager.Core.Listeners.DisplayInfoListener;
import pw.dotto.netmanager.Core.Listeners.LegacyPhoneStateListener;
import pw.dotto.netmanager.Core.Listeners.ServiceStateListener;
import pw.dotto.netmanager.Core.Listeners.SignalStrengthsListener;
import pw.dotto.netmanager.Core.Listeners.SubscriptionChangedListener;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Permissions;

/**
 * NetManager's SubscriptionTracker is a core component which tracks all updates
 * to the various SIM card slots (subscriptions) and properly manages them by
 * mapping their respective listeners or disposing them.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class SubscriptionTracker {
    private final Context context;
    private final Map<Integer, SIMSlotState> simSlots = new ConcurrentHashMap<>();
    private final SimReceiverManager simReceiverManager;
    private SubscriptionChangedListener subscriptionChangedListener;
    private java.util.function.IntConsumer onSlotRemoved;

    public void setOnSlotRemovedListener(java.util.function.IntConsumer listener) {
        this.onSlotRemoved = listener;
    }

    public SubscriptionTracker(Context context) {
        this.context = context.getApplicationContext();

        this.simReceiverManager = SimReceiverManager.getInstance(this.context);
        this.simReceiverManager.registerStateReceiver(this::refresh);

        SubscriptionManager subscriptionManager = getSubscriptionManager();

        if (subscriptionManager != null) {
            subscriptionChangedListener = new SubscriptionChangedListener(this::refresh);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                subscriptionManager.addOnSubscriptionsChangedListener(
                        this.context.getMainExecutor(), subscriptionChangedListener);
            } else {
                subscriptionManager.addOnSubscriptionsChangedListener(subscriptionChangedListener);
            }
        }

        refresh();
    }

    private SubscriptionManager getSubscriptionManager() {
        return (SubscriptionManager) context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
    }

    private TelephonyManager getTelephony() {
        return (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
    }

    @SuppressLint("MissingPermission")
    public void refresh() {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            new Handler(Looper.getMainLooper()).post(this::refresh);
            return;
        }

        synchronized (this) {
            if (!Permissions.check(context, Permissions.READ_PHONE_STATE)) {
                destroyAll();
                return;
            }

            SubscriptionManager manager = getSubscriptionManager();
            List<SubscriptionInfo> subscriptions = manager == null ? null : manager.getActiveSubscriptionInfoList();

            if (subscriptions == null || subscriptions.isEmpty()) {
                destroyAll();
                return;
            }

            Set<Integer> seenSlotIds = new HashSet<>();

            for (SubscriptionInfo info : subscriptions) {
                int slotId = info.getSimSlotIndex();
                seenSlotIds.add(slotId);

                SIMSlotState simSlotState = simSlots.computeIfAbsent(slotId, SIMSlotState::new);

                boolean subscriptionSwapped = simSlotState.subscriptionId != info.getSubscriptionId();
                if (subscriptionSwapped || simSlotState.telephony == null) {
                    unregisterCallbacks(simSlotState);

                    if (simSlotState.physicalChannelDumper != null) {
                        simSlotState.physicalChannelDumper.dispose();
                        simSlotState.physicalChannelDumper = null;
                    }

                    simSlotState.latestSnapshot = null;

                    try {
                        TelephonyManager base = getTelephony();
                        simSlotState.telephony = base == null ? null
                                : base.createForSubscriptionId(info.getSubscriptionId());
                        simSlotState.subscriptionId = info.getSubscriptionId();
                        simSlotState.simId = slotId;
                    } catch (Exception e) {
                        simSlotState.telephony = null;
                        DebugLogger.add("Failed creating a TelephonyManager for slot "
                                + slotId + ": " + e.getMessage() + ".");
                        continue;
                    }

                    registerCallbacks(simSlotState);

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S
                            && !simSlotState.hasTelephonyCallbacksRegistered()) {
                        DebugLogger.add("Callbacks registration failed for SIM slot " + slotId + ".");
                    }
                }
            }

            for (Integer knownSimId : new HashSet<>(simSlots.keySet())) {
                if (!seenSlotIds.contains(knownSimId)) {
                    SIMSlotState slot = simSlots.remove(knownSimId);

                    if (slot != null) {
                        unregisterCallbacks(slot);
                        if (slot.physicalChannelDumper != null)
                            slot.physicalChannelDumper.dispose();
                        if (onSlotRemoved != null)
                            onSlotRemoved.accept(knownSimId);
                    }
                }
            }
        }
    }

    private void registerCallbacks(SIMSlotState simSlotState) {
        if (simSlotState.telephony == null)
            return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Executor executor = ContextCompat.getMainExecutor(context);
            if (executor == null)
                return;

            try {
                simSlotState.nsaListener = new DisplayInfoListener();
                simSlotState.serviceStateListener = new ServiceStateListener();
                simSlotState.dataStateListener = new DataStateListener();
                simSlotState.signalStrengthsListener = new SignalStrengthsListener();
                simSlotState.cellInfoListener = new CellInfoListener();

                simSlotState.telephony.registerTelephonyCallback(executor, simSlotState.nsaListener);
                simSlotState.telephony.registerTelephonyCallback(executor, simSlotState.serviceStateListener);
                simSlotState.telephony.registerTelephonyCallback(executor, simSlotState.dataStateListener);
                simSlotState.telephony.registerTelephonyCallback(executor, simSlotState.signalStrengthsListener);
                simSlotState.telephony.registerTelephonyCallback(executor, simSlotState.cellInfoListener);
            } catch (Exception e) {
                DebugLogger.add("Callback registration exception for SIM slot "
                        + simSlotState.simId + ": " + e.getMessage() + ".");
            }
        } else {
            try {
                simSlotState.legacyPhoneStateListener = new LegacyPhoneStateListener(simSlotState.subscriptionId);

                int events = PhoneStateListener.LISTEN_SERVICE_STATE
                        | PhoneStateListener.LISTEN_SIGNAL_STRENGTHS
                        | PhoneStateListener.LISTEN_DATA_CONNECTION_STATE | PhoneStateListener.LISTEN_CELL_INFO;

                simSlotState.telephony.listen(simSlotState.legacyPhoneStateListener, events);
            } catch (Exception e) {
                DebugLogger.add("Legacy callback registration exception for SIM slot "
                        + simSlotState.simId + ": " + e.getMessage() + ".");
            }
        }
    }

    private void unregisterCallbacks(SIMSlotState simSlotState) {
        if (simSlotState.telephony == null)
            return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                if (simSlotState.nsaListener != null)
                    simSlotState.telephony.unregisterTelephonyCallback(simSlotState.nsaListener);
                if (simSlotState.serviceStateListener != null)
                    simSlotState.telephony.unregisterTelephonyCallback(simSlotState.serviceStateListener);
                if (simSlotState.dataStateListener != null)
                    simSlotState.telephony.unregisterTelephonyCallback(simSlotState.dataStateListener);
                if (simSlotState.signalStrengthsListener != null)
                    simSlotState.telephony.unregisterTelephonyCallback(simSlotState.signalStrengthsListener);
                if (simSlotState.cellInfoListener != null)
                    simSlotState.telephony.unregisterTelephonyCallback(simSlotState.cellInfoListener);
            } catch (Exception e) {
                DebugLogger.add("Callback unregistration exception for SIM slot "
                        + simSlotState.simId + ": " + e.getMessage() + ".");
            } finally {
                simSlotState.nsaListener = null;
                simSlotState.serviceStateListener = null;
                simSlotState.dataStateListener = null;
                simSlotState.signalStrengthsListener = null;
                simSlotState.cellInfoListener = null;
            }
        } else {
            try {
                if (simSlotState.legacyPhoneStateListener != null)
                    simSlotState.telephony.listen(simSlotState.legacyPhoneStateListener,
                            PhoneStateListener.LISTEN_NONE);
            } catch (Exception e) {
                DebugLogger.add("Legacy callback unregistration exception for SIM slot "
                        + simSlotState.simId + ": " + e.getMessage() + ".");
            } finally {
                simSlotState.legacyPhoneStateListener = null;
            }
        }
    }

    private void destroyAll() {
        for (SIMSlotState slot : simSlots.values()) {
            unregisterCallbacks(slot);
            if (slot.physicalChannelDumper != null)
                slot.physicalChannelDumper.dispose();
        }

        simSlots.clear();
    }

    public Map<Integer, SIMSlotState> getSimSlots() {
        return simSlots;
    }

    public SIMSlotState getSlot(int simId) {
        return simSlots.get(simId);
    }

    public int getSimCount() {
        return simSlots.size();
    }

    public SimReceiverManager getSimReceiverManager() {
        return simReceiverManager;
    }

    public void dispose() {
        SubscriptionManager subscriptionManager = getSubscriptionManager();
        if (subscriptionManager != null && subscriptionChangedListener != null) {
            try {
                subscriptionManager.removeOnSubscriptionsChangedListener(subscriptionChangedListener);
                if (subscriptionChangedListener != null)
                    subscriptionChangedListener.dispose();
            } catch (Exception ignored) {
            }
        }

        simReceiverManager.unregisterStateReceiver();
        SimReceiverManager.releaseInstance();

        destroyAll();
    }
}