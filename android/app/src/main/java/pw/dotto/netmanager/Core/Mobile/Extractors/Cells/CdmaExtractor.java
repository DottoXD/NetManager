package pw.dotto.netmanager.Core.Mobile.Extractors.Cells;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

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
 * @version 0.1.6
 */
public class CdmaExtractor {
    @NonNull
    public static CdmaCellData get(CellInfoCdma baseCell) {
        CellIdentityCdma identityCdma = baseCell.getCellIdentity();

        CellSignalStrengthCdma signalCdma = baseCell.getCellSignalStrength();
        return new CdmaCellData(
                String.valueOf(identityCdma.getBasestationId()),
                signalCdma.getCdmaDbm(),
                signalCdma.getCdmaEcio(),
                CELL_INFO_UNAVAILABLE, // ??,
                identityCdma.getSystemId(),
                identityCdma.getNetworkId(),
                CELL_INFO_UNAVAILABLE, // signalCdma.getRsrq(),
                signalCdma.getEvdoSnr(),
                CELL_INFO_UNAVAILABLE, // signalCdma.getCqi(),
                CELL_INFO_UNAVAILABLE, // signalCdma.getTimingAdvance(),
                CELL_INFO_UNAVAILABLE, // identityCdma.getBandwidth(),
                CELL_INFO_UNAVAILABLE,
                baseCell.isRegistered());
    }
}
