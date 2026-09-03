package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's CdmaCellData is a core component which is used to store various
 * info about Cdma cells.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class CdmaCellData extends CellData {

    public CdmaCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int channelQuality,
            int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "BTS",
                "RSSI",
                "EC/IO",
                "-",
                "PN",
                "LAC",
                "-",
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
                channelQuality,
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}
