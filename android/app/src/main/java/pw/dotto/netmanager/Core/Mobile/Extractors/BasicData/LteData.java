package pw.dotto.netmanager.Core.Mobile.Extractors.BasicData;

import pw.dotto.netmanager.Core.Mobile.CellDatas.BasicCellData;

public class LteData {
    public static BasicCellData get(int earfcn) {
        if (earfcn >= 0 && earfcn <= 599)
            return new BasicCellData(1, 2100);
        if (earfcn >= 600 && earfcn <= 1199)
            return new BasicCellData(2, 1900);
        if (earfcn >= 1200 && earfcn <= 1949)
            return new BasicCellData(3, 1800);
        if (earfcn >= 1950 && earfcn <= 2399)
            return new BasicCellData(4, 1700);
        if (earfcn >= 2400 && earfcn <= 2649)
            return new BasicCellData(5, 850);
        if (earfcn >= 2650 && earfcn <= 2749)
            return new BasicCellData(6, 900);
        if (earfcn >= 2750 && earfcn <= 3449)
            return new BasicCellData(7, 2600);
        if (earfcn >= 3450 && earfcn <= 3799)
            return new BasicCellData(8, 900);
        if (earfcn >= 3800 && earfcn <= 4149)
            return new BasicCellData(9, 1800);
        if (earfcn >= 4150 && earfcn <= 4749)
            return new BasicCellData(10, 1700);
        if (earfcn >= 4750 && earfcn <= 5009)
            return new BasicCellData(11, 1500);
        if (earfcn >= 5010 && earfcn <= 5179)
            return new BasicCellData(12, 700);
        if (earfcn >= 5180 && earfcn <= 5279)
            return new BasicCellData(13, 700);
        if (earfcn >= 5280 && earfcn <= 5729)
            return new BasicCellData(14, 700);
        if (earfcn >= 5730 && earfcn <= 5849)
            return new BasicCellData(17, 700);
        if (earfcn >= 5850 && earfcn <= 5999)
            return new BasicCellData(18, 800);
        if (earfcn >= 6000 && earfcn <= 6149)
            return new BasicCellData(19, 800);
        if (earfcn >= 6150 && earfcn <= 6449)
            return new BasicCellData(20, 800);
        if (earfcn >= 6450 && earfcn <= 6599)
            return new BasicCellData(21, 1500);
        if (earfcn >= 6600 && earfcn <= 7499)
            return new BasicCellData(22, 3500);
        if (earfcn >= 7500 && earfcn <= 7699)
            return new BasicCellData(23, 2000);
        if (earfcn >= 7700 && earfcn <= 8039)
            return new BasicCellData(24, 1600);
        if (earfcn >= 8040 && earfcn <= 8689)
            return new BasicCellData(25, 1900);
        if (earfcn >= 8690 && earfcn <= 9039)
            return new BasicCellData(26, 850);
        if (earfcn >= 9040 && earfcn <= 9209)
            return new BasicCellData(27, 800);
        if (earfcn >= 9210 && earfcn <= 9659)
            return new BasicCellData(28, 700);
        if (earfcn >= 9660 && earfcn <= 9769)
            return new BasicCellData(29, 700);
        if (earfcn >= 9770 && earfcn <= 9869)
            return new BasicCellData(30, 2300);
        if (earfcn >= 9870 && earfcn <= 9919)
            return new BasicCellData(31, 450);
        if (earfcn >= 9920 && earfcn <= 10359)
            return new BasicCellData(32, 1500);
        if (earfcn >= 36000 && earfcn <= 36199)
            return new BasicCellData(33, 1900);
        if (earfcn >= 36200 && earfcn <= 36349)
            return new BasicCellData(34, 2000);
        if (earfcn >= 36350 && earfcn <= 36949)
            return new BasicCellData(35, 1900);
        if (earfcn >= 36950 && earfcn <= 37549)
            return new BasicCellData(36, 1900);
        if (earfcn >= 37550 && earfcn <= 37749)
            return new BasicCellData(37, 1900);
        if (earfcn >= 37750 && earfcn <= 38249)
            return new BasicCellData(38, 2600);
        if (earfcn >= 38250 && earfcn <= 38649)
            return new BasicCellData(39, 1900);
        if (earfcn >= 38650 && earfcn <= 39649)
            return new BasicCellData(40, 2300);
        if (earfcn >= 39650 && earfcn <= 41589)
            return new BasicCellData(41, 2500);
        if (earfcn >= 41590 && earfcn <= 43589)
            return new BasicCellData(42, 3500);
        if (earfcn >= 43590 && earfcn <= 45589)
            return new BasicCellData(43, 3700);
        if (earfcn >= 45590 && earfcn <= 46589)
            return new BasicCellData(44, 700);
        if (earfcn >= 46590 && earfcn <= 46789)
            return new BasicCellData(45, 1500);
        if (earfcn >= 46790 && earfcn <= 54539)
            return new BasicCellData(46, 5200);
        if (earfcn >= 54540 && earfcn <= 55239)
            return new BasicCellData(47, 5900);
        if (earfcn >= 55240 && earfcn <= 56739)
            return new BasicCellData(48, 3600);
        if (earfcn >= 56740 && earfcn <= 58239)
            return new BasicCellData(49, 3600);
        if (earfcn >= 58240 && earfcn <= 59089)
            return new BasicCellData(50, 1500);
        if (earfcn >= 59090 && earfcn <= 59139)
            return new BasicCellData(51, 1500);
        if (earfcn >= 59140 && earfcn <= 60139)
            return new BasicCellData(52, 3300);
        if (earfcn >= 60140 && earfcn <= 60254)
            return new BasicCellData(53, 2500);
        if (earfcn >= 65536 && earfcn <= 66435)
            return new BasicCellData(65, 2100);
        if (earfcn >= 66436 && earfcn <= 67335)
            return new BasicCellData(66, 1700);
        if (earfcn >= 67336 && earfcn <= 67535)
            return new BasicCellData(67, 700);
        if (earfcn >= 67536 && earfcn <= 67835)
            return new BasicCellData(68, 700);
        if (earfcn >= 67836 && earfcn <= 68335)
            return new BasicCellData(69, 2500);
        if (earfcn >= 68336 && earfcn <= 68585)
            return new BasicCellData(70, 1700);
        if (earfcn >= 68586 && earfcn <= 68935)
            return new BasicCellData(71, 600);
        if (earfcn >= 68936 && earfcn <= 68985)
            return new BasicCellData(72, 450);
        if (earfcn >= 68986 && earfcn <= 69035)
            return new BasicCellData(73, 450);
        if (earfcn >= 69036 && earfcn <= 69465)
            return new BasicCellData(74, 1500);
        if (earfcn >= 69466 && earfcn <= 70315)
            return new BasicCellData(75, 1500);
        if (earfcn >= 70316 && earfcn <= 70365)
            return new BasicCellData(76, 1500);
        if (earfcn >= 70366 && earfcn <= 70545)
            return new BasicCellData(85, 700);
        if (earfcn >= 70546 && earfcn <= 70595)
            return new BasicCellData(87, 410);
        if (earfcn >= 70596 && earfcn <= 70645)
            return new BasicCellData(88, 410);
        if (earfcn >= 70646 && earfcn <= 70655)
            return new BasicCellData(103, 700);

        return new BasicCellData(-1, -1);
    }
}
