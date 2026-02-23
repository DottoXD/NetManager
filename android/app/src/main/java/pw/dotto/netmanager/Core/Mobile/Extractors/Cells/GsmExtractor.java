package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityGsm;
import android.telephony.CellInfoGsm;
import android.telephony.CellSignalStrengthGsm;

import androidx.annotation.NonNull;

import java.lang.reflect.Field;

import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

/**
 * NetManager's GsmExtractor is a component which creates a GsmCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class GsmExtractor {
    private static final String REFLECTION_RSSI = "mSignalStrength";
    private static final String REFLECTION_TA = "mTimingAdvance";

    @NonNull
    public static GsmCellData get(CellInfoGsm baseCell) {
        CellIdentityGsm identityGsm = baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthGsm signalGsm = baseCell.getCellSignalStrength();
        GsmCellData gsmCellData = new GsmCellData(
                String.valueOf(identityGsm.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalGsm.getRssi() : -1),
                signalGsm.getDbm(),
                identityGsm.getArfcn(),
                identityGsm.getBsic(),
                identityGsm.getLac(),
                -1, // signalGsm.getRsrq(),
                -1, // signalGsm.getSnr(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalGsm.getTimingAdvance() : -1),
                -1, // identityGsm.getBandwidth(),
                band,
                baseCell.isRegistered());

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            gsmCellData.setRawSignal(getReflectedField(signalGsm, REFLECTION_RSSI));
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            gsmCellData.setTimingAdvance(getReflectedField(signalGsm, REFLECTION_TA));
        }

        return gsmCellData;
    }

    public static int getReflectedField(CellSignalStrengthGsm cellSignalStrengthGsm, String fieldName) {
        try {
            Field field = CellSignalStrengthGsm.class.getDeclaredField(fieldName);
            field.setAccessible(true);

            return (int) field.get(cellSignalStrengthGsm);
        } catch (Exception ignored) {
            return -1;
        }
    }
}
