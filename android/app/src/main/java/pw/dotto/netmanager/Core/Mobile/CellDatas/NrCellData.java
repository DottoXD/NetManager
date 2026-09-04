package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's NrCellData is a core component which is used to store various
 * info about Nr cells.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class NrCellData extends CellData {

    public NrCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int channelQuality,
            int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "gNodeB",
                "CSI RSRP",
                "SS RSRP",
                "NR-ARFCN",
                "PCI",
                "TAC",
                "SS RSRQ",
                "SS SINR",
                "CSI CQI",
                "TA (µs)",
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