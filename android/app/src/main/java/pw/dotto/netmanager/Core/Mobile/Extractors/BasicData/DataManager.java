package pw.dotto.netmanager.Core.Mobile.Extractors.BasicData;

import pw.dotto.netmanager.Core.Mobile.CellDatas.BasicCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;

import android.telephony.CellInfo;

/**
 * NetManager's DataManager is a core component which manages BasicCellData for
 * all cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class DataManager {
    /**
     * Returns a BasicCellData object based on the CellData and mcc provided.
     *
     * @param cellData Any kind of CellData.
     * @param mcc      The cell network's mobile country code.
     * @return A BasicCellData object.
     */
    public static BasicCellData getBasicData(CellData cellData, int mcc) {
        if (cellData instanceof NrCellData) {
            String region = getRegion(mcc);

            BasicCellData basicCellData = NrData.get(cellData.getChannelNumber(), region);
            if (basicCellData.getBand() == -1
                    && (cellData.getBand() != -1 && cellData.getBand() != CellInfo.UNAVAILABLE)) {
                int freq;

                if (cellData.getChannelNumber() <= 599999)
                    freq = (int) (0.005 * cellData.getChannelNumber());
                else
                    freq = 3000 + (int) (0.015 * (cellData.getChannelNumber() - 600000));

                return new BasicCellData(cellData.getBand(), freq);
            }

            return basicCellData;
        } else if (cellData instanceof LteCellData) {
            return LteData.get(cellData.getChannelNumber());
        } else if (cellData instanceof WcdmaCellData || cellData instanceof TdscdmaCellData) {
            return UmtsData.get(cellData.getChannelNumber());
        } else if (cellData instanceof GsmCellData) {
            String region = getRegion(mcc);

            return GsmData.get(cellData.getChannelNumber(), region);
        }

        return new BasicCellData(-1, -1);
    }

    /**
     * Returns a string identifier of the network's zone based on the mobile country
     * code.
     *
     * @param mcc A valid mobile country code.
     * @return A string containing the network's zone.
     */
    private static String getRegion(int mcc) {
        if (mcc >= 202 && mcc <= 289)
            return "EU"; // Europe
        if (mcc >= 310 && mcc <= 316)
            return "US"; // NA
        if (mcc >= 440 && mcc <= 459)
            return "APAC"; // Asia

        return "GLOBAL";
    }
}
