package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.TelephonyCallback;
import android.telephony.TelephonyDisplayInfo;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

/**
 * NetManager's DisplayInfoListener is a core component for cell status
 * collection which is useful to detect NR NSA connections on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to detect NR NSA with
 * high accuracy.
 *
 * @author DottoXD
 * @version 0.0.3
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class DisplayInfoListener extends TelephonyCallback implements TelephonyCallback.DisplayInfoListener {
    private boolean isNsa = false;

    @Override
    public void onDisplayInfoChanged(@NonNull TelephonyDisplayInfo telephonyDisplayInfo) {
        int overrideType = telephonyDisplayInfo.getOverrideNetworkType();

        isNsa = overrideType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA ||
                overrideType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_ADVANCED ||
                overrideType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA_MMWAVE;
    }

    public boolean getNsa() {
        return isNsa;
    }
}
