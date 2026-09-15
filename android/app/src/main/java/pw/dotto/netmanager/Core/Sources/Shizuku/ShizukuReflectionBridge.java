package pw.dotto.netmanager.Core.Sources.Shizuku;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;
import static pw.dotto.netmanager.MainActivity.PACKAGE_NAME;

import android.content.ComponentName;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.os.Parcel;
import android.os.Parcelable;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Permissions;
import rikka.shizuku.Shizuku;

/**
 * NetManager's ShizukuReflectionBridge is an essential component for the
 * Shizuku-powered reflection in NetManager.
 * This class allows normal NetManager core classes to easily request reflection
 * through Shizuku for their desired fields.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public final class ShizukuReflectionBridge {
    private static final long BIND_TIMEOUT_MS = 1500;

    private static volatile IReflectionUserService service;
    private static volatile boolean bindInFlight = false;
    private static final Object bindLock = new Object();

    private ShizukuReflectionBridge() {
    }

    public static int getHiddenIntField(Parcelable signalStrength, String className, String fieldName) {
        if (!Permissions.checkShizuku()) {
            return CELL_INFO_UNAVAILABLE;
        }

        IReflectionUserService current = service;
        if (current == null) {
            current = bindBlocking();
        }

        if (current == null) {
            return CELL_INFO_UNAVAILABLE;
        }

        byte[] bytes = marshal(signalStrength);
        if (bytes == null) {
            return CELL_INFO_UNAVAILABLE;
        }

        try {
            return current.getHiddenIntField(bytes, className, fieldName);
        } catch (Exception e) {
            service = null;
            DebugLogger.add("ShizukuReflectionBridge call failed: " + e.getMessage());

            return CELL_INFO_UNAVAILABLE;
        }
    }

    private static byte[] marshal(Parcelable parcelable) {
        Parcel parcel = Parcel.obtain();

        try {
            parcel.writeParcelable(parcelable, 0);
            return parcel.marshall();
        } catch (Exception e) {
            DebugLogger.add("ShizukuReflectionBridge marshal failed: " + e.getMessage());

            return null;
        } finally {
            parcel.recycle();
        }
    }

    private static IReflectionUserService bindBlocking() {
        synchronized (bindLock) {
            if (service != null) {
                return service;
            }

            if (bindInFlight) {
                return null;
            }

            bindInFlight = true;
        }

        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicReference<IBinder> resultBinder = new AtomicReference<>();

        Shizuku.UserServiceArgs args = new Shizuku.UserServiceArgs(
                new ComponentName(PACKAGE_NAME, ReflectionUserService.class.getName()))
                .daemon(false)
                .processNameSuffix("reflection")
                .debuggable(false)
                .version(1);

        ServiceConnection connection = new ServiceConnection() {
            @Override
            public void onServiceConnected(ComponentName name, IBinder binder) {
                resultBinder.set(binder);
                latch.countDown();
            }

            @Override
            public void onServiceDisconnected(ComponentName name) {
                service = null;
            }
        };

        try {
            Shizuku.bindUserService(args, connection);
            latch.await(BIND_TIMEOUT_MS, TimeUnit.MILLISECONDS);
        } catch (Exception e) {
            DebugLogger.add("ShizukuReflectionBridge bind failed: " + e.getMessage());
        } finally {
            bindInFlight = false;
        }

        IBinder binder = resultBinder.get();
        if (binder == null || !binder.pingBinder()) {
            DebugLogger.add("ShizukuReflectionBridge: error.");

            return null;
        }

        IReflectionUserService bound = IReflectionUserService.Stub.asInterface(binder);
        service = bound;
        return bound;
    }
}