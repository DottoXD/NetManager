package pw.dotto.netmanager.Core.Sources.Shizuku;

import static pw.dotto.netmanager.Core.Sources.Telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.os.Parcel;
import android.os.Parcelable;

import java.lang.reflect.Field;

/**
 * NetManager's ReflectionUserService is an advanced NetManager component which
 * makes Shizuku, if available, perform reflection on behalf of NetManager to
 * possibly gather extra cell data on modern Android versions.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class ReflectionUserService extends IReflectionUserService.Stub {

    public ReflectionUserService() {
    }

    @Override
    public int getHiddenIntField(byte[] signalStrengthBytes, String className, String fieldName) {
        if (signalStrengthBytes == null) {
            return CELL_INFO_UNAVAILABLE;
        }

        Parcel parcel = Parcel.obtain();
        try {
            parcel.unmarshall(signalStrengthBytes, 0, signalStrengthBytes.length);
            parcel.setDataPosition(0);

            Parcelable signalStrength = parcel.readParcelable(getClass().getClassLoader());
            if (signalStrength == null) {
                return CELL_INFO_UNAVAILABLE;
            }

            Class<?> targetClass = Class.forName(className);
            if (!targetClass.isInstance(signalStrength)) {
                return CELL_INFO_UNAVAILABLE;
            }

            Field field = targetClass.getDeclaredField(fieldName);
            field.setAccessible(true);

            return (int) field.get(signalStrength);
        } catch (Exception ignored) {
            return CELL_INFO_UNAVAILABLE;
        } finally {
            parcel.recycle();
        }
    }

    @Override
    public void destroy() {
        System.exit(0);
    }
}