package pw.dotto.netmanager.Utils;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

public class Permissions {
        private static final int REQ_FOREGROUND = 1;
        private static final int REQ_BACKGROUND = 2;

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

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                        permissions.add(Manifest.permission.POST_NOTIFICATIONS);

                ActivityCompat.requestPermissions(activity,
                                permissions.toArray(new String[0]),
                                1);
        }

        public static void handleResult(Activity activity, int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
                if(requestCode == REQ_FOREGROUND) {
                        if(ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.ACCESS_BACKGROUND_LOCATION}, REQ_BACKGROUND);
                        }
                }
        }
}
