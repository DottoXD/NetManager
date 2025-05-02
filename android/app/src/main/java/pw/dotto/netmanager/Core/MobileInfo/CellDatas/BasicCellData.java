package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class BasicCellData {
    private final int band;
    private final double frequency;

    public BasicCellData(int band, double frequency) {
        this.band = band;
        this.frequency = frequency;
    }

    public int getBand() {
        return band;
    }

    public double getFrequency() {
        return frequency;
    }
}
