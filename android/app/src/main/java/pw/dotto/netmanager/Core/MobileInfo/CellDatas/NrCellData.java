package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class NrCellData extends CellData {

    public NrCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "RSSI",
                "RSRP",
                "ARFCN",
                "PCI",
                "TAC",
                "RSRQ",
                "SNR",
                "TA Microseconds",
                "-",
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