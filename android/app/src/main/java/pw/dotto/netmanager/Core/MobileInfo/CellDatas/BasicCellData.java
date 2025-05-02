package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class BasicCellData {
    private final int band;
    private final int frequency;

    public BasicCellData(int band, int frequency) {
        this.band = band;
        this.frequency = frequency;
    }

    public int getBand() {
        return band;
    }

    public int getFrequency() {
        return frequency;
    }
}
