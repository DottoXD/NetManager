package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityGsm;
import android.telephony.CellInfoGsm;
import android.telephony.CellSignalStrengthGsm;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

/**
 * NetManager's GsmExtractor is a component which creates a GsmCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
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
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalGsm.getTimingAdvance() : -1),
                -1, // identityGsm.getBandwidth(),
                band,
                baseCell.isRegistered());
    }
}
