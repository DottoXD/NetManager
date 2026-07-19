package pw.dotto.netmanager.Utils;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;

/**
 * NetManager's Mobile class is a component useful to get the division factors
 * (for Node/CellID calculations) across different CellData types.
 *
 * @author DottoXD
 * @version 0.1.0
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

    /**
     * Returns a label for a given mobile technology generation.
     *
     * @param gen The network's generation.
     * @return A label for that network gen.
     */
    public static String getGenerationLabel(int gen) {
        return switch (gen) {
            case 5 -> "5G NR";
            case 4 -> "4G LTE";
            case 3 -> "3G";
            case 2 -> "2G";
            default -> "N/A";
        };
    }
}
