package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class GsmCellData extends CellData {

    public GsmCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "RSSI",
                "RXL",
                "UARFCN",
                "BSIC",
                "LAC",
                "-",
                "-",
                "TA",
                "-",
                "-",
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
