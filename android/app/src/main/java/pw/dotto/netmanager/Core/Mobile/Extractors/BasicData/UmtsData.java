package pw.dotto.netmanager.Core.Mobile.Extractors.BasicData;

import pw.dotto.netmanager.Core.Mobile.CellDatas.BasicCellData;

/**
 * NetManager's UmtsData is a component which defines different UARFCN ranges to
 * identify bands.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class UmtsData {
    /**
     * Return a BasicCellData object based on the provided UARFCN and region.
     *
     * @param uarfcn The cell's UARFCN.
     * @return A BasicCellData object.
     */
    public static BasicCellData get(int uarfcn) {
        if (uarfcn >= 10562 && uarfcn <= 10838)
            return new BasicCellData(1, 2100);
        if (uarfcn >= 412 && uarfcn <= 687 || uarfcn >= 9662 && uarfcn <= 9938)
            return new BasicCellData(2, 1900);
        if (uarfcn >= 1162 && uarfcn <= 1513)
            return new BasicCellData(3, 1800);
        if (uarfcn >= 1537 && uarfcn <= 2087)
            return new BasicCellData(4, 1700);
        if (uarfcn >= 1007 && uarfcn <= 1087 || uarfcn >= 4357 && uarfcn <= 4458)
            return new BasicCellData(5, 850);
        if (uarfcn >= 2237 && uarfcn <= 2563)
            return new BasicCellData(7, 2600);
        if (uarfcn >= 2937 && uarfcn <= 3088)
            return new BasicCellData(8, 900);
        if (uarfcn >= 9237 && uarfcn <= 9387)
            return new BasicCellData(9, 1800);
        if (uarfcn >= 3112 && uarfcn <= 3388)
            return new BasicCellData(10, 1700);
        if (uarfcn >= 3712 && uarfcn <= 3787)
            return new BasicCellData(11, 1500);
        if (uarfcn >= 3842 && uarfcn <= 3903)
            return new BasicCellData(12, 700);
        if (uarfcn >= 4017 && uarfcn <= 4043)
            return new BasicCellData(13, 700);
        if (uarfcn >= 4117 && uarfcn <= 4143)
            return new BasicCellData(14, 700);
        if (uarfcn >= 712 && uarfcn <= 763)
            return new BasicCellData(19, 800);
        if (uarfcn >= 4512 && uarfcn <= 4638)
            return new BasicCellData(20, 800);
        if (uarfcn >= 862 && uarfcn <= 912)
            return new BasicCellData(21, 1500);
        if (uarfcn >= 4662 && uarfcn <= 5038)
            return new BasicCellData(22, 3500);
        if (uarfcn >= 5112 && uarfcn <= 5413 || uarfcn >= 6292 && uarfcn <= 6592)
            return new BasicCellData(25, 1900);
        if (uarfcn >= 5762 && uarfcn <= 5913)
            return new BasicCellData(26, 850);
        if (uarfcn >= 6617 && uarfcn <= 6813)
            return new BasicCellData(32, 1500);

        return new BasicCellData(-1, -1);
    }
}
