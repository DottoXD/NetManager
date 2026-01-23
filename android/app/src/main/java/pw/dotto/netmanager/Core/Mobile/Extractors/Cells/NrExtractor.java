package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityNr;
import android.telephony.CellInfo;
import android.telephony.CellInfoNr;
import android.telephony.CellSignalStrengthNr;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;

/**
 * NetManager's NrExtractor is a component which creates a NrCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class NrExtractor {
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
                        : CellInfo.UNAVAILABLE),
                -1, // identityNr.getBandwidth()
                band,
                baseCell.isRegistered());

        //
        processRsrq(nrCellData, signalNr);
        processSinr(nrCellData, signalNr);

        return nrCellData;
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
}
