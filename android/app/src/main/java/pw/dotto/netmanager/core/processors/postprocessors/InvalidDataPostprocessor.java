package pw.dotto.netmanager.core.processors.postprocessors;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import pw.dotto.netmanager.core.mobile.celldatas.CellData;
import pw.dotto.netmanager.core.mobile.SIMData;
import pw.dotto.netmanager.core.NetManagerCore;

/**
 * NetManager's InvalidDataPostprocessor is a cell data postprocessor
 * which removes obvious pieces of invalid data.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class InvalidDataPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getNeighborCells() == null || data.getActiveCells() == null)
            return data;

        for (CellData cell : data.getNeighborCells()) {
            if (cell.getChannelQuality() != -1 && cell.getChannelQuality() != CELL_INFO_UNAVAILABLE) {
                cell.setChannelQuality(-1);
            }
        }

        return data;
    }
}