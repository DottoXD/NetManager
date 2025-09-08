package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.telephony.CellIdentityTdscdma;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellSignalStrengthTdscdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;

public class TdscdmaExtractor {
    @NonNull
    public static TdscdmaCellData get(CellInfoTdscdma baseCell) {
        CellIdentityTdscdma identityTdscdma = (CellIdentityTdscdma) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthTdscdma signalTdscdma = (CellSignalStrengthTdscdma) baseCell.getCellSignalStrength();
        return new TdscdmaCellData(
                String.valueOf(identityTdscdma.getCid()),
                signalTdscdma.getDbm(),
                signalTdscdma.getRscp(),
                identityTdscdma.getUarfcn(),
                identityTdscdma.getCpid(),
                identityTdscdma.getLac(),
                -1, // signalTdscdma.getRsrq(),
                -1, // signalTdscdma.getSnr(),
                -1, // signalTdscdma.getTimingAdvance(),
                -1, // identityTdscdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }
}
