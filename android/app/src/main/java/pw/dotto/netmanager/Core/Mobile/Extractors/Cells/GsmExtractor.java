package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityGsm;
import android.telephony.CellInfoGsm;
import android.telephony.CellSignalStrengthGsm;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

public class GsmExtractor {
    @NonNull
    public static GsmCellData get(CellInfoGsm baseCell) {
        CellIdentityGsm identityGsm = baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthGsm signalGsm = baseCell.getCellSignalStrength();
        return new GsmCellData(
                String.valueOf(identityGsm.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalGsm.getRssi() : -1),
                signalGsm.getDbm(),
                identityGsm.getArfcn(),
                identityGsm.getBsic(),
                identityGsm.getLac(),
                -1, // signalGsm.getRsrq(),
                -1, // signalGsm.getSnr(),
                signalGsm.getTimingAdvance(),
                -1, // identityGsm.getBandwidth(),
                band,
                baseCell.isRegistered());
    }
}
