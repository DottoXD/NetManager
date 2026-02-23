package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityNr;
import android.telephony.CellInfo;
import android.telephony.CellInfoNr;
import android.telephony.CellSignalStrengthNr;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.lang.reflect.Field;

import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;

/**
 * NetManager's NrExtractor is a component which creates a NrCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class NrExtractor {
    private static final String REFLECTION_TA = "mTimingAdvance";

    @NonNull
    public static NrCellData get(CellInfoNr baseCell) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return new NrCellData(
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

        CellIdentityNr identityNr = (CellIdentityNr) baseCell.getCellIdentity();
        CellSignalStrengthNr signalNr = (CellSignalStrengthNr) baseCell.getCellSignalStrength();

        int band = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            int[] bands = identityNr.getBands();
            if (bands.length > 0)
                band = bands[0];
        }

        NrCellData nrCellData = new NrCellData(
                String.valueOf(identityNr.getNci()),
                signalNr.getCsiRsrp(),
                signalNr.getSsRsrp(),
                identityNr.getNrarfcn(),
                identityNr.getPci(),
                identityNr.getTac(),
                signalNr.getSsRsrq(),
                signalNr.getSsSinr(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        ? signalNr.getTimingAdvanceMicros()
                        : -1),
                -1, // identityNr.getBandwidth()
                band,
                baseCell.isRegistered());

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            nrCellData.setTimingAdvance(getReflectedField(signalNr, REFLECTION_TA));
        }

        processRsrq(nrCellData, signalNr);
        processSinr(nrCellData, signalNr);

        return nrCellData;
    }

    public static int getReflectedField(CellSignalStrengthNr cellSignalStrengthNr, String fieldName) {
        try {
            Field field = CellSignalStrengthNr.class.getDeclaredField(fieldName);
            field.setAccessible(true);

            return (int) field.get(cellSignalStrengthNr);
        } catch (Exception ignored) {
            return -1;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private static void processRsrq(NrCellData nrCellData, CellSignalStrengthNr signalNr) {
        int rsrq = nrCellData.getSignalQuality();

        if (rsrq == CellInfo.UNAVAILABLE) {
            rsrq = signalNr.getCsiRsrq();

            if (rsrq != CellInfo.UNAVAILABLE) {
                nrCellData.setSignalQualityString("CSI RSRQ");
                nrCellData.setSignalQuality(rsrq);
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.Q)
    private static void processSinr(NrCellData nrCellData, CellSignalStrengthNr signalNr) {
        int sinr = nrCellData.getSignalNoise();

        if (sinr == CellInfo.UNAVAILABLE) {
            sinr = signalNr.getCsiSinr();

            if (sinr != CellInfo.UNAVAILABLE) {
                nrCellData.setSignalNoiseString("CSI SINR");
                nrCellData.setSignalNoise(sinr);
            }
        }
    }

    public static int getMaximumNrMhz(int frequency) {
        if (frequency <= 1000)
            return 20;
        if (frequency <= 3000)
            return 50;
        if (frequency <= 7000)
            return 100;

        return 400;
    }
}
