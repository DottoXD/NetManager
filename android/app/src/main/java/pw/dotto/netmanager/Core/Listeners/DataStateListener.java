package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.TelephonyCallback;
import androidx.annotation.RequiresApi;

/**
 * NetManager's DataStateListener is a core component for cell data collection
 * which is useful to acquire SIM cards connection statuses on newer Android
 * versions (12+).
 * This is used across NetManager's mobile cell Manager to filter out cells for
 * idle SIM cards (which allows the app to give more accurate results when the
 * user is running a dual SIM configuration).
 *
 * @author DottoXD
 * @version 0.0.3
 */
@RequiresApi(api = Build.VERSION_CODES.S)
public class DataStateListener extends TelephonyCallback implements TelephonyCallback.DataConnectionStateListener {
    private int state = -1;

    @Override
    public void onDataConnectionStateChanged(int state, int networkType) {
        this.state = state;
    }

    public int getState() {
        return state;
    }
}
