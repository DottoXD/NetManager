package pw.dotto.netmanager.Core;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;

import androidx.core.app.NotificationCompat;

import java.util.Random;

import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

public class Notification {
    private final MainActivity context;

    private NotificationManager notificationManager;
    private NotificationChannel notificationChannel;
    private Intent intent;
    private NotificationCompat.Builder activeNotification;
    private int selectedId = 0;

    private final String NOTIFICATION_CHANNEL = "netmanager-chn";

    public Notification(MainActivity context) {
        this.context = context;
    }

    public void setupNotifications() {
        notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        notificationChannel = new NotificationChannel(
                NOTIFICATION_CHANNEL,
                "NetManager",
                NotificationManager.IMPORTANCE_LOW
        );
        notificationChannel.enableVibration(false);
        notificationManager.createNotificationChannel(notificationChannel);

        intent = new Intent(); //add close btn in future

        selectedId = new Random().nextInt(10);
    }

    public void send() {
        if (!context.checkPermissions() || (notificationManager == null || notificationChannel == null)) return;
        buildNotification();
        notificationManager.notify(selectedId, activeNotification.build());
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public void buildNotification() {
        activeNotification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(R.drawable.launch_background) //got to make an icon as soon as i make an app logo
                .setContentTitle(context.getManager().getCarrier() + " " + context.getManager().getNetworkGen() + "G")
                .setContentText("NetManager")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setOngoing(true) //add check to compare with settings
                .setSilent(true)
                .setAllowSystemGeneratedContextualActions(false);
    }
}
