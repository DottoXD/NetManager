package pw.dotto.netmanager.Core.Base;

import android.os.Build;
import android.telephony.TelephonyManager;

import pw.dotto.netmanager.Core.Listeners.DataStateListener;
import pw.dotto.netmanager.Core.Listeners.DisplayInfoListener;
import pw.dotto.netmanager.Core.Listeners.LegacyPhoneStateListener;
import pw.dotto.netmanager.Core.Listeners.ServiceStateListener;
import pw.dotto.netmanager.Core.Listeners.SignalStrengthsListener;
import pw.dotto.netmanager.Core.Mobile.CellSnapshot;
import pw.dotto.netmanager.Core.Mobile.PhysicalChannelDumper;

/**
 * NetManager's SIMSlotCache is a core component which contains all objects of
 * the various cell info utilies (e.g DisplayInfoListener,
 * ServiceStateListener...) for a certain SIM slot.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class SIMSlotState {
    public int simId;
    public int subscriptionId = -1;
    public TelephonyManager telephony;

    public DisplayInfoListener nsaListener;
    public ServiceStateListener serviceStateListener;
    public DataStateListener dataStateListener;
    public SignalStrengthsListener signalStrengthsListener;

    public LegacyPhoneStateListener legacyPhoneStateListener;

    public PhysicalChannelDumper physicalChannelDumper;
    public CellSnapshot latestSnapshot;

    public SIMSlotState(int simId) {
        this.simId = simId;
    }

    public boolean hasTelephonyCallbacksRegistered() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return nsaListener != null && serviceStateListener != null && dataStateListener != null
                    && signalStrengthsListener != null;
        } else {
            return legacyPhoneStateListener != null;
        }
    }
}
