package pw.dotto.netmanager.Utils;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

/**
 * NetManager's Permissions class is a component used to check and request
 * permissions.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class Permissions {
        private static final int REQ_FOREGROUND = 1;
        private static final int REQ_BACKGROUND = 2;

        public static final int READ_PHONE_STATE = 1 << 0;
        public static final int ACCESS_FINE_LOCATION = 1 << 1;
        public static final int ACCESS_BACKGROUND_LOCATION = 1 << 2;
        public static final int POST_NOTIFICATIONS = 1 << 3;

        /**
         * Checks if the default permissions (READ_PHONE_STATE, ACCESS_FINE_LOCATION &
         * ACCESS_BACKGROUND_LOCATION) are granted or not.
         *
         * @param context A valid Context object.
         * @return Whether or not the permissions are granted.
         */
        public static boolean check(Context context) {
                return check(context, READ_PHONE_STATE | ACCESS_FINE_LOCATION
                                | (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ? ACCESS_BACKGROUND_LOCATION : 0));
        }

        public static boolean check(Context context, int req) {
                if ((req & READ_PHONE_STATE) != 0 && ActivityCompat.checkSelfPermission(
                                context,
                                Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                        return false;
                }

                if ((req & ACCESS_FINE_LOCATION) != 0 && ActivityCompat.checkSelfPermission(
                                context,
                                Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        return false;
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && (req & ACCESS_BACKGROUND_LOCATION) != 0
                                && ActivityCompat.checkSelfPermission(
                                                context,
                                                Manifest.permission.ACCESS_BACKGROUND_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                        return false;
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && (req & POST_NOTIFICATIONS) != 0
                                && ActivityCompat.checkSelfPermission(
                                                context,
                                                Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                        return false;
                }

                return true;
        }

        /**
         * Requests the default permissions (READ_PHONE_STATE, ACCESS_FINE_LOCATION &
         * ACCESS_BACKGROUND_LOCATION).
         *
         * @param activity A valid & active Activity object.
         */
        public static void request(Activity activity) {
                request(activity, READ_PHONE_STATE | ACCESS_FINE_LOCATION
                                | (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ? ACCESS_BACKGROUND_LOCATION : 0));
        }

        /**
         * Requests the required permissions.
         *
         * @param activity A valid & active Activity object.
         * @param req      The BitField value representing the requested permissions.
         */
        public static void request(Activity activity, int req) {
                ArrayList<String> permissions = new ArrayList<>();

                if ((req & ACCESS_FINE_LOCATION) != 0)
                        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);

                if ((req & READ_PHONE_STATE) != 0)
                        permissions.add(Manifest.permission.READ_PHONE_STATE);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && (req & POST_NOTIFICATIONS) != 0)
                        permissions.add(Manifest.permission.POST_NOTIFICATIONS);

                if (!permissions.isEmpty())
                        ActivityCompat.requestPermissions(activity,
                                        permissions.toArray(new String[0]),
                                        1);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && (req & ACCESS_BACKGROUND_LOCATION) != 0) {
                        ActivityCompat.requestPermissions(activity,
                                        new String[] { Manifest.permission.ACCESS_BACKGROUND_LOCATION },
                                        REQ_BACKGROUND);
                }
        }

        /**
         * Handles permissions requests' results and eventually asks for the
         * ACCESS_BACKGROUND_LOCATION permission.
         *
         * @param activity     A valid & active Activity object.
         * @param requestCode  The request's code.
         * @param permissions  The requested permissions.
         * @param grantResults Wether or not the permissions were granted.
         */
        public static void handleResult(Activity activity, int requestCode, @NonNull String[] permissions,
                        @NonNull int[] grantResults) {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
                        return;

                if (requestCode == REQ_FOREGROUND) {
                        if (ActivityCompat.checkSelfPermission(activity,
                                        Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                                ActivityCompat.requestPermissions(activity,
                                                new String[] { Manifest.permission.ACCESS_BACKGROUND_LOCATION },
                                                REQ_BACKGROUND);
                        }
                }
        }
}
