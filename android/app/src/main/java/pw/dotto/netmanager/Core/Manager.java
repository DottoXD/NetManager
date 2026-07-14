package pw.dotto.netmanager.Core;

import android.content.Context;
import android.telephony.TelephonyManager;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Mobile.CellSnapshot;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;

/**
 * NetManager's Manager is a facade class that bridges data from NetManagerCore
 * to all classes with their own lifecycle.
 * In past this used to be a god-class and is still kept as a bridge to avoid
 * rewriting substantial (and working) parts of the codebase.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class Manager {
    private final Context context;
    private final String consumerId;
    private final NetManagerCore core;

    public Manager(Context context) {
        this(context, NetManagerCore.UI_CONSUMER_ID, NetManagerCore.DEFAULT_INTERVAL_SECONDS);
    }

    public Manager(Context context, String consumerId, int intervalSeconds) {
        this.context = context.getApplicationContext();
        this.consumerId = consumerId;
        this.core = NetManagerCore.getInstance(this.context);
        this.core.attach(consumerId, intervalSeconds);
    }

    public String getSimOperator(int simId) {
        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? "NetManager" : TelephonyCellDataSource.getSimOperator(context, slot.telephony);
    }

    public String getSimCarrier(int simId) {
        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? "NetManager" : TelephonyCellDataSource.getSimCarrier(context, slot.telephony);
    }

    public String getPlmn(int simId) {
        SIMData cached = core.getCachedSIMData(simId);
        if (cached != null)
            return cached.getNetworkPlmn();

        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? "00000" : TelephonyCellDataSource.getPlmn(context, slot.telephony);
    }

    public int getSimNetworkGen(int simId) {
        SIMData cached = core.getCachedSIMData(simId);
        if (cached != null)
            return cached.getNetworkGen();

        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? -1 : TelephonyCellDataSource.getSimNetworkGen(context, slot.telephony);
    }

    public boolean getNsaStatus(int simId) {
        SIMSlotState slot = core.getSlot(simId);
        return slot != null && TelephonyCellDataSource.getNsaStatus(slot, slot.telephony);
    }

    public int getDataStatus(int simId) {
        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? -1 : TelephonyCellDataSource.getDataStatus(context, slot, slot.telephony);
    }

    public TelephonyManager getSubscription(int simId) {
        SIMSlotState slot = core.getSlot(simId);
        return slot == null ? null : slot.telephony;
    }

    public String getFullHeaderString() {
        return core.getFullHeaderString();
    }

    public SIMData getSimNetworkData(int simId) {
        return core.getCachedSIMData(simId);
    }

    public CellSnapshot getCellSnapshot(int simId) {
        return core.getLatestSnapshot(simId);
    }

    public int getSimCount() {
        return core.getSimCount();
    }

    public EventManager getEventManager() {
        return core.getEventManager();
    }

    public SimReceiverManager getSimReceiverManager() {
        return core.getSubscriptionTracker().getSimReceiverManager();
    }

    public void updateInterval(int intervalSeconds) {
        core.attach(consumerId, intervalSeconds);
    }

    public void dispose() {
        core.detach(consumerId);
    }
}