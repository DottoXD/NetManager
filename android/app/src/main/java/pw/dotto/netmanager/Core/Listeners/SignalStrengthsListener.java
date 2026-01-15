package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.CellSignalStrength;
import android.telephony.SignalStrength;
import android.telephony.TelephonyCallback;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.List;

/**
 * NetManager's SignalStrengthsListener is a core component for cell data
 * collection which is essential to detect NR signal data on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to get NR NSA/SA SINR,
 * RSRQ and RSRP with high accuracy on devices that return none of that data.
 *
 * @author DottoXD
 * @version 0.0.3
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class SignalStrengthsListener extends TelephonyCallback implements TelephonyCallback.SignalStrengthsListener {
    private List<CellSignalStrength> latestSignalStrengths = new ArrayList<>();

    @Override
    public void onSignalStrengthsChanged(@NonNull SignalStrength signalStrength) {
        latestSignalStrengths = signalStrength.getCellSignalStrengths();
    }

    public CellSignalStrength[] getLatestSignalStrengths() {
        return latestSignalStrengths.toArray(new CellSignalStrength[0]);
    }
}
