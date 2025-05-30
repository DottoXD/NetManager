package pw.dotto.netmanager.Core.MobileInfo;

import android.os.Build;
import android.telephony.TelephonyCallback;
import android.telephony.TelephonyDisplayInfo;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

@RequiresApi(api = Build.VERSION_CODES.S)
public class DisplayInfoListener extends TelephonyCallback implements TelephonyCallback.DisplayInfoListener {
    private boolean isNsa = false;

    @Override
    public void onDisplayInfoChanged(@NonNull TelephonyDisplayInfo telephonyDisplayInfo) {
        int overrideType = telephonyDisplayInfo.getOverrideNetworkType();

        isNsa = overrideType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_NSA ||
                overrideType == TelephonyDisplayInfo.OVERRIDE_NETWORK_TYPE_NR_ADVANCED;
    }

    public boolean getNsa() {
        return isNsa;
    }
}
