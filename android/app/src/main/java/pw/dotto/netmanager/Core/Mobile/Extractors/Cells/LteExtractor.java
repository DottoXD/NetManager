package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityLte;
import android.telephony.CellInfo;
import android.telephony.CellInfoLte;
import android.telephony.CellSignalStrengthLte;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;

/**
 * NetManager's LteExtractor is a component which creates a LteCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
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
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ? signalLte.getRssi() : -1),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalLte.getRsrp() : -1),
                identityLte.getEarfcn(),
                identityLte.getPci(),
                identityLte.getTac(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalLte.getRsrq() : -1),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ? signalLte.getRssnr() : -1),
                signalLte.getTimingAdvance(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ? identityLte.getBandwidth() : -1),
                band,
                baseCell.isRegistered());

        processBandwidth(lteCellData, identityLte);

        return lteCellData;
    }

    private static void processBandwidth(LteCellData lteCellData, CellIdentityLte cellIdentityLte) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P)
            return;

        int bandwidth = cellIdentityLte.getBandwidth();

        if (!(bandwidth == CellInfo.UNAVAILABLE || (bandwidth / 1000) > MAXIMUM_LTE_MHZ)) {
            lteCellData.setBandwidth(bandwidth / 1000);
        }
    }
}
