package pw.dotto.netmanager.Core.Startup;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import pw.dotto.netmanager.Core.Notifications.Service;
import pw.dotto.netmanager.R;
import pw.dotto.netmanager.Utils.Permissions;

/**
 * NetManager's DelayedServiceStarter is a simple workaround to allow the cell
 * monitoring service to start on boot on newer Android versions.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class DelayedServiceStarter extends android.app.Service {
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

    /**
     * Starts the cell monitoring background service if enabled by the user with a
     * delayed timer.
     *
     * @param intent  The operation's intent.
     * @param flags   The startup flags.
     * @param startId The startId.
     * @return An integer (should always be START_NOT_STICKY).
     */
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            NotificationChannel notificationChannel = notificationManager
                    .getNotificationChannel(TEMP_NOTIFICATION_CHANNEL);
            if (notificationChannel == null) {
                notificationChannel = new NotificationChannel(
                        TEMP_NOTIFICATION_CHANNEL,
                        "NetManager Startup",
                        NotificationManager.IMPORTANCE_MIN);

                notificationChannel.enableVibration(false);
                notificationManager.createNotificationChannel(notificationChannel);
            }
        }

        Notification tempNotification = new NotificationCompat.Builder(this, TEMP_NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager is starting!")
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setContentText("Preparing NetManager's Cell Updates service..")
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setStyle(new NotificationCompat.BigTextStyle())
                .setOngoing(true)
                .setSilent(true)
                .setAllowSystemGeneratedContextualActions(false)
                .build();

        startForeground(TEMP_NOTIFICATION_ID, tempNotification);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            Intent serviceIntent = new Intent(this, Service.class);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }

            stopSelf();
        }, 5000);

        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }
}
