package pw.dotto.netmanager.Core.Notifications;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.service.notification.StatusBarNotification;

import androidx.core.app.NotificationManagerCompat;

public class Receiver extends BroadcastReceiver {
    private static final String baseIntent = "CLOSE_NOTIFICATION";

    @Override
    public void onReceive(Context context, Intent intent) {
        if(intent.getAction() != null && intent.getAction().equals(baseIntent)) {
            NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);
            try {
                int selectedId = intent.getIntExtra("id", -1);
                notificationManagerCompat.cancel(selectedId);
            } catch(Exception ignored) {
                for(StatusBarNotification notification : notificationManagerCompat.getActiveNotifications()) {
                    if(notification.getNotification().getChannelId().equals(MonitorNotification.NOTIFICATION_CHANNEL)) notificationManagerCompat.cancel(notification.getId());
                }
            }
        }
    }
}
