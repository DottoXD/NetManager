package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityLte;
import android.telephony.CellInfoLte;
import android.telephony.CellSignalStrengthLte;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;

public class LteExtractor {
    @NonNull
    public static LteCellData get(CellInfoLte baseCell) {
        CellIdentityLte identityLte = baseCell.getCellIdentity();

        int band = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            int[] bands = identityLte.getBands();
            if (bands.length > 0)
                band = bands[0];
        }

        CellSignalStrengthLte signalLte = baseCell.getCellSignalStrength();
        return new LteCellData(
                String.valueOf(identityLte.getCi()),
                signalLte.getRssi(),
                signalLte.getRsrp(),
                identityLte.getEarfcn(),
                identityLte.getPci(),
                identityLte.getTac(),
                signalLte.getRssnr(),
                signalLte.getRssnr(),
                signalLte.getTimingAdvance(),
                identityLte.getBandwidth() / 1000,
                band,
                baseCell.isRegistered());
    }
}
