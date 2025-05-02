package pw.dotto.netmanager.Core.MobileInfo;

import pw.dotto.netmanager.Core.MobileInfo.CellDatas.BasicCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.TdscmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.WcdmaCellData;

public class DataExtractor {
    public static BasicCellData getBasicData(CellData cellData) { //todo the methods
        if(cellData instanceof NrCellData) {
            return getNrBasicData(cellData.getChannelNumber());
        } else if(cellData instanceof LteCellData) {
            return getLteBasicData(cellData.getChannelNumber());
        } else if(cellData instanceof WcdmaCellData || cellData instanceof TdscmaCellData) {
            return getUmtsBasicData(cellData.getChannelNumber());
        //} else if(cellData instanceof CdmaCellData) {
        } else if(cellData instanceof GsmCellData) {
            return getGsmBasicData(cellData.getChannelNumber());
        }

        return new BasicCellData(-1, -1);
    }
}
