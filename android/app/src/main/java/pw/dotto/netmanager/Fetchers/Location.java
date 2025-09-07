package pw.dotto.netmanager.Fetchers;

import static android.content.Context.MODE_PRIVATE;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import pw.dotto.netmanager.Utils.Permissions;

public class Location {
    private static final int UPDATES_INTERVAL = 5000;
    private static final int DESTROY_TIMEOUT = 5000;

    private static Location instance;
    private final LocationManager locationManager;
    private LocationListener locationListener;
    private android.location.Location lastLocation;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private long lastAccess;

    @SuppressLint("MissingPermission")
    public Location(Context context) {
        locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
        SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);

        if (locationManager != null && Permissions.check(context)) {
            int minDistance = 5;
            String provider;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                provider = LocationManager.FUSED_PROVIDER;
            } else {
                provider = LocationManager.GPS_PROVIDER;
            }

            if (sharedPreferences != null) {
                long positionPrecisionLevel;

                try {
                    positionPrecisionLevel = sharedPreferences.getLong("flutter.positionPrecision", 3);
                } catch (Exception ignored) {
                    positionPrecisionLevel = 3;
                }

                switch ((int) positionPrecisionLevel) {
                    case 0:
                        provider = LocationManager.PASSIVE_PROVIDER;
                        minDistance = 15;
                        break;
                    case 1:
                        provider = LocationManager.NETWORK_PROVIDER;
                        minDistance = 10;
                        break;
                    case 2:
                        provider = LocationManager.GPS_PROVIDER;
                        break;
                }
            }

            locationManager.requestLocationUpdates(
                    provider,
                    UPDATES_INTERVAL,
                    minDistance,
                    locationListener = location -> lastLocation = location);

            lastLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
            updateAccess();
        } else
            instance = null;
    }

    public static synchronized Location getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new Location(context.getApplicationContext());
        }

        return instance;
    }

    public android.location.Location getLastLocation() {
        updateAccess();
        return lastLocation;
    }

    public void updateAccess() {
        lastAccess = System.currentTimeMillis();
        handler.removeCallbacks(selfDestruct);
        handler.postDelayed(selfDestruct, DESTROY_TIMEOUT);
    }

    private final Runnable selfDestruct = this::destroy;

    public void destroy() {
        if (locationManager != null) {
            locationManager.removeUpdates(locationListener);
        }

        instance = null;
    }
}
