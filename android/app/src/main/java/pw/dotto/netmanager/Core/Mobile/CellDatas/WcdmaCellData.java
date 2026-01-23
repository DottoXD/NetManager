package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's WcdmaCellData is a core component which is used to store various
 * info about Wcdma cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class WcdmaCellData extends CellData {

    public WcdmaCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
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
