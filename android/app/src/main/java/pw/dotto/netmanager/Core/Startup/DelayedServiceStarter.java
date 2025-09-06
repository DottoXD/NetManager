package pw.dotto.netmanager.Core.Startup;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import pw.dotto.netmanager.Core.Notifications.NotificationService;
import pw.dotto.netmanager.Utils.Permissions;

public class DelayedServiceStarter extends Service {
    private static final String TEMP_NOTIFICATION_CHANNEL = "netmanager-tmp";
    private static final int TEMP_NOTIFICATION_ID = 1;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        NotificationChannel notificationChannel = notificationManager.getNotificationChannel(TEMP_NOTIFICATION_CHANNEL);
        if (notificationChannel == null) {
            notificationChannel = new NotificationChannel(
                    TEMP_NOTIFICATION_CHANNEL,
                    "NetManager Startup",
                    NotificationManager.IMPORTANCE_MIN);

            notificationChannel.enableVibration(false);
            notificationManager.createNotificationChannel(notificationChannel);
        }

        if (!Permissions.check(this)) {
            stopSelf();
            return START_NOT_STICKY;
        }

        Notification tempNotification = new NotificationCompat.Builder(this, TEMP_NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager is starting!")
                .setSmallIcon(android.R.drawable.stat_notify_sync) // got to make an icon as soon as i make an app logo
                .setContentText("Preparing NetManager's Cell Updates service..")
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setStyle(new NotificationCompat.BigTextStyle())
                .setOngoing(true)
                .setSilent(true)
                .setAllowSystemGeneratedContextualActions(false)
                .build();

        startForeground(TEMP_NOTIFICATION_ID, tempNotification);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Intent serviceIntent = new Intent(this, NotificationService.class);
            startForegroundService(serviceIntent);

            stopSelf();
        }, 5000);

        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }
}
