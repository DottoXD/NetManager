package pw.dotto.netmanager.Core.Startup;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == null)
            return;

        SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences",
                Context.MODE_PRIVATE);

        Intent delayedServiceIntent = new Intent(context, DelayedServiceStarter.class);

        if (sharedPreferences != null && sharedPreferences.getBoolean("flutter.startupMonitoring", false))
            context.startForegroundService(delayedServiceIntent);
    }
}
