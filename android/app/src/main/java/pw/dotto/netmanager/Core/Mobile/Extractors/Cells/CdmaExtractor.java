package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import android.telephony.CellIdentityCdma;
import android.telephony.CellInfoCdma;
import android.telephony.CellSignalStrengthCdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;

/**
 * NetManager's CdmaExtractor is a component which creates a CdmaCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class CdmaExtractor {
    @NonNull
    public static CdmaCellData get(CellInfoCdma baseCell) {
        CellIdentityCdma identityCdma = baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthCdma signalCdma = baseCell.getCellSignalStrength();
        return new CdmaCellData(
                String.valueOf(identityCdma.getBasestationId()),
                signalCdma.getCdmaDbm(),
                signalCdma.getCdmaEcio(),
                -1, // ??,
                identityCdma.getSystemId(),
                -1, // identityCdma.getTac(),
                -1, // signalCdma.getRsrq(),
                signalCdma.getEvdoSnr(),
                -1, // signalCdma.getTimingAdvance(),
                -1, // identityCdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }
}
