package pw.dotto.netmanager.Core.Notifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class Receiver extends BroadcastReceiver {
    private static final String baseIntent = "CLOSE_NOTIFICATION";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() != null && intent.getAction().equals(baseIntent)) {
            context.stopService(new Intent(context, Service.class));
        }
    }
}
