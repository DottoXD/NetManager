package pw.dotto.netmanager.Core.Processors.Postprocessors;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;

/**
 * NetManager's PixelTAPostprocessor is a cell data postprocessor which filters
 * out cells with a value equal to 0 on Google Pixel phones.
 * Most Google Pixel models often retrun 0 as a placeholder timing advance value
 * on secondary SIMs.
 *
 * @author DottoXD
 * @version 0.1.2
 */
public class PixelTAPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId) {
        data.getPrimaryCell().setTimingAdvance(-1);
        for (CellData cell : data.getActiveCells()) {
            if (cell.getTimingAdvance() == 0)
                cell.setTimingAdvance(-1);
        }

        return data;
    }
}
