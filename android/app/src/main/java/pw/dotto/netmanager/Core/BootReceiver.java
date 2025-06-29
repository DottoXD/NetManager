package pw.dotto.netmanager.Core;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import pw.dotto.netmanager.Core.Notifications.DelayedServiceStarter;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == null)
            return;

        if (intent.getAction().equals(Intent.ACTION_BOOT_COMPLETED)) {
            Intent notificationIntent = new Intent(context, DelayedServiceStarter.class);
            SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences",
                    Context.MODE_PRIVATE);

            if (sharedPreferences != null && sharedPreferences.getBoolean("flutter.startupMonitoring", false)
                    && sharedPreferences.getBoolean("flutter.backgroundService", false))
                context.startForegroundService(notificationIntent);
        }
    }
}
