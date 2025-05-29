package pw.dotto.netmanager.Core;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import pw.dotto.netmanager.Core.Notifications.NotificationService;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == null)
            return;

        if (intent.getAction().equals(Intent.ACTION_BOOT_COMPLETED)) {
            Intent notificationIntent = new Intent(context, NotificationService.class);

            context.startForegroundService(notificationIntent);
        }
    }
}
