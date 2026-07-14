package pw.dotto.netmanager.Core.Base;

import java.util.concurrent.ConcurrentHashMap;

import pw.dotto.netmanager.Core.Mobile.SIMData;

/**
 * NetManager's SIMStateCache is a core component maps the various SIM slots to
 * their respective cache data.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class SIMStateCache {
    private final ConcurrentHashMap<Integer, CacheEntry> simDataCache = new ConcurrentHashMap<>();

    public void updateSimData(int simId, SIMData data) {
        simDataCache.put(simId, new CacheEntry(data, System.currentTimeMillis()));
    }

    public SIMData getSimData(int simId) {
        CacheEntry entry = simDataCache.get(simId);
        return entry == null ? null : entry.data;
    }

    public CacheEntry getCacheEntry(int simId) {
        return simDataCache.get(simId);
    }

    public long getAgeMillis(int simId) {
        CacheEntry entry = simDataCache.get(simId);
        return entry == null ? -1 : System.currentTimeMillis() - entry.timestampMillis;
    }

    public void clear(int simId) {
        simDataCache.remove(simId);
    }

    public void clearAll() {
        simDataCache.clear();
    }
}