package pw.dotto.netmanager.Core.Sources;

import pw.dotto.netmanager.Core.Sources.Diag.DiagCellDataSource;
import pw.dotto.netmanager.Core.Sources.Shizuku.ShizukuCellDataSource;

/**
 * NetManager's DataSourceSelector is a core NetManager component which decides
 * which CellDataSource to use based on the user's settings and the various
 * available data sources.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class DataSourceSelector {
    private final TelephonyCellDataSource telephonySource;
    private final ShizukuCellDataSource shizukuSource;
    private final DiagCellDataSource diagCellDataSource;

    public DataSourceSelector(TelephonyCellDataSource telephonySource) {
        this.telephonySource = telephonySource;

        this.shizukuSource = new ShizukuCellDataSource(telephonySource);
        this.diagCellDataSource = new DiagCellDataSource(telephonySource);
    }

    public CellDataSource select() {
        if (diagCellDataSource.isAvailable(null)) {
            return diagCellDataSource;
        }

        if (shizukuSource.isAvailable(null)) {
            return shizukuSource;
        }

        return telephonySource;
    }

    public TelephonyCellDataSource getTelephonySource() {
        return telephonySource;
    }
}