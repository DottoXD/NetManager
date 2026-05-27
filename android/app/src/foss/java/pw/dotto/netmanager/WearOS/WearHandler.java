package pw.dotto.netmanager.WearOS;

import android.content.Context;

/**
 * NetManager's WearHandler FOSS class is just an empty class, due to WearOS
 * support not being available without Google Play Services at this time.
 *
 * @author DottoXD
 * @version 0.0.5
 */
public class WearHandler implements WearIntegration {
    @Override
    public void onCreate(Context context) {
    }

    @Override
    public void onResume() {
    }

    @Override
    public void onPause() {
    }

    @Override
    public void onDestroy() {
    }
}
