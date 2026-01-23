package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's BasicCellData is a core component which comes in handy for
 * saving cells bands and frequencies in a simple way.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class BasicCellData {
    private final int band;
    private final int frequency;

    public BasicCellData(int band, int frequency) {
        this.band = band;
        this.frequency = frequency;
    }

    /**
     * Returns the cell's band (or -1 if unavailable).
     *
     * @return The band's 3GPP number.
     */
    public int getBand() {
        return band;
    }

    /**
     * Returns the band's frequency in MHz (or -1 if unavailable).
     *
     * @return The band's frequency in MHz.
     */
    public int getFrequency() {
        return frequency;
    }
}
