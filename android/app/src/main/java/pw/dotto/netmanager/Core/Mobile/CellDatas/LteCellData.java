package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's LteCellData is a core component which is used to store various
 * info about Lte cells.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class LteCellData extends CellData {

    public LteCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int channelQuality,
            int timingAdvance, int bandwidth,
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
                "CQI",
                "TA",
                "Total BW",
                "Band",
                cellIdentifier,
                rawSignal,
                processedSignal,
                channelNumber,
                stationIdentity,
                areaCode,
                signalQuality,
                signalNoise,
                channelQuality,
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}
