package pw.dotto.netmanager.Core.Notifications;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.service.notification.StatusBarNotification;

import androidx.core.app.NotificationCompat;

import com.google.gson.Gson;

import java.util.Random;

import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

public class MonitorNotification {
    private final MainActivity context;
    private final Gson gson = new Gson();

    private NotificationManager notificationManager;
    private NotificationChannel notificationChannel;
    private NotificationCompat.Builder activeNotification;
    private int selectedId = -1;

    private PendingIntent closingPendingIntent;
    private PendingIntent openPendingIntent;

    public static final String NOTIFICATION_CHANNEL = "netmanager-chn";

    public MonitorNotification(MainActivity context) {
        this.context = context;
    }

    public void setupNotifications() {
        notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        notificationChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL);
        if (notificationChannel == null) {
            notificationChannel = new NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "NetManager",
                    NotificationManager.IMPORTANCE_LOW);

            notificationChannel.enableVibration(false);
            notificationManager.createNotificationChannel(notificationChannel);
        }

        for (StatusBarNotification notification : notificationManager.getActiveNotifications()) {
            if (notification.getNotification().getChannelId().equals(NOTIFICATION_CHANNEL)) {
                selectedId = notification.getId();
                break;
            }
        }

        if (selectedId < 0)
            selectedId = new Random().nextInt(10);

        Intent closingIntent = new Intent(context, Receiver.class);
        closingIntent.setAction("CLOSE_NOTIFICATION");
        closingIntent.putExtra("id", selectedId);
        closingPendingIntent = PendingIntent.getBroadcast(context, 0, closingIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK |
                Intent.FLAG_ACTIVITY_CLEAR_TASK);
        openPendingIntent = PendingIntent.getActivity(context, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);
    }

    public void send() {
        if (!context.checkPermissions() || (notificationManager == null || notificationChannel == null))
            return;
        buildNotification();
        notificationManager.notify(selectedId, activeNotification.build());
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public void buildNotification() {
        activeNotification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(R.drawable.launch_background) // got to make an icon as soon as i make an app logo
                .setContentTitle(context.getManager().getFullHeaderString())
                .setContentText("NetManager - " + gson.toJson(context.getManager().getSimNetworkData(0))) // got to
                                                                                                          // change this
                .setContentIntent(openPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true) // add check to compare with settings
                .setSilent(true)
                .addAction(R.drawable.launch_background, "Close", closingPendingIntent) // same here for the logo
                .setAllowSystemGeneratedContextualActions(false);
    }
}
