package pw.dotto.netmanager.WearOS;

import android.content.Context;

/**
 * NetManager's WearIntegration interface defines the base methods which CAN be
 * implemented in the Play flavor of NetManager.
 *
 * @author DottoXD
 * @version 0.0.5
 */
public interface WearIntegration {
    void onCreate(Context context);

    void onResume();

    void onPause();

    void onDestroy();
}
