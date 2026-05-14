package pw.dotto.netmanager.WearOS;

import android.content.Context;

public interface WearIntegration {
    void onCreate(Context context);
    void onResume();
    void onPause();
}
