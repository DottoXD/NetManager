package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityLte;
import android.telephony.CellInfo;
import android.telephony.CellInfoLte;
import android.telephony.CellSignalStrengthLte;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;

public class LteExtractor {
    private static final int MAXIMUM_LTE_MHZ = 20;

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
        LteCellData lteCellData = new LteCellData(
                String.valueOf(identityLte.getCi()),
                signalLte.getRssi(),
                signalLte.getRsrp(),
                identityLte.getEarfcn(),
                identityLte.getPci(),
                identityLte.getTac(),
                signalLte.getRsrq(),
                signalLte.getRssnr(),
                signalLte.getTimingAdvance(),
                identityLte.getBandwidth(),
                band,
                baseCell.isRegistered());

        processBandwidth(lteCellData, identityLte);

        return lteCellData;
    }

    private static void processBandwidth(LteCellData lteCellData, CellIdentityLte cellIdentityLte) {
        int bandwidth = cellIdentityLte.getBandwidth();

        if (!(bandwidth == CellInfo.UNAVAILABLE || (bandwidth / 1000) > MAXIMUM_LTE_MHZ)) {
            lteCellData.setBandwidth(bandwidth / 1000);
        }
    }
}
