package pw.dotto.netmanager.Core.Listeners;

import android.os.Build;
import android.telephony.TelephonyCallback;
import androidx.annotation.RequiresApi;

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
