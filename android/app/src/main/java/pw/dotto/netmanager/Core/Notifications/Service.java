package pw.dotto.netmanager.Core.Notifications;

import android.app.Notification;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's Service is an essential component for notification management.
 * This component shuts down the notification service.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class Service extends android.app.Service {
    private pw.dotto.netmanager.Core.Manager manager;
    private Manager notification;

    private Handler handler;
    private Runnable notificationRunnable;
    private SharedPreferences sharedPreferences;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        notification = new Manager(this);

        try {
            notification.setupChannel();
        } catch (Exception e) {
            DebugLogger.add("Unexpected error while creating the notifications channel: " + e.getMessage());
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (manager == null) {
            manager = new pw.dotto.netmanager.Core.Manager(this, "notification",
                    NetManagerCore.DEFAULT_INTERVAL_SECONDS);
            sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        }

        Notification bootstrap = notification.buildBootstrapNotification();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(notification.getSelectedId(), bootstrap,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL);
        } else {
            startForeground(notification.getSelectedId(), bootstrap);
        }

        if (!notification.send()) {
            DebugLogger.add("Unexpected error while sending the notification.");
            stopSelf();
            return START_NOT_STICKY;
        }

        if (sharedPreferences == null || !(sharedPreferences.getBoolean("flutter.backgroundService", false)
                || sharedPreferences.getBoolean("flutter.startupMonitoring", false))) {
            stopSelf();
            return START_NOT_STICKY;
        }

        if (handler == null)
            handler = new Handler(Looper.getMainLooper());

        long seconds = NetManagerCore.DEFAULT_INTERVAL_SECONDS;
        try {
            seconds = sharedPreferences.getLong("flutter.backgroundUpdateInterval",
                    NetManagerCore.DEFAULT_INTERVAL_SECONDS);
            manager.updateInterval((int) seconds);
        } catch (ClassCastException e) {
            Log.e("pw.dotto.netmanager", "Broken SharedPreferences.", e);
        } catch (Exception e) {
            Log.w("pw.dotto.netmanager", e.getMessage() == null ? "No info." : e.getMessage());
        }

        if (notificationRunnable == null) {
            long finalSeconds = seconds;
            notificationRunnable = new Runnable() {
                @Override
                public void run() {
                    if (notification != null)
                        notification.send();

                    long millis = finalSeconds * 1000;
                    handler.postDelayed(this, millis);
                }
            };
        }

        handler.post(notificationRunnable);

        return START_STICKY;
    }

    /**
     * Disposes the notification Service.
     */
    @Override
    public void onDestroy() {
        if (manager != null) {
            SimReceiverManager simReceiverManager = manager.getSimReceiverManager();
            if (simReceiverManager != null)
                simReceiverManager.unregisterStateReceiver();

            manager.dispose();
        }

        if (handler != null)
            handler.removeCallbacks(notificationRunnable);
        if (notification != null)
            notification.cancel();

        super.onDestroy();
    }

    public pw.dotto.netmanager.Core.Manager getManager() {
        return manager;
    }
}
