package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityLte;
import android.telephony.CellInfo;
import android.telephony.CellInfoLte;
import android.telephony.CellSignalStrengthLte;

import androidx.annotation.NonNull;

import java.lang.reflect.Field;

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

    private static final String REFLECTION_RSSI = "mSignalStrength";
    private static final String REFLECTION_BW = "mBandwidth";
    private static final String REFLECTION_RSRP = "mRsrp";
    private static final String REFLECTION_RSRQ = "mRsrq";
    private static final String REFLECTION_SNR = "mRssnr";

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

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            lteCellData.setRawSignal(getReflectedField(signalLte, REFLECTION_RSSI));
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lteCellData.setBandwidth(getReflectedField(signalLte, REFLECTION_BW));
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            lteCellData.setProcessedSignal(getReflectedField(signalLte, REFLECTION_RSRP));
            lteCellData.setSignalQuality(getReflectedField(signalLte, REFLECTION_RSRQ));
            lteCellData.setSignalNoise(getReflectedField(signalLte, REFLECTION_SNR));
        }

        processBandwidth(lteCellData, identityLte);

        return lteCellData;
    }

    public static int getReflectedField(CellSignalStrengthLte cellSignalStrengthLte, String fieldName) {
        try {
            Field field = CellSignalStrengthLte.class.getDeclaredField(fieldName);
            field.setAccessible(true);

            return (int) field.get(cellSignalStrengthLte);
        } catch (Exception ignored) {
            return -1;
        }
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
