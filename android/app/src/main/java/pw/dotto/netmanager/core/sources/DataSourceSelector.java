package pw.dotto.netmanager.core.sources;

import pw.dotto.netmanager.core.sources.shizuku.ShizukuCellDataSource;
import pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource;

/**
 * NetManager's DataSourceSelector is a core NetManager component which decides
 * which CellDataSource to use based on the user's settings and the various
 * available data sources.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class DataSourceSelector {
    private final TelephonyCellDataSource telephonySource;
    private final ShizukuCellDataSource shizukuSource;

    public DataSourceSelector(TelephonyCellDataSource telephonySource) {
        this.telephonySource = telephonySource;
        this.shizukuSource = new ShizukuCellDataSource(telephonySource);
    }

    public CellDataSource select() {
        if (shizukuSource.isAvailable(null)) {
            return shizukuSource;
        }

        return telephonySource;
    }

    public TelephonyCellDataSource getTelephonySource() {
        return telephonySource;
    }
}