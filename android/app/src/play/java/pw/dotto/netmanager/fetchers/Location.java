package pw.dotto.netmanager.fetchers;

import static android.content.Context.MODE_PRIVATE;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;

import androidx.annotation.NonNull;

import com.google.android.gms.location.CurrentLocationRequest;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;
import com.google.android.gms.tasks.CancellationTokenSource;

import pw.dotto.netmanager.utils.DebugLogger;
import pw.dotto.netmanager.utils.Permissions;

/**
 * NetManager's Location class is a core component which is used in the map
 * component to display the user's position.
 *
 * @author DottoXD
 * @version 0.2.4
 */
public class Location {
    private static final long UPDATES_INTERVAL = 3000L;
    private static final long DESTROY_TIMEOUT = 45000L;
    private static final long MAX_CACHED_LOCATION_AGE = 5000L;
    private static final long CURRENT_LOCATION_TIMEOUT = 15000L;

    private static Location instance;

    private final FusedLocationProviderClient fusedLocationClient;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final CancellationTokenSource currentLocationCancellation = new CancellationTokenSource();

    private LocationCallback locationCallback;
    private android.location.Location lastLocation;
    private boolean disposed;

    @SuppressLint("MissingPermission")
    private Location(Context context) {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(context);

        SharedPreferences preferences = context.getSharedPreferences(
                "FlutterSharedPreferences",
                MODE_PRIVATE);

        int priority = Priority.PRIORITY_HIGH_ACCURACY;
        float minDistance = 2.0f;

        if (preferences != null) {
            long precision;

            try {
                precision = preferences.getLong(
                        "flutter.positionPrecision", 3);
            } catch (Exception ignored) {
                precision = 3;
            }

            switch ((int) precision) {
                case 0:
                    priority = Priority.PRIORITY_PASSIVE;
                    minDistance = 10.0f;
                    break;

                case 1:
                    priority = Priority.PRIORITY_BALANCED_POWER_ACCURACY;
                    minDistance = 5.0f;
                    break;

                case 2:
                    minDistance = 5.0f;
                    break;

                case 3:
                default:
                    break;
            }
        }

        LocationRequest request = new LocationRequest.Builder(
                priority,
                UPDATES_INTERVAL)
                .setMinUpdateIntervalMillis(UPDATES_INTERVAL / 2)
                .setMinUpdateDistanceMeters(minDistance)
                .setMaxUpdateAgeMillis(MAX_CACHED_LOCATION_AGE)
                .setWaitForAccurateLocation(false)
                .build();

        locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(@NonNull LocationResult result) {
                acceptLocation(result.getLastLocation());
            }
        };

        try {
            fusedLocationClient.getLastLocation()
                    .addOnSuccessListener(location -> {
                        if (isRecent(location, MAX_CACHED_LOCATION_AGE)) {
                            acceptLocation(location);
                        }
                    })
                    .addOnFailureListener(
                            error -> DebugLogger.add("Could not get cached location: " + error.getMessage() + "."));
        } catch (SecurityException error) {
            DebugLogger.add("Location permissions have not been granted!");
        }

        if (priority != Priority.PRIORITY_PASSIVE) {
            CurrentLocationRequest currentRequest = new CurrentLocationRequest.Builder()
                    .setPriority(priority)
                    .setMaxUpdateAgeMillis(MAX_CACHED_LOCATION_AGE)
                    .setDurationMillis(CURRENT_LOCATION_TIMEOUT)
                    .build();

            try {
                fusedLocationClient.getCurrentLocation(
                        currentRequest,
                        currentLocationCancellation.getToken())
                        .addOnSuccessListener(this::acceptLocation)
                        .addOnFailureListener(error -> DebugLogger
                                .add("Could not get current location: " + error.getMessage() + "."));
            } catch (SecurityException error) {
                DebugLogger.add("Location permissions have not been granted!");
            }
        }

        try {
            fusedLocationClient.requestLocationUpdates(
                    request,
                    locationCallback,
                    Looper.getMainLooper())
                    .addOnFailureListener(
                            error -> DebugLogger.add("Could not start location updates: " + error.getMessage() + "."));
        } catch (SecurityException error) {
            DebugLogger.add("Location permissions have not been granted!");
        }

        updateAccess();
    }

    public static synchronized Location getInstance(Context context) {
        if (context == null) {
            return null;
        }

        if (!Permissions.check(context, Permissions.ACCESS_FINE_LOCATION)) {
            if (instance != null) {
                instance.dispose();
            }

            return null;
        }

        if (instance == null) {
            instance = new Location(context.getApplicationContext());
        }

        return instance;
    }

    /**
     * Returns the latest registered Location.
     *
     * @return A location object.
     */
    public android.location.Location getLastLocation() {
        updateAccess();
        return lastLocation;
    }

    private boolean isRecent(
            android.location.Location location,
            long maxAgeMillis) {
        if (location == null) {
            return false;
        }

        long ageNanos = SystemClock.elapsedRealtimeNanos()
                - location.getElapsedRealtimeNanos();

        return ageNanos >= 0
                && ageNanos <= maxAgeMillis * 1_000_000L;
    }

    private void acceptLocation(android.location.Location location) {
        if (disposed || location == null) {
            return;
        }

        if (lastLocation == null
                || location.getElapsedRealtimeNanos() >= lastLocation.getElapsedRealtimeNanos()) {
            lastLocation = location;
        }
    }

    /**
     * Updates the latest access to location data.
     */
    public void updateAccess() {
        if (disposed) {
            return;
        }

        handler.removeCallbacks(selfDestruct);
        handler.postDelayed(selfDestruct, DESTROY_TIMEOUT);
    }

    /**
     * Disposes the Location object.
     */
    public void dispose() {
        if (disposed) {
            return;
        }

        disposed = true;

        handler.removeCallbacks(selfDestruct);
        currentLocationCancellation.cancel();

        if (locationCallback != null) {
            try {
                fusedLocationClient.removeLocationUpdates(locationCallback);
            } catch (SecurityException error) {
                DebugLogger.add("Could not remove GMS location updates!");
            }

            locationCallback = null;
        }

        if (instance == this) {
            instance = null;
        }
    }

    private final Runnable selfDestruct = this::dispose;
}
