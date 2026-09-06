package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.os.Build;
import android.telephony.CellIdentityWcdma;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrengthWcdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;

/**
 * NetManager's WcdmaExtractor is a component which creates a WcdmaCellData
 * object based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class WcdmaExtractor {
    @NonNull
    public static WcdmaCellData get(CellInfoWcdma baseCell) {
        CellIdentityWcdma identityWcdma = baseCell.getCellIdentity();

        CellSignalStrengthWcdma signalWcdma = baseCell.getCellSignalStrength();
        return new WcdmaCellData(
                String.valueOf(identityWcdma.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalWcdma.getEcNo() : CELL_INFO_UNAVAILABLE),
                signalWcdma.getDbm(),
                identityWcdma.getUarfcn(),
                identityWcdma.getPsc(),
                identityWcdma.getLac(),
                CELL_INFO_UNAVAILABLE, // signalWcdma.getRsrq(),
                CELL_INFO_UNAVAILABLE, // signalWcdma.getRssnr(),
                CELL_INFO_UNAVAILABLE, // signalWcdma.getCqi(),
                CELL_INFO_UNAVAILABLE, // signalWcdma.getTimingAdvance(),
                CELL_INFO_UNAVAILABLE, // identityWcdma.getBandwidth(),
                CELL_INFO_UNAVAILABLE, // identityWcdma.getBand(),
                baseCell.isRegistered());
    }
}
