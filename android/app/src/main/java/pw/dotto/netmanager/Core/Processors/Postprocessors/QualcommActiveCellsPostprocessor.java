package pw.dotto.netmanager.Core.Processors.Postprocessors;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's QualcommActiveCellsPostprocessor is a cell data postprocessor
 * which
 * adds LTE and NR NSA cells incorrectly flagged as neighboring cells to the
 * active cells list.
 *
 * @author DottoXD
 * @version 0.1.3
 */
public class QualcommActiveCellsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getNeighborCells() == null || data.getActiveCells() == null
                || data.getActiveCells().length > 1)
            return data;

        for (CellData neighboringCell : data.getNeighborCells()) {
            if (neighboringCell.getAreaCode() >= 0) {
                data.addActiveCell(neighboringCell);
                data.removeNeighborCell(neighboringCell);
            }
        }

        return data;
    }
}
