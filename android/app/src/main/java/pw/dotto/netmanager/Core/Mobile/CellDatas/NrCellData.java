package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's NrCellData is a core component which is used to store various
 * info about Nr cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class NrCellData extends CellData {

    public NrCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
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
                "SS SNR",
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
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}