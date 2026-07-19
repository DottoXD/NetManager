package pw.dotto.netmanager.Core.Listeners;

import android.Manifest;
import android.os.Build;
import android.telephony.ServiceState;
import android.telephony.TelephonyCallback;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.RequiresPermission;

import pw.dotto.netmanager.Utils.Permissions;

/**
 * NetManager's ServiceStateListener is a core component for cell data
 * collection which is useful to detect NR cell bandwidths on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to detect NR NSA/SA cell
 * bandwidths with moderate accuracy and operator names.
 * This might be used in future to detect 4G/LTE cell bandwidths on devices that
 * (sadly) return no bandwidth data.
 *
 * @author DottoXD
 * @version 0.1.0
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class ServiceStateListener extends TelephonyCallback implements TelephonyCallback.ServiceStateListener {
    private int[] updatedCellBandwidths = {};
    private String updatedOperatorAlphaShort = "";
    private String updatedOperatorAlphaLong = "";
    private String operatorNumeric = "";
    private int state = ServiceState.STATE_IN_SERVICE;
    private boolean isEmergency = false;

    @RequiresPermission(allOf = { Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION })
    @Override
    public void onServiceStateChanged(@NonNull ServiceState serviceState) {
        updatedCellBandwidths = serviceState.getCellBandwidths();

        try {
            updatedOperatorAlphaShort = serviceState.getOperatorAlphaShort();
            updatedOperatorAlphaLong = serviceState.getOperatorAlphaLong();
            operatorNumeric = serviceState.getOperatorNumeric();
            state = serviceState.getState();

            String s = serviceState.toString();
            isEmergency = s.contains("mIsEmergencyOnly=true") || s.contains("EmergOnly=true");
        } catch (Exception ignored) {
        }
    }

    public int[] getUpdatedCellBandwidths() {
        return updatedCellBandwidths;
    }

    public String getUpdatedOperatorAlphaShort() {
        return updatedOperatorAlphaShort;
    }

    public String getUpdatedOperatorAlphaLong() {
        return updatedOperatorAlphaLong;
    }

    public String getOperatorNumeric() {
        return operatorNumeric;
    }

    public int getState() {
        return state;
    }

    public boolean getIsEmergency() {
        return isEmergency;
    }
}
