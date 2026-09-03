package pw.dotto.netmanager.Core.Processors.Postprocessors;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's PixelDataPostprocessor is a cell data postprocessor which
 * filters
 * out invalid cell data on Google Pixel phones.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class PixelDataPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data.getPrimaryCell() != null && data.getPrimaryCell().getTimingAdvance() == 0)
            data.getPrimaryCell().setTimingAdvance(-1);

        for (CellData cell : data.getActiveCells()) {
            if (cell == null)
                continue;

            if (cell.getTimingAdvance() == 0)
                cell.setTimingAdvance(-1);

            /*
             * if (cell instanceof NrCellData && cell.getSignalNoise() == 0 &&
             * cell.getSignalQuality() > -12) {
             * cell.setSignalNoise(-1);
             * }
             */
        }

        return data;
    }
}
