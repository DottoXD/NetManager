package pw.dotto.netmanager.wearos;

/**
 * NetManager's WearConnectionCallback is a tiny, simple interface used for
 * WearOS callbacks.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public interface WearConnectionCallback {
    void onResult(boolean isConnected);
}