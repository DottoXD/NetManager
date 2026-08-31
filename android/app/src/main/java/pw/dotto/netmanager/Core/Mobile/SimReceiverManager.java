package pw.dotto.netmanager.Core.Mobile;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.telephony.TelephonyManager;

import io.sentry.Hint;
import io.sentry.Sentry;

/**
 * NetManager's SimReceiverManager is a class used to listen to SIM/subscription
 * changes.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class SimReceiverManager {
    private static SimReceiverManager instance;

    private Context context;
    private BroadcastReceiver simReceiver;
    private boolean isRegistered = false;

    private HandlerThread receiverThread;
    private Handler backgroundHandler;

    private SimReceiverManager(Context context) {
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

    /**
     * Registers an event receiver for Android subscription updates.
     *
     * @param onUpdate A method that shall be run as soon as there's an update to
     *                 the SIM's subscription.
     */
    public void registerStateReceiver(Runnable onUpdate) {
        if (isRegistered)
            return;

        receiverThread = new HandlerThread("SimReceiverThread");
        receiverThread.start();
        backgroundHandler = new Handler(receiverThread.getLooper());

        simReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (TelephonyManager.ACTION_SUBSCRIPTION_CARRIER_IDENTITY_CHANGED.equals(intent.getAction()) ||
                        TelephonyManager.ACTION_MULTI_SIM_CONFIG_CHANGED.equals(intent.getAction()))
                    onUpdate.run();
            }
        };

        IntentFilter filter = new IntentFilter();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            filter.addAction(TelephonyManager.ACTION_SUBSCRIPTION_CARRIER_IDENTITY_CHANGED);
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            filter.addAction(TelephonyManager.ACTION_MULTI_SIM_CONFIG_CHANGED);
        }

        try {
            if (context != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.registerReceiver(simReceiver, filter, null, backgroundHandler,
                            Context.RECEIVER_NOT_EXPORTED);
                } else {
                    context.registerReceiver(simReceiver, filter, null, backgroundHandler);
                }
                isRegistered = true;
            }
        } catch (IllegalArgumentException e) {
            Sentry.captureException(e, scope -> scope.setExtra("feature", "SimReceiverManager registerReceiver"));
        }
    }

    /**
     * Useful to release the current SimReceiverManager instance.
     */
    public static synchronized void releaseInstance() {
        if (instance != null) {
            instance.unregisterStateReceiver();
            instance = null;
        }
    }

    /**
     * Disposes this SimReceiverManager instance.
     */
    public void unregisterStateReceiver() {
        if (simReceiver == null || !isRegistered)
            return;

        try {
            if (context != null)
                context.unregisterReceiver(simReceiver);
        } catch (IllegalArgumentException e) {
            Sentry.captureException(e,
                    scope -> scope.setExtra("feature", "SimReceiverManager unregisterStateReceiver"));
        } finally {
            isRegistered = false;
            simReceiver = null;

            if (receiverThread != null) {
                receiverThread.quitSafely();
                receiverThread = null;
                backgroundHandler = null;
            }
        }
    }
}
