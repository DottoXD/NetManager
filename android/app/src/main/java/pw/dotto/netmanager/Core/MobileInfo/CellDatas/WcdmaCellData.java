package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

import pw.dotto.netmanager.Core.MobileInfo.CellData;

public class WcdmaCellData extends CellData {

    public WcdmaCellData(String cellIdentifier, String rawSignal, String processedSignal, int channelNumber, int stationIdentity, String areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth, int band, boolean isRegistered) {
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
                isRegistered
        );
    }
}
