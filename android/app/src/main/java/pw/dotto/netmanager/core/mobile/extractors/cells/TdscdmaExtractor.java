package pw.dotto.netmanager.core.mobile.extractors.cells;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.os.Build;
import android.telephony.CellIdentityTdscdma;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellSignalStrengthTdscdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.core.mobile.celldatas.TdscdmaCellData;

/**
 * NetManager's TdscdmaExtractor is a component which creates a TdscdmaCellData
 * object based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class TdscdmaExtractor {
    @NonNull
    public static TdscdmaCellData get(CellInfoTdscdma baseCell) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return new TdscdmaCellData(
                    "CELL_INFO_UNAVAILABLE",
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    CELL_INFO_UNAVAILABLE,
                    baseCell.isRegistered());
        }

        CellIdentityTdscdma identityTdscdma = baseCell.getCellIdentity();

        CellSignalStrengthTdscdma signalTdscdma = baseCell.getCellSignalStrength();
        return new TdscdmaCellData(
                String.valueOf(identityTdscdma.getCid()),
                signalTdscdma.getDbm(),
                signalTdscdma.getRscp(),
                identityTdscdma.getUarfcn(),
                identityTdscdma.getCpid(),
                identityTdscdma.getLac(),
                CELL_INFO_UNAVAILABLE, // signalTdscdma.getRsrq(),
                CELL_INFO_UNAVAILABLE, // signalTdscdma.getSnr(),
                CELL_INFO_UNAVAILABLE, // signalTdscdma.getCqi(),
                CELL_INFO_UNAVAILABLE, // signalTdscdma.getTimingAdvance(),
                CELL_INFO_UNAVAILABLE, // identityTdscdma.getBandwidth(),
                CELL_INFO_UNAVAILABLE, // identityTdscdma.getBand(),
                baseCell.isRegistered());
    }
}
