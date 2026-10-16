package pw.dotto.netmanager.core.processors.postprocessors;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.core.mobile.celldatas.CellData;
import pw.dotto.netmanager.core.mobile.celldatas.LteCellData;
import pw.dotto.netmanager.core.mobile.celldatas.NrCellData;
import pw.dotto.netmanager.core.mobile.SIMData;
import pw.dotto.netmanager.core.NetManagerCore;

/**
 * NetManager's QualcommActiveCellsPostprocessor is a cell data postprocessor
 * which
 * adds LTE and NR NSA cells incorrectly flagged as neighboring cells to the
 * active cells list.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class QualcommActiveCellsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getNeighborCells() == null || data.getActiveCells() == null
                || data.getActiveCells().length > 1 || data.getNetworkGen() < 4)
            return data;

        if (!netManagerCore.isActiveDataSubscription(simId)) {
            return data;
        }

        List<CellData> toSwitch = new ArrayList<>();
        for (CellData neighboringCell : data.getNeighborCells()) {
            if (neighboringCell.getAreaCode() >= 0 && neighboringCell.getAreaCode() != CELL_INFO_UNAVAILABLE
                    && (neighboringCell instanceof LteCellData || neighboringCell instanceof NrCellData)) {
                toSwitch.add(neighboringCell);
            }
        }

        for (CellData cell : toSwitch) {
            data.addActiveCell(cell);
            data.removeNeighborCell(cell);
        }

        return data;
    }
}
