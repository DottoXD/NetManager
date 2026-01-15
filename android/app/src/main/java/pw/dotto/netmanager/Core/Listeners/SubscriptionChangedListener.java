package pw.dotto.netmanager.Core.Listeners;

import android.telephony.SubscriptionManager;

/**
 * NetManager's SubscriptionChangedListener is a core component for
 * subscriptions data collection on newer Android versions (12+).
 * This is used across NetManager's mobile cell Manager to detect active
 * subscriptions and changes across them.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class SubscriptionChangedListener extends SubscriptionManager.OnSubscriptionsChangedListener {
    private Runnable onChangedCallback;

    public SubscriptionChangedListener(Runnable onChangedCallback) {
        this.onChangedCallback = onChangedCallback;
    }

    @Override
    public void onSubscriptionsChanged() {
        if (onChangedCallback != null)
            onChangedCallback.run();
    }

    public void dispose() {
        onChangedCallback = null;
    }
}
