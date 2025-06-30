package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class NrCellData extends CellData {

    public NrCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "CSI RSRP",
                "SS RSRP",
                "ARFCN",
                "PCI",
                "TAC",
                "RSRQ",
                "SNR",
                "TA (µs)",
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