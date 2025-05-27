package pw.dotto.netmanager.Core.MobileInfo.CellDatas;

import pw.dotto.netmanager.Core.MobileInfo.CellData;

public class NrCellData extends CellData {

    public NrCellData(String cellIdentifier, String rawSignal, String processedSignal, int channelNumber, int stationIdentity, String areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth, int band, boolean isRegistered) {
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