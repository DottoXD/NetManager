package pw.dotto.netmanager.Core.Mobile;

/**
 * NetManager's CellSnapshot is a component which is supposed to contain
 * subscription, network and main cell info of a SIM card.
 * This is used for NetManager's WearOS bridge.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class CellSnapshot {
    private final String network;
    private final String node;
    private final int band;
    private final int networkGen;
    private final int rawSignal;
    private final int processedSignal;
    private final long timestamp;

    public CellSnapshot(String network, String node, int band, int networkGen, int rawSignal, int processedSignal) {
        this.network = network;
        this.node = node;
        this.band = band;
        this.networkGen = networkGen;
        this.rawSignal = rawSignal;
        this.processedSignal = processedSignal;
        this.timestamp = System.currentTimeMillis();
    }

    public String getNetwork() {
        return network;
    }

    public String getNode() {
        return node;
    }

    public int getBand() {
        return band;
    }

    public int getNetworkGen() {
        return networkGen;
    }

    public int getRawSignal() {
        return rawSignal;
    }

    public int getProcessedSignal() {
        return processedSignal;
    }

    public long getTimestamp() {
        return timestamp;
    }
}
