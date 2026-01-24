package pw.dotto.netmanager.Utils;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

/**
 * NetManager's Mobile class is a component useful to get the division factors
 * (for Node/CellID calculations) across different CellData types.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class Mobile {
    /**
     * Returns the mobile cell's division factor based on the provided CellData
     * type.
     *
     * @param cellData A valid CellData object.
     * @return The cell division factor.
     */
    public static int getFactor(CellData cellData) {
        int factor = 256;

        if (cellData instanceof GsmCellData)
            factor = 64;
        else if (cellData instanceof CdmaCellData)
            factor = 1;

        return factor;
    }
}
