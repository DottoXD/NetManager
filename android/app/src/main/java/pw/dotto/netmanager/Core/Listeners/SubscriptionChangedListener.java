package pw.dotto.netmanager.Core.Listeners;

import android.telephony.SubscriptionManager;

public class SubscriptionChangedListener extends SubscriptionManager.OnSubscriptionsChangedListener {
    private Runnable onChangedCallback;

    public SubscriptionChangedListener(Runnable onChangedCallback) {
        this.onChangedCallback = onChangedCallback;
    }

    @Override
    public void onSubscriptionsChanged() {
        if(onChangedCallback != null) onChangedCallback.run();
    }

    public void dispose() {
        onChangedCallback = null;
    }
}
