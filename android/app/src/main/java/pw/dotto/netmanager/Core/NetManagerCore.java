package pw.dotto.netmanager.Core;

import static android.content.Context.MODE_PRIVATE;

import android.Manifest;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import androidx.annotation.RequiresPermission;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import pw.dotto.netmanager.Core.Base.SIMStateCache;
import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Base.SubscriptionTracker;
import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.EventTypes;
import pw.dotto.netmanager.Core.Events.MobileNetManagerEvent;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellSnapshot;
import pw.dotto.netmanager.Core.Mobile.PhysicalChannelDumper;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Processors.DevicePatchRegistry;
import pw.dotto.netmanager.Core.Processors.Postprocessors.Postprocessor;
import pw.dotto.netmanager.Core.Processors.Preprocessors.Preprocessor;
import pw.dotto.netmanager.Core.Sources.CellDataSource;
import pw.dotto.netmanager.Core.Sources.DataSourceSelector;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.DeviceData;
import pw.dotto.netmanager.Utils.Mobile;
import pw.dotto.netmanager.Utils.Permissions;

/**
 * NetManager's NetManagerCore is the heart of NetManager's data fetching
 * features.
 * This core component manages cache states, events, data fetching, available
 * data sources and pretty much everything else related to mobile cell data.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class NetManagerCore {
    private static volatile NetManagerCore instance;

    public static final int DEFAULT_INTERVAL_SECONDS = 3;

    private final Context appContext;
    private final SubscriptionTracker subscriptionTracker;
    private final SIMStateCache simStateCache = new SIMStateCache();
    private final EventManager eventManager;
    private final DataSourceSelector sourceSelector;
    private final List<Postprocessor> postprocessors;

    private final ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor(
            r -> new Thread(r, "NetManagerCore-poll"));
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private final Map<String, Integer> intervalRequests = new ConcurrentHashMap<>();
    private volatile int currentIntervalSeconds = DEFAULT_INTERVAL_SECONDS;
    private ScheduledFuture<?> pollTask;

    private final Map<String, String> lastEventValues = new ConcurrentHashMap<>();

    public static final String UI_CONSUMER_ID = "ui";

    private NetManagerCore(Context context) {
        this.appContext = context.getApplicationContext();
        this.subscriptionTracker = new SubscriptionTracker(appContext);

        this.eventManager = EventManager.getInstance(appContext);

        SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        DeviceData deviceData = DeviceData.getInstance(sharedPreferences);
        List<Preprocessor> preprocessors = DevicePatchRegistry.preprocessorsFor(deviceData);
        this.postprocessors = DevicePatchRegistry.postprocessorsFor(deviceData);

        CellDataSource telephonySource = new TelephonyCellDataSource(preprocessors);
        this.sourceSelector = new DataSourceSelector(telephonySource);

        this.subscriptionTracker.setOnSlotRemovedListener(simId -> {
            simStateCache.clear(simId);
            lastEventValues.keySet().removeIf(key -> key.startsWith(simId + ":"));
            if (sourceSelector.select() instanceof TelephonyCellDataSource) {
                TelephonyCellDataSource telephonyCellDataSource = (TelephonyCellDataSource) sourceSelector.select();
                telephonyCellDataSource.clearSlotState(simId);
            }
        });

        DebugLogger.add("Created a new NetManagerCore instance!");
    }

    public static NetManagerCore getInstance(Context context) {
        if (instance == null) {
            synchronized (NetManagerCore.class) {
                if (instance == null)
                    instance = new NetManagerCore(context);
            }
        }

        return instance;
    }

    public synchronized void attach(String consumerId, int desiredIntervalSeconds) {
        boolean wasEmpty = intervalRequests.isEmpty();
        intervalRequests.put(consumerId, Math.max(1, desiredIntervalSeconds));
        recomputeInterval();

        DebugLogger.add("Consumer " + consumerId + " just attached to NetManagerCore!");

        if (wasEmpty)
            scheduler.execute(this::pollOnce);
    }

    public synchronized void detach(String consumerId) {
        intervalRequests.remove(consumerId);

        DebugLogger.add("Consumer " + consumerId + " just detached from NetManagerCore!");

        if (intervalRequests.isEmpty())
            stopPolling();
        else
            recomputeInterval();
    }

    public boolean isForegroundActive() {
        return intervalRequests.containsKey(UI_CONSUMER_ID);
    }

    private synchronized void recomputeInterval() {
        int fastest = intervalRequests.values().stream().min(Integer::compare).orElse(DEFAULT_INTERVAL_SECONDS);
        if (pollTask == null || fastest != currentIntervalSeconds) {
            currentIntervalSeconds = fastest;
            if (pollTask != null)
                pollTask.cancel(false);
            pollTask = scheduler.scheduleWithFixedDelay(this::pollOnce, currentIntervalSeconds, currentIntervalSeconds,
                    TimeUnit.SECONDS);
        }
    }

    private synchronized void stopPolling() {
        if (pollTask != null) {
            pollTask.cancel(false);
            pollTask = null;
        }
    }

    @RequiresPermission(Manifest.permission.READ_PHONE_STATE)
    private void pollOnce() {
        for (SIMSlotState simSlotState : subscriptionTracker.getSimSlots().values()) {
            try {
                pollSlot(simSlotState);
            } catch (Exception e) {
                DebugLogger.add(
                        "NetManagerCore poll exception for SIM slot " + simSlotState.simId + ": " + e.getMessage());
            }
        }
    }

    @RequiresPermission(Manifest.permission.READ_PHONE_STATE)
    private void pollSlot(SIMSlotState simSlotState) {
        if (simSlotState.telephony == null)
            return;

        boolean foreground = isForegroundActive();
        updateForegroundTools(simSlotState, foreground);

        CellDataSource source = sourceSelector.select();
        SIMData raw = source.fetch(appContext, simSlotState);
        if (raw == null)
            return;

        SIMData processed = raw;
        for (Postprocessor postprocessor : postprocessors)
            processed = postprocessor.process(processed, simSlotState.simId);

        emitEventsIfChanged(simSlotState, processed);
        simStateCache.updateSimData(simSlotState.simId, processed);

        if (foreground)
            simSlotState.latestSnapshot = buildCellSnapshot(processed);
    }

    private void updateForegroundTools(SIMSlotState slot, boolean foreground) {
        if (foreground) {
            if (slot.physicalChannelDumper == null) {
                mainHandler.post(() -> {
                    if (slot.physicalChannelDumper == null && isForegroundActive()) {
                        try {
                            slot.physicalChannelDumper = new PhysicalChannelDumper(slot.telephony, appContext);
                        } catch (Exception e) {
                            DebugLogger.add("PhysicalChannelDumper registration exception: " + e.getMessage());
                        }
                    }
                });
            }
        } else if (slot.physicalChannelDumper != null) {
            PhysicalChannelDumper dumperToDispose = slot.physicalChannelDumper;
            slot.physicalChannelDumper = null;
            slot.latestSnapshot = null;

            mainHandler.post(() -> {
                try {
                    dumperToDispose.dispose();
                } catch (Exception e) {
                    DebugLogger.add("PhysicalChannelDumper disposal exception: " + e.getMessage());
                }
            });
        }
    }

    @RequiresPermission(Manifest.permission.READ_PHONE_STATE)
    private void emitEventsIfChanged(SIMSlotState slot, SIMData data) {
        int simId = slot.simId;

        int gen = data.getNetworkGen();
        boolean nsa = TelephonyCellDataSource.getNsaStatus(slot, slot.telephony);
        String technology = nsa ? "5G" : (gen > 0 ? gen + "G" : "Unknown");
        emitIfChanged(EventTypes.MOBILE_TECHNOLOGY_CHANGED, simId, technology, data);

        String plmn = TelephonyCellDataSource.getPlmn(appContext, slot.telephony, slot);
        emitIfChanged(EventTypes.MOBILE_PLMN_CHANGED, simId, plmn, data);

        CellData primaryCell = data.getPrimaryCell();
        if (primaryCell != null) {
            String band = (primaryCell instanceof NrCellData ? "N" : "B")
                    + (primaryCell.getBand() == -1 ? primaryCell.getBasicCellData().getBand() : primaryCell.getBand());
            emitIfChanged(EventTypes.MOBILE_BAND_CHANGED, simId, band, data);

            String node;
            try {
                long nodeValue = Long.parseLong(primaryCell.getCellIdentifier()) / Mobile.getFactor(primaryCell);
                node = String.valueOf(nodeValue);
            } catch (Exception ignored) {
                node = "N/A";
            }
            emitIfChanged(EventTypes.MOBILE_NODE_CHANGED, simId, node, data);
        }

        boolean isActiveData;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && slot.telephony != null) {
            isActiveData = (slot.telephony.getSubscriptionId() == SubscriptionManager.getActiveDataSubscriptionId());
        } else {
            isActiveData = false;
            SubscriptionManager sm = (SubscriptionManager) appContext
                    .getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);

            if (sm != null) {
                try {
                    SubscriptionInfo info = sm.getActiveSubscriptionInfoForSimSlotIndex(simId);
                    if (info != null) {
                        int subId = info.getSubscriptionId();

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            isActiveData = (subId == SubscriptionManager.getActiveDataSubscriptionId());
                        } else {
                            isActiveData = (subId == SubscriptionManager.getDefaultDataSubscriptionId());
                        }
                    }
                } catch (Exception ignored) {
                }
            }
        }

        if (isActiveData) {
            String simName = getNetwork(simId);
            if (!simName.equals("NetManager"))
                emitIfChanged(EventTypes.MOBILE_DATA_SIM_CHANGED, simId, simName, data);
        }
    }

    private void emitIfChanged(EventTypes type, int simId, String value, SIMData data) {
        if (value == null)
            return;

        String key = simId + ":" + type;
        String previous = lastEventValues.get(key);
        if (value.equals(previous))
            return;

        lastEventValues.put(key, value);
        if (eventManager != null)
            eventManager.addEvent(new MobileNetManagerEvent(type, value, simId, data.getNetwork()));
    }

    private CellSnapshot buildCellSnapshot(SIMData simData) {
        if (simData == null || simData.getPrimaryCell() == null)
            return null;

        CellData primaryCell = simData.getPrimaryCell();
        int networkGen = simData.getNetworkGen();
        if (networkGen == 4 && simData.getActiveCells().length > 0 && simData.getActiveCells()[0] instanceof NrCellData)
            networkGen++;

        return new CellSnapshot(simData.getNetwork(), primaryCell.getCellIdentifier(),
                primaryCell.getBand() == -1 ? primaryCell.getBasicCellData().getBand() : primaryCell.getBand(),
                networkGen, primaryCell.getRawSignal(), primaryCell.getRawSignalString(),
                primaryCell.getProcessedSignal(), primaryCell.getProcessedSignalString(),
                primaryCell.getChannelNumber(), primaryCell.getChannelNumberString(),
                primaryCell.getStationIdentity(), primaryCell.getStationIdentityString(),
                primaryCell.getAreaCode(), primaryCell.getAreaCodeString(),
                primaryCell.getSignalQuality(), primaryCell.getSignalQualityString(),
                primaryCell.getSignalNoise(), primaryCell.getSignalNoiseString(),
                primaryCell.getTimingAdvance(), primaryCell.getTimingAdvanceString());
    }

    public String getFullHeaderString() {
        if (!Permissions.check(appContext, Permissions.READ_PHONE_STATE))
            return "Unknown";

        Map<Integer, SIMSlotState> slots = subscriptionTracker.getSimSlots();
        if (slots.isEmpty())
            return "No service";

        List<Integer> simIds = new ArrayList<>(slots.keySet());
        Collections.sort(simIds);

        StringBuilder str = new StringBuilder();
        for (int i = 0; i < simIds.size(); i++) {
            SIMSlotState slot = slots.get(simIds.get(i));
            String entry;

            if (slot == null || slot.telephony == null) {
                entry = "Unknown";
            } else {
                int gen = TelephonyCellDataSource.getSimNetworkGen(appContext, slot.telephony);
                boolean nrSa = gen == 5;
                if (gen == 4 && TelephonyCellDataSource.getNsaStatus(slot, slot.telephony))
                    gen = 5;

                String name = slot.telephony.getNetworkOperatorName();
                String genLabel = gen == 0 ? "Unknown"
                        : (gen < 0 ? "No service" : gen + "G" + (gen == 5 ? (nrSa ? " SA" : " NSA") : ""));

                entry = (name != null && !name.trim().isEmpty()) ? name + " " + genLabel : "Unknown";
            }

            str.append(i == 0 ? entry : " | " + entry);
        }

        return str.toString().trim();
    }

    public String getNetwork(int simId) {
        SIMSlotState slot = subscriptionTracker.getSlot(simId);
        return slot == null ? "NetManager" : TelephonyCellDataSource.getSimCarrier(appContext, slot.telephony, slot);
    }

    /*
     * public SIMData fetchLive(TelephonyManager telephony) {
     * if (telephony == null)
     * return null;
     * 
     * SIMSlotState tempSlot = new SIMSlotState(-1);
     * tempSlot.telephony = telephony;
     * 
     * SIMData raw = sourceSelector.select()
     * .fetch(appContext, tempSlot);
     * if (raw == null)
     * return null;
     * 
     * SIMData processed = raw;
     * for (Postprocessor postprocessor : postprocessors)
     * processed = postprocessor.process(processed, tempSlot.simId);
     * return processed;
     * }
     */

    public SIMData getCachedSIMData(int simId) {
        return simStateCache.getSimData(simId);
    }

    public SIMStateCache getSimStateCache() {
        return simStateCache;
    }

    public SubscriptionTracker getSubscriptionTracker() {
        return subscriptionTracker;
    }

    public SIMSlotState getSlot(int simId) {
        return subscriptionTracker.getSlot(simId);
    }

    public CellSnapshot getLatestSnapshot(int simId) {
        SIMData cachedData = getCachedSIMData(simId);
        if (cachedData == null)
            return null;

        return buildCellSnapshot(cachedData);
    }

    public EventManager getEventManager() {
        return eventManager;
    }

    public int getSimCount() {
        return subscriptionTracker.getSimCount();
    }

    public void dispose() {
        stopPolling();
        subscriptionTracker.dispose();

        synchronized (NetManagerCore.class) {
            if (instance == this)
                instance = null;
        }
    }
}