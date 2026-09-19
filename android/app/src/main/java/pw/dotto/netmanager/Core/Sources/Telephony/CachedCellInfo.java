package pw.dotto.netmanager.Core.Sources.Telephony;

import android.telephony.CellInfo;

import java.util.Collections;
import java.util.List;

/**
 * NetManager's CachedCellInfo class is a simple component used to store a list
 * of cached cells at a certain timestamp.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class CachedCellInfo {
    private final List<CellInfo> cells;
    private final long timestamp;

    public CachedCellInfo(List<CellInfo> cells) {
        this.cells = cells != null ? Collections.unmodifiableList(cells) : Collections.emptyList();
        this.timestamp = System.currentTimeMillis();
    }

    public List<CellInfo> getCells() {
        return cells;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public boolean isExpired(long maxAgeMs) {
        return (System.currentTimeMillis() - timestamp) > maxAgeMs;
    }
}