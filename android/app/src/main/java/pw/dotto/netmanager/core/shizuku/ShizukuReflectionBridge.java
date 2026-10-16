package pw.dotto.netmanager.core.shizuku;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;
import static pw.dotto.netmanager.MainActivity.PACKAGE_NAME;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.IBinder;
import android.os.Parcel;
import android.os.Parcelable;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import pw.dotto.netmanager.utils.DebugLogger;
import pw.dotto.netmanager.utils.Permissions;
import rikka.shizuku.Shizuku;

/**
 * NetManager's ShizukuReflectionBridge is the bridge component which can be
 * called across the codebase to perform reflection with Shizuku.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public final class ShizukuReflectionBridge {
    private static final int USER_SERVICE_VERSION = 6;
    private static final long BIND_TIMEOUT_MS = 10000;
    private static final Object bindLock = new Object();

    private static volatile IReflectionUserService service;
    private static volatile boolean bindInFlight = false;

    public static int getHiddenIntField(Parcelable signalStrength, String className, String fieldName) {
        IReflectionUserService current = ensureServiceIsRunning();

        if (current == null)
            return CELL_INFO_UNAVAILABLE;

        byte[] bytes = marshal(signalStrength);
        if (bytes == null)
            return CELL_INFO_UNAVAILABLE;

        try {
            return current.getHiddenIntField(bytes, className, fieldName);
        } catch (Exception e) {
            invalidateService("getHiddenIntField", e);
            return CELL_INFO_UNAVAILABLE;
        }
    }

    public static String getAdvancedState(int subId) {
        IReflectionUserService current = ensureServiceIsRunning();
        if (current == null)
            return null;

        try {
            return current.getAdvancedState(subId);
        } catch (Exception e) {
            invalidateService("getAdvancedState", e);
            return null;
        }
    }

    private static void invalidateService(String component, Exception e) {
        service = null;
        DebugLogger.add("ShizukuReflectionBridge: " + component
                + " failed (" + e.getClass().getSimpleName()
                + "): " + e.getMessage() + ".");
    }

    private static IReflectionUserService ensureServiceIsRunning() {
        if (!Permissions.checkShizuku()) {
            return null;
        }

        IReflectionUserService current = service;
        if (current != null) {
            try {
                if (current.asBinder().pingBinder())
                    return current;
            } catch (Throwable ignored) {
            }

            service = null;
        }

        return bindBlocking();
    }

    private static byte[] marshal(Parcelable parcelable) {
        Parcel parcel = Parcel.obtain();

        try {
            parcel.writeParcelable(parcelable, 0);
            return parcel.marshall();
        } catch (Exception e) {
            DebugLogger.add("ShizukuReflectionBridge marshal failed: " + e.getMessage() + ".");
            return null;
        } finally {
            parcel.recycle();
        }
    }

    private static IReflectionUserService bindBlocking() {
        synchronized (bindLock) {
            if (service != null)
                return service;
            if (bindInFlight)
                return null;

            bindInFlight = true;
        }

        try {
            int perm = Shizuku.checkSelfPermission();

            DebugLogger.add("ShizukuReflectionBridge: version "
                    + Shizuku.getVersion()
                    + ", pingBinder " + Shizuku.pingBinder()
                    + ", permission " + (perm == PackageManager.PERMISSION_GRANTED
                            ? "granted"
                            : "denied (" + perm + ")")
                    + ".");
        } catch (Throwable t) {
            DebugLogger.add("ShizukuReflectionBridge: Shizuku probe threw "
                    + t.getClass().getSimpleName() + ": " + t.getMessage() + ".");
        }

        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicReference<IBinder> resultBinder = new AtomicReference<>();
        final AtomicReference<String> disconnectReason = new AtomicReference<>();

        Shizuku.UserServiceArgs args = new Shizuku.UserServiceArgs(
                new ComponentName(PACKAGE_NAME, ReflectionUserService.class.getName()))
                .daemon(false)
                .processNameSuffix("reflection")
                .debuggable(false)
                .version(USER_SERVICE_VERSION);

        ServiceConnection connection = new ServiceConnection() {
            @Override
            public void onServiceConnected(ComponentName name, IBinder binder) {
                DebugLogger.add("ShizukuReflectionBridge: onServiceConnected fired, binder is "
                        + (binder == null ? "null" : "alive") + ".");
                resultBinder.set(binder);
                latch.countDown();
            }

            @Override
            public void onServiceDisconnected(ComponentName name) {
                DebugLogger.add("ShizukuReflectionBridge: onServiceDisconnected.");
                disconnectReason.set("onServiceDisconnected");
                service = null;
            }

            @Override
            public void onBindingDied(ComponentName name) {
                DebugLogger.add("ShizukuReflectionBridge: onBindingDied (service process died).");
                disconnectReason.set("onBindingDied");
                service = null;
                latch.countDown();
            }

            @Override
            public void onNullBinding(ComponentName name) {
                DebugLogger.add("ShizukuReflectionBridge: onNullBinding (service returned null binder).");
                disconnectReason.set("onNullBinding");
                latch.countDown();
            }
        };

        long start = System.currentTimeMillis();
        try {
            DebugLogger.add("ShizukuReflectionBridge: calling bindUserService with version "
                    + USER_SERVICE_VERSION + "!");
            Shizuku.bindUserService(args, connection);
        } catch (Throwable e) {
            DebugLogger.add("ShizukuReflectionBridge: bindUserService threw "
                    + e.getClass().getSimpleName() + ": " + e.getMessage() + ".");
            synchronized (bindLock) {
                bindInFlight = false;
            }

            return null;
        }

        try {
            latch.await(BIND_TIMEOUT_MS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException ignored) {
        } finally {
            synchronized (bindLock) {
                bindInFlight = false;
            }
        }

        long elapsed = System.currentTimeMillis() - start;

        IBinder binder = resultBinder.get();
        if (binder == null) {
            DebugLogger.add("ShizukuReflectionBridge: no binder after " + elapsed
                    + "ms, " + disconnectReason.get() + ".");

            return null;
        }
        if (!binder.pingBinder()) {
            DebugLogger.add("ShizukuReflectionBridge: binder dead on arrival ("
                    + elapsed + "ms).");

            return null;
        }

        DebugLogger.add("ShizukuReflectionBridge: bound in " + elapsed + "ms.");
        IReflectionUserService bound = IReflectionUserService.Stub.asInterface(binder);
        service = bound;

        return bound;
    }
}