package pw.dotto.netmanager.Core.Notifications;

import android.app.Notification;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ServiceInfo;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;

import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;

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
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (manager == null) {
            manager = new pw.dotto.netmanager.Core.Manager(this);
            notification = new Manager(this);
            sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        }

        notification.setupChannel();
        notification.send();

        int attempts = 0;
        Notification activeNotification = null;

        while (activeNotification == null && attempts < 3) {
            activeNotification = notification.getActiveNotification();
            if (activeNotification != null) {
                startForeground(notification.getSelectedId(), notification.getActiveNotification(),
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL);
            }

            attempts++;
        }

        if (activeNotification == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

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

        SimReceiverManager simReceiverManager = manager.getSimReceiverManager();
        if (simReceiverManager != null)
            simReceiverManager.unregisterStateReceiver();

        if (handler != null)
            handler.removeCallbacks(notificationRunnable);
        if (notification != null)
            notification.cancel();
    }

    public pw.dotto.netmanager.Core.Manager getManager() {
        return manager;
    }
}
