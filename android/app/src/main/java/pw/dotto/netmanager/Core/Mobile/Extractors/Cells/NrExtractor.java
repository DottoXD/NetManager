package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.os.Build;
import android.telephony.CellIdentityNr;
import android.telephony.CellInfo;
import android.telephony.CellInfoNr;
import android.telephony.CellSignalStrengthNr;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;

public class NrExtractor {
    @NonNull
    public static NrCellData get(CellInfoNr baseCell) {
        CellIdentityNr identityNr = (CellIdentityNr) baseCell.getCellIdentity();

        int band = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            int[] bands = identityNr.getBands();
            if (bands.length > 0)
                band = bands[0];
        }

        CellSignalStrengthNr signalNr = (CellSignalStrengthNr) baseCell.getCellSignalStrength();
        return new NrCellData(
                String.valueOf(identityNr.getNci()),
                signalNr.getCsiRsrp(),
                signalNr.getSsRsrp(),
                identityNr.getNrarfcn(),
                identityNr.getPci(),
                identityNr.getTac(),
                (signalNr.getSsRsrq() == CellInfo.UNAVAILABLE ? signalNr.getCsiRsrq() : signalNr.getSsRsrq()),
                (signalNr.getSsSinr() == CellInfo.UNAVAILABLE ? signalNr.getCsiSinr() : signalNr.getSsSinr()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        ? (signalNr.getTimingAdvanceMicros() == Integer.MAX_VALUE ? -1
                                : signalNr.getTimingAdvanceMicros())
                        : -1),
                -1, // identityNr.getBandwidth()
                band,
                baseCell.isRegistered());
    }
}
