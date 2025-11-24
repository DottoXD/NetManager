package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityWcdma;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrengthWcdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;

public class WcdmaExtractor {
    @NonNull
    public static WcdmaCellData get(CellInfoWcdma baseCell) {
        CellIdentityWcdma identityWcdma = baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthWcdma signalWcdma = baseCell.getCellSignalStrength();
        return new WcdmaCellData(
                String.valueOf(identityWcdma.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalWcdma.getEcNo() : -1),
                signalWcdma.getDbm(),
                identityWcdma.getUarfcn(),
                identityWcdma.getPsc(),
                identityWcdma.getLac(),
                -1, // signalWcdma.getRsrq(),
                -1, // signalWcdma.getRssnr(),
                -1, // signalWcdma.getTimingAdvance(),
                -1, // identityWcdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }
}
