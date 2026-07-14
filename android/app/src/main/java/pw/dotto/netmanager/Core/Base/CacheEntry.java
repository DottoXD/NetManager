package pw.dotto.netmanager.Core.Base;

import pw.dotto.netmanager.Core.Mobile.SIMData;

/**
 * NetManager's CacheEntry is a component which contains a cached SIMData object
 * and its timestamp.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class CacheEntry {
    public final SIMData data;
    public final long timestampMillis;

    public CacheEntry(SIMData data, long timestampMillis) {
        this.data = data;
        this.timestampMillis = timestampMillis;
    }
}