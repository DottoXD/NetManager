package pw.dotto.netmanager.Core.Sources.Telephony;

import android.telephony.CellInfo;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * NetManager's CellInfoCache class is a simple caching system built to save
 * freshly fetched cells from Telephony.
 * This component is especially useful on devices that keep neighboring/less
 * important cells for very short amounts of time.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class CellInfoCache {
    private static final long DEFAULT_CACHE_MAX_AGE_MS = 5000;
    private final Map<Integer, CachedCellInfo> requestedCellCache = new ConcurrentHashMap<>();

    public void put(int simId, List<CellInfo> cells) {
        if (cells != null && !cells.isEmpty()) {
            requestedCellCache.put(simId, new CachedCellInfo(cells));
        }
    }

    public List<CellInfo> getValidCells(int simId) {
        return getValidCells(simId, DEFAULT_CACHE_MAX_AGE_MS);
    }

    public List<CellInfo> getValidCells(int simId, long maxAgeMs) {
        CachedCellInfo cached = requestedCellCache.get(simId);

        if (cached == null) {
            return Collections.emptyList();
        }

        if (cached.isExpired(maxAgeMs)) {
            requestedCellCache.remove(simId);
            return Collections.emptyList();
        }

        return cached.getCells();
    }

    public void invalidate(int simId) {
        requestedCellCache.remove(simId);
    }

    public void clear() {
        requestedCellCache.clear();
    }
}