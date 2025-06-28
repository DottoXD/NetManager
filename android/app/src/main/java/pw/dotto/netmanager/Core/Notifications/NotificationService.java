package pw.dotto.netmanager.Core.Notifications;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ServiceInfo;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import pw.dotto.netmanager.Core.Manager;

public class NotificationService extends Service {
    private Manager manager;
    private MonitorNotification notification;

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
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (manager == null) {
            manager = new Manager(this);
            notification = new MonitorNotification(this);
            sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        }
        notification.setupNotifications();
        notification.send();

        startForeground(notification.getSelectedId(), notification.getActiveNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL);

        if (sharedPreferences == null || !sharedPreferences.getBoolean("flutter.backgroundService", false)) {
            stopSelf();
            return START_NOT_STICKY;
        }

        if (handler == null)
            handler = new Handler(Looper.getMainLooper());

        if (notificationRunnable == null)
            notificationRunnable = new Runnable() {
                @Override
                public void run() {
                    if (notification != null)
                        notification.send();

                    long millis = 3000;
                    try {
                        long seconds = sharedPreferences.getLong("flutter.backgroundUpdateInterval", 3);
                        millis = seconds * 1000;
                    } catch (ClassCastException e) {
                        Log.e("pw.dotto.netmanager", "Broken SharedPreferences.", e);
                    } catch (Exception e) {
                        Log.w("pw.dotto.netmanager", e.getMessage() == null ? "No info." : e.getMessage());
                    }
                    handler.postDelayed(this, millis);
                }
            };

        handler.post(notificationRunnable);

        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        manager.unregisterStateReceiver();

        if (handler != null)
            handler.removeCallbacks(notificationRunnable);
        if (notification != null)
            notification.cancel();
    }

    public Manager getManager() {
        return manager;
    }
}
