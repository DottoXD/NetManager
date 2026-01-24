package pw.dotto.netmanager.Core.Notifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/**
 * NetManager's Receiver is an essential component for notification management.
 * This component shuts down the notification service.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class Receiver extends BroadcastReceiver {
    private static final String baseIntent = "CLOSE_NOTIFICATION";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() != null && intent.getAction().equals(baseIntent)) {
            context.stopService(new Intent(context, Service.class));
        }
    }
}
