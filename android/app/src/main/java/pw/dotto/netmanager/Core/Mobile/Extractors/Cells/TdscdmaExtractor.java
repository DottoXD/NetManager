package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityTdscdma;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellSignalStrengthTdscdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;

public class TdscdmaExtractor {
    @NonNull
    public static TdscdmaCellData get(CellInfoTdscdma baseCell) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return new TdscdmaCellData(
                    "-1",
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    baseCell.isRegistered());
        }

        CellIdentityTdscdma identityTdscdma = baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthTdscdma signalTdscdma = baseCell.getCellSignalStrength();
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
