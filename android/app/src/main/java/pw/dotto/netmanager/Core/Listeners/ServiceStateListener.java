package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.ServiceState;
import android.telephony.TelephonyCallback;
import android.telephony.TelephonyDisplayInfo;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.Arrays;

import pw.dotto.netmanager.Utils.DebugLogger;

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
