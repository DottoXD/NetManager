package pw.dotto.netmanager.Core.Notifications;

import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

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
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        manager = new Manager(this);
        notification = new MonitorNotification(this);
        sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        notification.setupNotifications();
        notification.send();

        startForeground(notification.getSelectedId(), notification.getActiveNotification());

        handler = new Handler(Looper.getMainLooper());

        if (sharedPreferences == null /* || !sharedPreferences.getBoolean("backgroundService", false) */) {
            onDestroy();
            return;
        }

        notificationRunnable = new Runnable() {
            @Override
            public void run() {
                if (notification != null)
                    notification.send();
                handler.postDelayed(this, sharedPreferences.getInt("backgroundUpdateInterval", 3));
            }
        };

        handler.post(notificationRunnable);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        if (handler != null)
            handler.removeCallbacks(notificationRunnable);
        if (notification != null)
            notification.cancel();
    }

    public Manager getManager() {
        return manager;
    }
}
