package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's LteCellData is a core component which is used to store various
 * info about Lte cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
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
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}
