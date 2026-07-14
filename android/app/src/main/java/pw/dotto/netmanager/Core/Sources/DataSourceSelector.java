package pw.dotto.netmanager.Core.Sources;

/**
 * NetManager's DataSourceSelector is a core NetManager component which decides
 * which CellDataSource to use based on the user's settings and the various
 * available data sources.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class DataSourceSelector {
    private final CellDataSource telephonySource;

    public DataSourceSelector(CellDataSource telephonySource) {
        this.telephonySource = telephonySource;
    }

    public CellDataSource select() {
        return telephonySource;
    }
}