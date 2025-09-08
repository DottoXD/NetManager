package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.telephony.CellIdentityWcdma;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrengthWcdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;

public class WcdmaExtractor {
    @NonNull
    public static WcdmaCellData get(CellInfoWcdma baseCell) {
        CellIdentityWcdma identityWcdma = (CellIdentityWcdma) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthWcdma signalWcdma = (CellSignalStrengthWcdma) baseCell.getCellSignalStrength();
        return new WcdmaCellData(
                String.valueOf(identityWcdma.getCid()),
                -1, // signalWcdma.getDbm(),
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
