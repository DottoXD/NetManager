package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

import pw.dotto.netmanager.Core.MobileInfo.CellData;

public class LteCellData extends CellData {

    public LteCellData(long cellIdentifier, int rawSignal, int processedSignal, int channelNumber, int stationIdentity, int areaCode, int signalQuality, int signalNoise, boolean isRegistered) {
        super(
                "Cell ID",
                "RSSI",
                "RSRP",
                "ARFCN",
                "PCI",
                "TAC",
                "RSRQ",
                "SNR",
                cellIdentifier,
                rawSignal,
                processedSignal,
                channelNumber,
                stationIdentity,
                areaCode,
                signalQuality,
                signalNoise,
                isRegistered
        );
    }
}
