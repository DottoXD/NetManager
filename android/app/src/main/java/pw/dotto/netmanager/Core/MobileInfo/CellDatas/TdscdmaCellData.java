package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

public class TdscdmaCellData extends CellData {

    public TdscdmaCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
                           int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
                           int band, boolean isRegistered) {
        super(
                "Cell ID",
                "-",
                "RSCP",
                "UARFCN",
                "PSC",
                "LAC",
                "-",
                "-",
                "-",
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
