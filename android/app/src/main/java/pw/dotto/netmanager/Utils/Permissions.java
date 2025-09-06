package pw.dotto.netmanager.Utils;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

public class Permissions {
        public static boolean check(Context context) {
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

        public static void request(Activity activity) {
                ArrayList<String> permissions = new ArrayList<>();
                permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
                permissions.add(Manifest.permission.READ_PHONE_STATE);
                permissions.add(Manifest.permission.ACCESS_BACKGROUND_LOCATION);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                        permissions.add(Manifest.permission.POST_NOTIFICATIONS);

                ActivityCompat.requestPermissions(activity,
                                permissions.toArray(new String[0]),
                                1);
        }
}
