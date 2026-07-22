package pw.dotto.netmanager.Utils;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.PowerManager;
import android.provider.Settings;

/**
 * NetManager's PowerUtils class is an helper utility which allows the app to
 * request the user to ignore battery optimisations for NetManager.
 * This is useful to make NetManager behave normally on devices with aggressive,
 * non AOSP battery optimisations.
 *
 * @author DottoXD
 * @version 0.1.1
 */
public class PowerUtils {
    public static boolean isIgnoringBatteryOptimisations(Context context) {
        PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        return pm != null && pm.isIgnoringBatteryOptimizations(context.getPackageName());
    }

    @SuppressLint("BatteryLife")
    public static boolean requestIgnoreBatteryOptimisations(Context context) {
        try {
            Intent intent = new Intent();

            if (!isIgnoringBatteryOptimisations(context)) {
                intent.setAction(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.parse("package:" + context.getPackageName()));
            } else {
                intent.setAction(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
            }

            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);

            return true;
        } catch (Exception e) {
            DebugLogger.add("PowerUtils battery settings failed: " + e.getMessage());
            return openStandardBatterySettings(context);
        }
    }

    private static boolean openStandardBatterySettings(Context context) {
        try {
            Intent intent = new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);

            return true;
        } catch (Exception ignored) {
            return false;
        }
    }
}
