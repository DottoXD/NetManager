package pw.dotto.netmanager.Speedtest;

import android.app.AlarmManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.service.notification.StatusBarNotification;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import java.util.Random;
import java.util.concurrent.atomic.AtomicBoolean;

import pw.dotto.netmanager.R;

/**
 * NetManager's Scheduler class is the component which manages the scheduling of
 * planned speed tests.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class Scheduler extends Service {
    private static final String NOTIFICATION_CHANNEL = "netmanager-scheduler";
    private int selectedId = -1;
    private int testsRunCount = 0;

    private final Handler loopHandler = new Handler(Looper.getMainLooper());
    private Runnable loopRunnable;
    private final AtomicBoolean isTestRunning = new AtomicBoolean(false);

    private String pingUrl;
    private String downloadUrl;
    private String uploadUrl;
    private long intervalMs;

    private Client activeClient;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null)
            return START_NOT_STICKY;

        String action = intent.getAction();
        if ("STOP_SCHEDULE".equals(action)) {
            stopScheduler();
            return START_NOT_STICKY;
        }

        pingUrl = intent.getStringExtra("pingUrl");
        downloadUrl = intent.getStringExtra("downloadUrl");
        uploadUrl = intent.getStringExtra("uploadUrl");
        intervalMs = intent.getIntExtra("intervalMs", 300000);

        if (pingUrl == null || downloadUrl == null || uploadUrl == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        if (selectedId < 0)
            selectedId = new Random().nextInt(9) + 1;

        String serverName = pingUrl.replace("https://", "").split("/")[0];

        Notification notification = createNotification("Scheduled speed tests are now running on " + serverName + ".");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(selectedId, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
        } else {
            startForeground(selectedId, notification);
        }

        if (intervalMs < 15 * 60 * 1000) {
            startContinuousLoop();
        } else {
            runSingleTestAndScheduleNext();
        }

        return START_STICKY;
    }

    private void startContinuousLoop() {
        if (loopRunnable != null)
            loopHandler.removeCallbacks(loopRunnable);

        loopRunnable = new Runnable() {
            @Override
            public void run() {
                executeTest(false);
                loopHandler.postDelayed(this, intervalMs);
            }
        };

        loopHandler.post(loopRunnable);
    }

    private void runSingleTestAndScheduleNext() {
        AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
        Intent intent = new Intent(this, Scheduler.class);
        intent.putExtra("pingUrl", pingUrl);
        intent.putExtra("downloadUrl", downloadUrl);
        intent.putExtra("uploadUrl", uploadUrl);
        intent.putExtra("intervalMs", intervalMs);

        PendingIntent pendingIntent = PendingIntent.getService(
                this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        long targetTime = System.currentTimeMillis() + intervalMs;
        if (alarmManager != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent);
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, targetTime, pendingIntent);
            }
        }

        executeTest(true);
    }

    private void executeTest(boolean stopService) {
        if (!isTestRunning.compareAndSet(false, true))
            return;

        testsRunCount++;
        updateNotification("Running speed test #" + testsRunCount + "...");

        new Thread(() -> {
            try {
                activeClient = new Client();
                activeClient.runSpeedTest(getApplicationContext(), pingUrl, downloadUrl, uploadUrl, null);
            } finally {
                activeClient = null;
                isTestRunning.set(false);

                if (stopService) {
                    stopForeground(true);
                    stopSelf();
                } else {
                    updateNotification("Completed " + testsRunCount + " tests. Waiting for scheduler...");
                }
            }
        }).start();
    }

    private void stopScheduler() {
        if (loopRunnable != null)
            loopHandler.removeCallbacks(loopRunnable);

        if (activeClient != null) {
            activeClient.stopTest();
            activeClient = null;
        }

        stopForeground(true);
        stopSelf();
    }

    private Notification createNotification(String contentText) {
        return new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager scheduled speed tests")
                .setContentText(contentText)
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setOngoing(true)
                .build();
    }

    private void updateNotification(String text) {
        NotificationManager notificationManager = getSystemService(NotificationManager.class);
        if (notificationManager != null && selectedId > 0) {
            Notification updatedNotification = createNotification(text);
            notificationManager.notify(selectedId, updatedNotification);
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "NetManager Scheduler",
                    NotificationManager.IMPORTANCE_LOW);

            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);

                for (StatusBarNotification notification : notificationManager.getActiveNotifications()) {
                    if (notification.getNotification().getChannelId().equals(NOTIFICATION_CHANNEL)) {
                        selectedId = notification.getId();
                        break;
                    }
                }
            }
        }
    }

    @Override
    public void onDestroy() {
        stopScheduler();
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}