package pw.dotto.netmanager.Core.Mobile;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.telephony.TelephonyManager;

public class SimReceiverManager {
    private static SimReceiverManager instance;

    private Context context;
    private BroadcastReceiver simReceiver;
    private boolean isRegistered = false;

    public SimReceiverManager(Context context) {
        if (context != null)
            this.context = context.getApplicationContext();
    }

    public static synchronized SimReceiverManager getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new SimReceiverManager(context);
        }

        return instance;
    }

    public void registerStateReceiver(Runnable onUpdate) {
        if (isRegistered)
            return;
        simReceiver = new BroadcastReceiver() {

            @Override
            public void onReceive(Context context, Intent intent) {
                if (TelephonyManager.ACTION_SUBSCRIPTION_CARRIER_IDENTITY_CHANGED.equals(intent.getAction()) ||
                        TelephonyManager.ACTION_MULTI_SIM_CONFIG_CHANGED.equals(intent.getAction()))
                    onUpdate.run();
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(TelephonyManager.ACTION_SUBSCRIPTION_CARRIER_IDENTITY_CHANGED);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            filter.addAction(TelephonyManager.ACTION_MULTI_SIM_CONFIG_CHANGED);
        }

        try {
            if (context != null) {
                context.registerReceiver(simReceiver, filter);
                isRegistered = true;
            }
        } catch (IllegalArgumentException ignored) {
            // todo add sentry
        }

    }

    public void unregisterStateReceiver() {
        if (simReceiver == null || !isRegistered)
            return;

        try {
            if (context != null)
                context.unregisterReceiver(simReceiver);
        } catch (IllegalArgumentException ignored) {
            // todo add sentry
        } finally {
            isRegistered = false;
            simReceiver = null;
        }

    }
}
