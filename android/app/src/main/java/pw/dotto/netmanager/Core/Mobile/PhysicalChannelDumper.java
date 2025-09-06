package pw.dotto.netmanager.Core.Mobile;

import android.telephony.TelephonyManager;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Utils.DebugLogger;

public class PhysicalChannelDumper {
    public static List<String> dump(TelephonyManager telephonyManager) {
        List<String> res = new ArrayList<>();

        try {
            Method method = TelephonyManager.class.getDeclaredMethod("getPhysicalChannelConfigList");
            List<?> list = (List<?>) method.invoke(telephonyManager);

            if (list != null) {
                for (Object obj : list) {
                    String item = obj.toString();
                    res.add(item);
                }
            }
        } catch (Exception e) {
            DebugLogger.add("PhysicalChannelDumper exception: " + e.getMessage());
        }

        return res;
    }
}
