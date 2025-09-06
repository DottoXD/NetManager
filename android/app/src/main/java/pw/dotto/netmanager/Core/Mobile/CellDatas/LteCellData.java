package pw.dotto.netmanager.Core.Mobile.CellDatas;

public class LteCellData extends CellData {

    public LteCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "eNodeB",
                "RSSI",
                "RSRP",
                "EARFCN",
                "PCI",
                "TAC",
                "RSRQ",
                "SNR",
                "TA",
                "Bandwidth",
                "Band",
                cellIdentifier,
                rawSignal,
                processedSignal,
                channelNumber,
                stationIdentity,
                areaCode,
                signalQuality,
                signalNoise,
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}
