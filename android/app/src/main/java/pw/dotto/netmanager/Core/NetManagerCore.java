package pw.dotto.netmanager.Core;

import android.content.Context;

import pw.dotto.netmanager.Core.Base.SIMStateCache;
import pw.dotto.netmanager.Core.Mobile.SIMData;

public class NetManagerCore {
    private static NetManagerCore instance;
    private final Context appContext;

    private final SIMStateCache simStateCache;

    private NetManagerCore(Context context) {
        this.appContext = context.getApplicationContext();

        this.simStateCache = new SIMStateCache();
    }

    public static synchronized NetManagerCore getInstance(Context context) {
        if(instance == null) {
            instance = new NetManagerCore(context);
        }

        return instance;
    }

    public SIMData getCachedSIMData(int simId) {
        return simStateCache.getSimData(simId);
    }
}
