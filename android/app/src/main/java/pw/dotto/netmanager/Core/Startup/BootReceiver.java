package pw.dotto.netmanager.Core.Startup;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;

/**
 * NetManager's BootReceiver is a core component which is used to check if the
 * background service for cell monitoring should be started on boot.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class BootReceiver extends BroadcastReceiver {

    /**
     * Starts the cell monitoring background service if enabled by the user.
     *
     * @param context A valid Android context.
     * @param intent  The operation's intent.
     */
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == null)
            return;

        SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences",
                Context.MODE_PRIVATE);

        Intent delayedServiceIntent = new Intent(context, DelayedServiceStarter.class);

        if (sharedPreferences != null && sharedPreferences.getBoolean("flutter.startupMonitoring", false)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(delayedServiceIntent);
            } else {
                context.startService(delayedServiceIntent);
            }
        }
    }
}
