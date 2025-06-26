package pw.dotto.netmanager.Core;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;

public class Utils {
        public static boolean checkPermissions(Context context) {
                boolean basePerms = ActivityCompat.checkSelfPermission(
                                context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                                && ActivityCompat.checkSelfPermission(
                                                context,
                                                Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
                                && ActivityCompat.checkSelfPermission(
                                                context,
                                                Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED;

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        return basePerms && ActivityCompat.checkSelfPermission(
                                        context,
                                        Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
                } else
                        return basePerms;
        }
}
