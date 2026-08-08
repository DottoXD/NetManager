package pw.dotto.netmanager.Core.Processors.Postprocessors;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's QualcommActiveCellsPostprocessor is a cell data postprocessor
 * which
 * adds LTE and NR NSA cells incorrectly flagged as neighboring cells to the
 * active cells list.
 *
 * @author DottoXD
 * @version 0.1.4
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
