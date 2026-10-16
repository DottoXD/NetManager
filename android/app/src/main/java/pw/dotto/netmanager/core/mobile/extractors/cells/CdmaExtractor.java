package pw.dotto.netmanager.core.mobile.extractors.cells;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.telephony.CellIdentityCdma;
import android.telephony.CellInfoCdma;
import android.telephony.CellSignalStrengthCdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.core.mobile.celldatas.CdmaCellData;

/**
 * NetManager's CdmaExtractor is a component which creates a CdmaCellData object
 * based on the provided cell info.
 *
 * @author DottoXD
 * @version 0.2.1
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
