package pw.dotto.netmanager.Core.Mobile;

/**
 * NetManager's CellSnapshot is a component which is supposed to contain
 * subscription, network and main cell info of a SIM card.
 * This is used for NetManager's WearOS bridge.
 *
 * @author DottoXD
 * @version 0.0.5
 */
public class CellSnapshot {
    private final String network;
    private final String node;
    private final int band;
    private final int networkGen;
    private final int rawSignal;
    private final String rawSignalString;
    private final int processedSignal;
    private final String processedSignalString;
    private final int channelNumber;
    private final String channelNumberString;
    private final int stationIdentity;
    private final String stationIdentityString;
    private final int areaCode;
    private final String areaCodeString;
    private final int signalQuality;
    private final String signalQualityString;
    private final int signalNoise;
    private final String signalNoiseString;
    private final int timingAdvance;
    private final String timingAdvanceString;
    private final long timestamp;

    public CellSnapshot(String network, String node, int band, int networkGen, int rawSignal, String rawSignalString,
            int processedSignal, String processedSignalString, int channelNumber, String channelNumberString,
            int stationIdentity, String stationIdentityString, int areaCode, String areaCodeString, int signalQuality,
            String signalQualityString, int signalNoise, String signalNoiseString, int timingAdvance,
            String timingAdvanceString) {
        this.network = network;
        this.node = node;
        this.band = band;
        this.networkGen = networkGen;
        this.rawSignal = rawSignal;
        this.rawSignalString = rawSignalString;
        this.processedSignal = processedSignal;
        this.processedSignalString = processedSignalString;
        this.channelNumber = channelNumber;
        this.channelNumberString = channelNumberString;
        this.stationIdentity = stationIdentity;
        this.stationIdentityString = stationIdentityString;
        this.areaCode = areaCode;
        this.areaCodeString = areaCodeString;
        this.signalQuality = signalQuality;
        this.signalQualityString = signalQualityString;
        this.signalNoise = signalNoise;
        this.signalNoiseString = signalNoiseString;
        this.timingAdvance = timingAdvance;
        this.timingAdvanceString = timingAdvanceString;
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

    public String getRawSignalString() {
        return rawSignalString;
    }

    public int getProcessedSignal() {
        return processedSignal;
    }

    public String getProcessedSignalString() {
        return processedSignalString;
    }

    public int getChannelNumber() {
        return channelNumber;
    }

    public String getChannelNumberString() {
        return channelNumberString;
    }

    public int getStationIdentity() {
        return stationIdentity;
    }

    public String getStationIdentityString() {
        return stationIdentityString;
    }

    public int getAreaCode() {
        return areaCode;
    }

    public String getAreaCodeString() {
        return areaCodeString;
    }

    public int getSignalQuality() {
        return signalQuality;
    }

    public String getSignalQualityString() {
        return signalQualityString;
    }

    public int getSignalNoise() {
        return signalNoise;
    }

    public String getSignalNoiseString() {
        return signalNoiseString;
    }

    public int getTimingAdvance() {
        return timingAdvance;
    }

    public String getTimingAdvanceString() {
        return timingAdvanceString;
    }

    public long getTimestamp() {
        return timestamp;
    }
}
