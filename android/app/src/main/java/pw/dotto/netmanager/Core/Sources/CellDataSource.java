package pw.dotto.netmanager.Core.Sources;

import android.content.Context;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.SIMData;

/**
 * NetManager's CellDataSource is an interface used to define a data source that
 * allows NetManager to fetch cell data. A source can be optionally disabled.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public interface CellDataSource {
    boolean isAvailable(Context context);

    SIMData fetch(Context context, SIMSlotState simSlotState);
}
