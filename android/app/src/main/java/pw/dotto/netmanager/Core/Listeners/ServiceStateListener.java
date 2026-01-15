package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.ServiceState;
import android.telephony.TelephonyCallback;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

/**
 * NetManager's ServiceStateListener is a core component for cell data
 * collection which is useful to detect NR cell bandwidths on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to detect NR NSA/SA cell
 * bandwidths with moderate accuracy.
 * This might be used in future to detect 4G/LTE cell bandwidths on devices that
 * (sadly) return no bandwidth data.
 *
 * @author DottoXD
 * @version 0.0.3
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class ServiceStateListener extends TelephonyCallback implements TelephonyCallback.ServiceStateListener {
    private int[] updatedCellBandwidths = {};

    @Override
    public void onServiceStateChanged(@NonNull ServiceState serviceState) {
        updatedCellBandwidths = serviceState.getCellBandwidths();
    }

    public int[] getUpdatedCellBandwidths() {
        return updatedCellBandwidths;
    }
}
