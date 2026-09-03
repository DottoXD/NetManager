package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's WcdmaCellData is a core component which is used to store various
 * info about Wcdma cells.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class WcdmaCellData extends CellData {

    public WcdmaCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int channelQuality,
            int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "NodeB",
                "EcNo",
                "RSCP",
                "UARFCN",
                "PSC",
                "LAC",
                "-",
                "-",
                "-",
                "-",
                "-",
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
