package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's GsmCellData is a core component which is used to store various
 * info about Gsm cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class GsmCellData extends CellData {

    public GsmCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "BTS",
                "RSSI",
                "RXL",
                "ARFCN",
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
