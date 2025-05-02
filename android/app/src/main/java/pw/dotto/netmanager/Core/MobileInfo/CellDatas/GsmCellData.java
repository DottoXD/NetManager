package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

import pw.dotto.netmanager.Core.MobileInfo.CellData;

public class GsmCellData extends CellData {

    public GsmCellData(long cellIdentifier, int rawSignal, int processedSignal, int channelNumber, int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth, int band, boolean isRegistered) {
        super(
                "Cell ID",
                "-",
                "RSCP",
                "UARFCN",
                "PSC",
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
                isRegistered
        );
    }
}
