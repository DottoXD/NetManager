package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

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
 * @version 0.1.6
 */
public class GsmExtractor {
    private static final String REFLECTION_RSSI = "mSignalStrength";
    private static final String REFLECTION_TA = "mTimingAdvance";

    @NonNull
    public static GsmCellData get(CellInfoGsm baseCell) {
        CellIdentityGsm identityGsm = baseCell.getCellIdentity();
        
        CellSignalStrengthGsm signalGsm = baseCell.getCellSignalStrength();
        GsmCellData gsmCellData = new GsmCellData(
                String.valueOf(identityGsm.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalGsm.getRssi() : CELL_INFO_UNAVAILABLE),
                signalGsm.getDbm(),
                identityGsm.getArfcn(),
                identityGsm.getBsic(),
                identityGsm.getLac(),
                CELL_INFO_UNAVAILABLE, // signalGsm.getRsrq(),
                CELL_INFO_UNAVAILABLE, // signalGsm.getSnr(),
                CELL_INFO_UNAVAILABLE, // signalGsm.getCqi(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalGsm.getTimingAdvance() : CELL_INFO_UNAVAILABLE),
                CELL_INFO_UNAVAILABLE, // identityGsm.getBandwidth(),
                CELL_INFO_UNAVAILABLE,
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
            return CELL_INFO_UNAVAILABLE;
        }
    }
}
