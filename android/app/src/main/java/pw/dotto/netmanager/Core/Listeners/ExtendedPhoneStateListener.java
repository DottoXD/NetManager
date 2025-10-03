package pw.dotto.netmanager.Core.Listeners;

import android.annotation.SuppressLint;
import android.telephony.PhoneStateListener;
import android.telephony.PhysicalChannelConfig;

import java.lang.reflect.Field;
import java.util.List;

import pw.dotto.netmanager.Utils.DebugLogger;

public class ExtendedPhoneStateListener extends PhoneStateListener {
    public ExtendedPhoneStateListener(int subscriptionId) {
        try {
            Field subscriptionIdField = PhoneStateListener.class.getDeclaredField("mSubId");
            subscriptionIdField.setAccessible(true);
            subscriptionIdField.set(this, subscriptionId);
        } catch (Exception e) {
            DebugLogger.add("ExtendedPhoneStateListener reflection error: " + e.getMessage());
        }
    }

    @Deprecated
    public void onPhysicalChannelConfigurationChanged(List<?> configs) {
        if (configs != null) {
            for (Object config : configs) {
                DebugLogger.add("Base PhysicalChannel update: " + config.toString());
            }
        }
    }
}
