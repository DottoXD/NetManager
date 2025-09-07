package pw.dotto.netmanager.Utils;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

public class Mobile {
    public static int getFactor(CellData cellData) {
        int factor = 256;

        if (cellData instanceof GsmCellData)
            factor = 64;
        else if (cellData instanceof CdmaCellData)
            factor = 1;

        return factor;
    }
}
