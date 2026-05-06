package pw.dotto.netmanager.Recording;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * NetManager's Receiver is a component that shuts down recording service's notifications management.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class Receiver extends BroadcastReceiver {
    private static final String baseIntent = "CLOSE_RECORDING_NOTIFICATION";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() != null && intent.getAction().equals(baseIntent)) {
            context.stopService(new Intent(context, Service.class));
        }
    }
}
