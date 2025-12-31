package pw.dotto.netmanager.Core.Mobile;

public class CellSnapshot {
    private final String network;
    private final String node;
    private final String band;
    private final int rawSignal;
    private final int processedSignal;
    private final long timestamp;

    public CellSnapshot(String network, String node, String band, int rawSignal, int processedSignal) {
        this.network = network;
        this.node = node;
        this.band = band;
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

    public String getBand() {
        return band;
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
