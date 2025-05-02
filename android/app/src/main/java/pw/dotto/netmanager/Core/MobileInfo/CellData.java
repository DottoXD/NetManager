package pw.dotto.netmanager.Core.MobileInfo;

public abstract class CellData {
    protected final String cellIdentifierString;
    protected final String rawSignalString;
    protected final String processedSignalString;
    protected final String channelNumberString;
    protected final String stationIdentityString;
    protected final String areaCodeString;
    protected final String signalQualityString;
    protected final String signalNoiseString;

    private long cellIdentifier;

    private int rawSignal;
    private int processedSignal;
    private int channelNumber;
    private int stationIdentity;
    private int areaCode;
    private int signalQuality;
    private int signalNoise;

    private boolean isRegistered;


    public CellData(
            String cellIdentifierString,
            String rawSignalString,
            String processedSignalString,
            String channelNumberString,
            String stationIdentityString,
            String areaCodeString,
            String signalQualityString,
            String signalNoiseString,
            long cellIdentifier,
            int rawSignal,
            int processedSignal,
            int channelNumber,
            int stationIdentity,
            int areaCode,
            int signalQuality,
            int signalNoise,
            boolean isRegistered
    ) {
        this.cellIdentifierString = cellIdentifierString;
        this.rawSignalString = rawSignalString;
        this.processedSignalString = processedSignalString;
        this.channelNumberString = channelNumberString;
        this.stationIdentityString = stationIdentityString;
        this.areaCodeString = areaCodeString;
        this.signalQualityString = signalQualityString;
        this.signalNoiseString = signalNoiseString;

        this.cellIdentifier = cellIdentifier;
        this.rawSignal = rawSignal;
        this.processedSignal = processedSignal;
        this.channelNumber = channelNumber;
        this.stationIdentity = stationIdentity;
        this.areaCode = areaCode;
        this.signalQuality = signalQuality;
        this.signalNoise = signalNoise;

        this.isRegistered = isRegistered;
    }

    public long getCellIdentifier() {
        return cellIdentifier;
    }

    public int getRawSignal() {
        return rawSignal;
    }

    public int getProcessedSignal() {
        return processedSignal;
    }

    public int getChannelNumber() {
        return channelNumber;
    }

    public int getStationIdentity() {
        return stationIdentity;
    }

    public int getAreaCode() {
        return areaCode;
    }

    public int getSignalQuality() {
        return signalQuality;
    }

    public int getSignalNoise() {
        return signalNoise;
    }

    public boolean isRegistered() {
        return isRegistered;
    }

    public void setCellIdentifier(int cellIdentifier) {
        this.cellIdentifier = cellIdentifier;
    }

    public void setRawSignal(int rawSignal) {
        this.rawSignal = rawSignal;
    }

    public void setProcessedSignal(int processedSignal) {
        this.processedSignal = processedSignal;
    }

    public void setChannelNumber(int channelNumber) {
        this.channelNumber = channelNumber;
    }

    public void setStationIdentity(int stationIdentity) {
        this.stationIdentity = stationIdentity;
    }

    public void setAreaCode(int areaCode) {
        this.areaCode = areaCode;
    }

    public void setSignalQuality(int signalQuality) {
        this.signalQuality = signalQuality;
    }

    public void setSignalNoise(int signalNoise) {
        this.signalNoise = signalNoise;
    }

    public void setIsRegistered(boolean isRegistered) {
        this.isRegistered = isRegistered;
    }
}
