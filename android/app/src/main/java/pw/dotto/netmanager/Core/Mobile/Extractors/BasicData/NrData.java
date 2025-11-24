package pw.dotto.netmanager.Core.Mobile.Extractors.BasicData;

import pw.dotto.netmanager.Core.Mobile.CellDatas.BasicCellData;

public class NrData {
    public static BasicCellData get(int nrarfcn, String region) {
        if (nrarfcn >= 422000 && nrarfcn <= 434000)
            return new BasicCellData(1, 2100);
        if (nrarfcn >= 386000 && nrarfcn <= 398000)
            return new BasicCellData(2, 1900);
        if (nrarfcn >= 361000 && nrarfcn <= 376000)
            return new BasicCellData(3, 1800);
        if (nrarfcn >= 173800 && nrarfcn <= 178800)
            return new BasicCellData(5, 850);
        if (nrarfcn >= 524000 && nrarfcn <= 538000)
            return new BasicCellData(7, 2600);
        if (nrarfcn >= 185000 && nrarfcn <= 192000)
            return new BasicCellData(8, 900);
        if (nrarfcn >= 145800 && nrarfcn <= 149200)
            return new BasicCellData(12, 700);
        if (nrarfcn >= 149200 && nrarfcn <= 151600)
            return new BasicCellData(13, 700);
        if (nrarfcn >= 151600 && nrarfcn <= 153600)
            return new BasicCellData(14, 700);
        if ("APAC".equals(region) && nrarfcn >= 172000 && nrarfcn <= 175000)
            return new BasicCellData(18, 800);
        if ("EU".equals(region) && nrarfcn >= 158200 && nrarfcn <= 164200)
            return new BasicCellData(20, 800);
        if ("US".equals(region) && nrarfcn >= 305000 && nrarfcn <= 311800)
            return new BasicCellData(24, 1600);
        if (nrarfcn >= 386000 && nrarfcn <= 399000)
            return new BasicCellData(25, 1900);
        if (nrarfcn >= 171800 && nrarfcn <= 178800)
            return new BasicCellData(26, 850);
        if (nrarfcn >= 151600 && nrarfcn <= 160600)
            return new BasicCellData(28, 700);
        if (nrarfcn >= 143400 && nrarfcn <= 145600)
            return new BasicCellData(29, 700);
        if (nrarfcn >= 461000 && nrarfcn <= 472000)
            return new BasicCellData(30, 2300);
        if (nrarfcn >= 90500 && nrarfcn <= 93500)
            return new BasicCellData(31, 450);
        if (nrarfcn >= 402000 && nrarfcn <= 405000)
            return new BasicCellData(34, 2000);
        if (nrarfcn >= 514000 && nrarfcn <= 524000)
            return new BasicCellData(38, 2600);
        if (nrarfcn >= 376000 && nrarfcn <= 384000)
            return new BasicCellData(39, 1900);
        if (nrarfcn >= 460000 && nrarfcn <= 480000)
            return new BasicCellData(40, 2300);
        if (nrarfcn >= 499200 && nrarfcn <= 537999)
            return new BasicCellData(41, 2500);

        if (nrarfcn >= 790334 && nrarfcn <= 795000)
            return new BasicCellData(47, 5200);
        if (nrarfcn >= 743334 && nrarfcn <= 795000)
            return new BasicCellData(46, 5200);

        if ("US".equals(region) && nrarfcn >= 636667 && nrarfcn <= 646666)
            return new BasicCellData(48, 3600);

        if ("APAC".equals(region) && nrarfcn >= 285400 && nrarfcn <= 286400)
            return new BasicCellData(51, 1500);
        if ("EU".equals(region) && nrarfcn >= 286400 && nrarfcn <= 303400)
            return new BasicCellData(50, 1500);

        if (nrarfcn >= 496700 && nrarfcn <= 499000)
            return new BasicCellData(53, 2500);
        if (nrarfcn >= 334000 && nrarfcn <= 335000)
            return new BasicCellData(54, 1700);
        if ("US".equals(region) && nrarfcn >= 422000 && nrarfcn <= 440000)
            return new BasicCellData(66, 1700);
        if ("EU".equals(region) && nrarfcn >= 422000 && nrarfcn <= 440000)
            return new BasicCellData(67, 1700);
        if (nrarfcn >= 422000 && nrarfcn <= 440000)
            return new BasicCellData(65, 2100);

        if (nrarfcn >= 399000 && nrarfcn <= 404000)
            return new BasicCellData(70, 2000);
        if ("US".equals(region) && nrarfcn >= 123400 && nrarfcn <= 130400)
            return new BasicCellData(71, 600);
        if ("EU".equals(region) && nrarfcn >= 123400 && nrarfcn <= 130400)
            return new BasicCellData(72, 600);
        if ("EU".equals(region) && nrarfcn >= 285400 && nrarfcn <= 286400)
            return new BasicCellData(76, 1500);
        if ("US".equals(region) && nrarfcn >= 295000 && nrarfcn <= 303600)
            return new BasicCellData(74, 1500);
        if ("EU".equals(region) && nrarfcn >= 295000 && nrarfcn <= 303600)
            return new BasicCellData(75, 1500);

        if (nrarfcn >= 653334 && nrarfcn <= 680000)
            return new BasicCellData(77, 3700);
        if (nrarfcn >= 620000 && nrarfcn <= 653333)
            return new BasicCellData(78, 3500);
        if (nrarfcn >= 693334 && nrarfcn <= 733333)
            return new BasicCellData(79, 4500);
        if (nrarfcn >= 163000 && nrarfcn <= 169800)
            return new BasicCellData(80, 1800);
        if (nrarfcn >= 197000 && nrarfcn <= 201600)
            return new BasicCellData(81, 850);
        if ("EU".equals(region) && nrarfcn >= 166400 && nrarfcn <= 172400)
            return new BasicCellData(82, 900);
        if ("EU".equals(region) && nrarfcn >= 143400 && nrarfcn <= 151600)
            return new BasicCellData(83, 700);
        if (nrarfcn >= 384000 && nrarfcn <= 396000)
            return new BasicCellData(84, 2100);
        if ("US".equals(region) && nrarfcn >= 145600 && nrarfcn <= 149200)
            return new BasicCellData(85, 700);
        if ("US".equals(region) && nrarfcn >= 285400 && nrarfcn <= 286400)
            return new BasicCellData(86, 1500);
        if ("US".equals(region) && nrarfcn >= 410000 && nrarfcn <= 415000)
            return new BasicCellData(89, 850);
        if (nrarfcn >= 480000 && nrarfcn <= 486000)
            return new BasicCellData(90, 2500);

        if ("EU".equals(region) && nrarfcn >= 285400 && nrarfcn <= 286400) // to be fixed!
            return new BasicCellData(91, 1500);
        if ("EU".equals(region) && nrarfcn >= 286400 && nrarfcn <= 303400)
            return new BasicCellData(92, 1500);
        if ("EU".equals(region) && nrarfcn >= 285400 && nrarfcn <= 286400)
            return new BasicCellData(93, 1500);
        if ("EU".equals(region) && nrarfcn >= 286400 && nrarfcn <= 303400)
            return new BasicCellData(94, 1500);

        if ("APAC".equals(region) && nrarfcn >= 143400 && nrarfcn <= 151600)
            return new BasicCellData(95, 700);
        if ("US".equals(region) && nrarfcn >= 2070833 && nrarfcn <= 2084999)
            return new BasicCellData(261, 27500);
        if (nrarfcn >= 2054167 && nrarfcn <= 2104166)
            return new BasicCellData(257, 26500);
        if (nrarfcn >= 2016667 && nrarfcn <= 2070833)
            return new BasicCellData(258, 24250);
        if (nrarfcn >= 2229167 && nrarfcn <= 2279166)
            return new BasicCellData(260, 37000);

        return new BasicCellData(-1, -1);
    }
}
