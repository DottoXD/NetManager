package pw.dotto.netmanager.Core.Mobile;

import android.os.Build;
import android.telephony.PhoneStateListener;
import android.telephony.PhysicalChannelConfig;
import android.telephony.TelephonyManager;
import android.util.Log;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Utils.DebugLogger;

public class PhysicalChannelDumper {
    private static final int LISTEN_PHYSICAL_CHANNEL_CONFIGURATION = 0x00100000;

    public static List<String> dump(TelephonyManager telephonyManager) { // output to be cached
        List<String> res = new ArrayList<>();

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
            try {
                Method method = TelephonyManager.class.getDeclaredMethod("getPhysicalChannelConfigList");
                List<?> configs = (List<?>) method.invoke(telephonyManager);

                if (configs != null) {
                    for (Object obj : configs) {
                        DebugLogger.add("Old PhysicalChannelDumper config: " + obj.toString());
                        res.add(obj.toString());
                    }
                }
            } catch (Exception e) {
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);
                pw.flush();

                DebugLogger.add("Reflection PhysicalChannelDumper exception: " + e.getMessage() + ", " + e.getCause()
                        + ".\n" + sw);
            }
        } else {
            try {
                telephonyManager.listen(new PhoneStateListener() {
                    public void onPhysicalChannelConfigurationChanged(List<?> configs) {
                        if (configs != null) {
                            for (Object obj : configs) {
                                DebugLogger.add("Modern PhysicalChannelDumper config: " + obj.toString());
                                res.add(obj.toString());
                            }
                        }

                        telephonyManager.listen(this, PhoneStateListener.LISTEN_NONE);
                    }
                }, LISTEN_PHYSICAL_CHANNEL_CONFIGURATION);
            } catch (Exception e) {
                StringWriter sw = new StringWriter();
                PrintWriter pw = new PrintWriter(sw);
                e.printStackTrace(pw);
                pw.flush();

                DebugLogger.add(
                        "Modern PhysicalChannelDumper exception: " + e.getMessage() + ", " + e.getCause() + ".\n" + sw);
            }
        }

        return res;
    }
}
