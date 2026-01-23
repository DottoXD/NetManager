package pw.dotto.netmanager.Core.Mobile.Extractors.BasicData;

import pw.dotto.netmanager.Core.Mobile.CellDatas.BasicCellData;

/**
 * NetManager's GsmData is a component which defines different ARFCN ranges to
 * identify bands.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class GsmData {
    /**
     * Return a BasicCellData object based on the provided ARFCN and region.
     *
     * @param arfcn  The cell's ARFCN.
     * @param region The network's region.
     * @return A BasicCellData object.
     */
    public static BasicCellData get(int arfcn, String region) {
        if ("US".equals(region) && arfcn >= 512 && arfcn <= 810)
            return new BasicCellData(2, 1900);
        if (arfcn >= 512 && arfcn <= 885)
            return new BasicCellData(3, 1800);
        if (arfcn >= 128 && arfcn <= 251)
            return new BasicCellData(5, 850);
        if (arfcn >= 438 && arfcn <= 511)
            return new BasicCellData(6, 750);
        if (arfcn >= 0 && arfcn <= 124 || arfcn >= 955 && arfcn <= 1023)
            return new BasicCellData(8, 900);
        if (arfcn >= 259 && arfcn <= 293)
            return new BasicCellData(31, 450);
        if (arfcn >= 306 && arfcn <= 340)
            return new BasicCellData(72, 480);

        return new BasicCellData(-1, -1);
    }
}
