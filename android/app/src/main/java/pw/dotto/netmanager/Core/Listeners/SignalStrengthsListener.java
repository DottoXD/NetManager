package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.CellSignalStrength;
import android.telephony.SignalStrength;
import android.telephony.TelephonyCallback;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.List;

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
