package pw.dotto.netmanager.Core.Processors.Preprocessors;

import android.os.Build;
import android.telephony.CellIdentity;
import android.telephony.CellInfo;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Core.Sources.Telephony.CellInfoCache;
import pw.dotto.netmanager.Core.Sources.Telephony.TelephonyCellDataSource;

/**
 * NetManager's ExtraCellsPostprocessor is a simple cell data preprocessor which
 * adds cells gathered from Telephony in any single way that is not
 * getAllCellInfo() (cached cells, cells from cellInfoListener...) to the list
 * of cells.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class ExtraCellsPreprocessor implements Preprocessor {

    @Override
    public List<CellInfo> process(List<CellInfo> rawCellInfo, int simId, NetManagerCore netManagerCore) {
        if (rawCellInfo == null || rawCellInfo.isEmpty() || simId < 0 || netManagerCore == null)
            return rawCellInfo;

        List<CellInfo> additionalCells = null;
        SIMSlotState simSlotState = netManagerCore.getSlot(simId);

        if (simSlotState != null) {
            if (simSlotState.cellInfoListener != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                additionalCells = simSlotState.cellInfoListener.getLatestCellInfo();
            } else if (simSlotState.legacyPhoneStateListener != null) {
                additionalCells = simSlotState.legacyPhoneStateListener.getLatestCellInfo();
            }
        }

        CellInfoCache cellInfoCache = TelephonyCellDataSource.getCellInfoCache();
        if (cellInfoCache == null)
            cellInfoCache = new CellInfoCache();

        List<CellInfo> cachedCells = cellInfoCache.getValidCells(simId);
        if (!cachedCells.isEmpty()) {
            if (additionalCells == null) {
                additionalCells = new ArrayList<>();
            } else {
                additionalCells = new ArrayList<>(additionalCells);
            }

            additionalCells.addAll(cachedCells);
        }

        if (additionalCells != null && !additionalCells.isEmpty()) {
            if (rawCellInfo.isEmpty()) {
                rawCellInfo.addAll(additionalCells);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Set<CellIdentity> existingIdentities = new HashSet<>();
                for (CellInfo cell : rawCellInfo) {
                    if (cell != null && cell.getCellIdentity() != null) {
                        existingIdentities.add(cell.getCellIdentity());
                    }
                }

                for (CellInfo additionalCell : additionalCells) {
                    if (additionalCell != null) {
                        CellIdentity identity = additionalCell.getCellIdentity();
                        if (identity != null && !existingIdentities.contains(identity)) {
                            rawCellInfo.add(additionalCell);
                            existingIdentities.add(identity);
                        }
                    }
                }
            } else {
                for (CellInfo additionalCell : additionalCells) {
                    if (additionalCell != null && !rawCellInfo.contains(additionalCell)) {
                        rawCellInfo.add(additionalCell);
                    }
                }
            }
        }

        return rawCellInfo;
    }
}