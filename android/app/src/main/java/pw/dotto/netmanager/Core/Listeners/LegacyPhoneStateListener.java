package pw.dotto.netmanager.Core.Listeners;

import android.Manifest;
import android.os.Build;
import android.telephony.CellInfo;
import android.telephony.CellSignalStrength;
import android.telephony.PhoneStateListener;
import android.telephony.ServiceState;
import android.telephony.SignalStrength;

import androidx.annotation.RequiresPermission;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's LegacyPhoneStateListener is a core component for cell data
 * collection which is useful to acquire extra information such as a SIM card's
 * connection status (just like DataStateListener), mobile cell bandwidth info
 * (just like ServiceStateListener), extra signal strength data
 * (SignalStrengthsListener) and additional cells (CellInfoListener) on older
 * Android versions that don't support
 * TelephonyCallback.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class LegacyPhoneStateListener extends PhoneStateListener {
    private int dataState = -1;
    private int[] updatedCellBandwidths = {};
    private List<CellSignalStrength> latestSignalStrengths = new ArrayList<>();
    private List<CellInfo> latestCellInfo = new ArrayList<>();
    private String updatedOperatorAlphaShort = "";
    private String updatedOperatorAlphaLong = "";
    private String operatorNumeric = "";
    private int state = ServiceState.STATE_IN_SERVICE;
    private boolean isEmergency = false;

    public LegacyPhoneStateListener(int subscriptionId) {
        try {
            Field subscriptionIdField = PhoneStateListener.class.getDeclaredField("mSubId");
            subscriptionIdField.setAccessible(true);
            subscriptionIdField.set(this, subscriptionId);
        } catch (Exception e) {
            DebugLogger.add("LegacyPhoneStateListener reflection error: " + e.getMessage());
        }
    }

    @Override
    public void onDataConnectionStateChanged(int state, int networkType) {
        this.dataState = state;
    }

    @RequiresPermission(allOf = { Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION })
    @Override
    public void onServiceStateChanged(ServiceState serviceState) {
        if (serviceState == null)
            return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            this.updatedCellBandwidths = serviceState.getCellBandwidths();
        } else {
            this.updatedCellBandwidths = new int[] {};
        }

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

    @Override
    public void onSignalStrengthsChanged(SignalStrength signalStrength) {
        if (signalStrength == null)
            return;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            this.latestSignalStrengths = signalStrength.getCellSignalStrengths();
        } else {
            this.latestSignalStrengths = new ArrayList<>();
        }
    }

    @Override
    public void onCellInfoChanged(List<CellInfo> cellInfo) {
        if (cellInfo != null) {
            this.latestCellInfo = cellInfo;
        }
    }

    public int getDataState() {
        return dataState;
    }

    public int[] getUpdatedCellBandwidths() {
        return updatedCellBandwidths;
    }

    public CellSignalStrength[] getLatestSignalStrengths() {
        return latestSignalStrengths.toArray(new CellSignalStrength[0]);
    }

    public List<CellInfo> getLatestCellInfo() {
        return latestCellInfo;
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
