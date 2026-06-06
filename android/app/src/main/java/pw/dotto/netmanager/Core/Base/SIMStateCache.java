package pw.dotto.netmanager.Core.Base;

import java.util.concurrent.ConcurrentHashMap;

import pw.dotto.netmanager.Core.Mobile.SIMData;

public class SIMStateCache {
    private final ConcurrentHashMap<Integer, SIMData> simDataCache = new ConcurrentHashMap<>();

    public void updateSimData(int simId, SIMData data) {
        simDataCache.put(simId, data);
    }

    public SIMData getSimData(int simId) {
        return simDataCache.get(simId);
    }
}
