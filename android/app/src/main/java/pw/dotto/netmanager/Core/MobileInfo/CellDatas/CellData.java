package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

import androidx.annotation.NonNull;

public abstract class CellData {
    protected final String cellIdentifierString;
    protected final String rawSignalString;
    protected final String processedSignalString;
    protected final String channelNumberString;
    protected final String stationIdentityString;
    protected final String areaCodeString;
    protected final String signalQualityString;
    protected final String signalNoiseString;
    protected final String timingAdvanceString;
    protected final String bandwidthString;
    protected final String bandString;

    private String cellIdentifier;

    private int rawSignal;
    private int processedSignal;
    private int channelNumber;
    private int stationIdentity;
    private int areaCode;
    private int signalQuality;
    private int signalNoise;
    private int timingAdvance;
    private int bandwidth;
    private int band;
    private BasicCellData basicCellData;

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
            String timingAdvanceString,
            String bandwidthString,
            String bandString,
            String cellIdentifier,
            int rawSignal,
            int processedSignal,
            int channelNumber,
            int stationIdentity,
            int areaCode,
            int signalQuality,
            int signalNoise,
            int timingAdvance,
            int bandwidth,
            int band,
            boolean isRegistered) {
        this.cellIdentifierString = cellIdentifierString;
        this.rawSignalString = rawSignalString;
        this.processedSignalString = processedSignalString;
        this.channelNumberString = channelNumberString;
        this.stationIdentityString = stationIdentityString;
        this.areaCodeString = areaCodeString;
        this.signalQualityString = signalQualityString;
        this.signalNoiseString = signalNoiseString;
        this.timingAdvanceString = timingAdvanceString;
        this.bandwidthString = bandwidthString;
        this.bandString = bandString;

        this.cellIdentifier = cellIdentifier;
        this.rawSignal = rawSignal;
        this.processedSignal = processedSignal;
        this.channelNumber = channelNumber;
        this.stationIdentity = stationIdentity;
        this.areaCode = areaCode;
        this.signalQuality = signalQuality;
        this.signalNoise = signalNoise;
        this.timingAdvance = timingAdvance;
        this.bandwidth = bandwidth;
        this.band = band;

        this.isRegistered = isRegistered;
    }

    public String getCellIdentifier() {
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

    public int getTimingAdvance() {
        return timingAdvance;
    }

    public int getBandwidth() {
        return bandwidth;
    }

    public int getBand() {
        return band;
    }

    public String getAreaCodeString() {
        return areaCodeString;
    }

    public String getBandString() {
        return bandString;
    }

    public String getBandwidthString() {
        return bandwidthString;
    }

    public String getCellIdentifierString() {
        return cellIdentifierString;
    }

    public String getChannelNumberString() {
        return channelNumberString;
    }

    public String getProcessedSignalString() {
        return processedSignalString;
    }

    public String getRawSignalString() {
        return rawSignalString;
    }

    public String getSignalNoiseString() {
        return signalNoiseString;
    }

    public String getSignalQualityString() {
        return signalQualityString;
    }

    public String getStationIdentityString() {
        return stationIdentityString;
    }

    public String getTimingAdvanceString() {
        return timingAdvanceString;
    }

    public BasicCellData getBasicCellData() {
        return basicCellData;
    }

    public boolean isRegistered() {
        return isRegistered;
    }

    public void setCellIdentifier(String cellIdentifier) {
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

    public void setTimingAdvance(int timingAdvance) {
        this.timingAdvance = timingAdvance;
    }

    public void setBandwidth(int bandwidth) {
        this.bandwidth = bandwidth;
    }

    public void setBand(int band) {
        this.band = band;
    }

    public void setBasicCellData(BasicCellData basicCellData) {
        this.basicCellData = basicCellData;
    }

    public void setIsRegistered(boolean isRegistered) {
        this.isRegistered = isRegistered;
    }

    @NonNull
    public String toString() {
        return cellIdentifierString + ": " + cellIdentifier + ", " + rawSignalString + ": " + rawSignal + ", " + processedSignalString + ": " + processedSignal + ", " + channelNumberString + ": " + channelNumber + ", " + stationIdentityString + ": " + stationIdentity + ", " + areaCodeString + ": " + areaCode + ", " + signalQualityString + ": " + signalQuality + ", " + signalNoiseString + ": " + signalNoise + ", " + timingAdvanceString + ": " + timingAdvance + ", " + bandwidthString + ": " + bandwidth + ", " + bandString + ": " + band;
    }
}
