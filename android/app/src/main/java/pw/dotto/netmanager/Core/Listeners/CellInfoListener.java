package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.CellInfo;
import android.telephony.TelephonyCallback;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.util.ArrayList;
import java.util.List;

/**
 * NetManager's CellInfoListener is a core component for cell data collection
 * which is useful to acquire cell info lists on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to gather additional
 * cells that might not be provided by Telephony#getAllCellInfo().
 *
 * @author DottoXD
 * @version 0.1.0
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class CellInfoListener extends TelephonyCallback implements TelephonyCallback.CellInfoListener {
    private List<CellInfo> latestCellInfo = new ArrayList<>();

    @Override
    public void onCellInfoChanged(@NonNull List<CellInfo> list) {
        this.latestCellInfo = list;
    }

    public List<CellInfo> getLatestCellInfo() {
        return latestCellInfo;
    }
}
