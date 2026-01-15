package pw.dotto.netmanager.Core.Listeners;

import android.telephony.PhoneStateListener;

import java.lang.reflect.Field;
import java.util.List;

import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's ExtendedPhoneStateListener is a WIP component for cell info
 * collection which aims at helping to acquire more data on devices with
 * root-less PhysicalChannelConfig access.
 * This is used on NetManager's PhysicalChannelDumper on more modern Android
 * versions.
 * ExtendedPhoneStateListener must be considered as a preview feature due to its
 * low accuracy and effectiveness across all Android devices.
 *
 * @author DottoXD
 * @version 0.0.3
 */
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
