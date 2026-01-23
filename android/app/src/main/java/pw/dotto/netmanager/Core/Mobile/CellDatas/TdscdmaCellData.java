package pw.dotto.netmanager.Core.Mobile.CellDatas;

/**
 * NetManager's TdscdmaCellData is a core component which is used to store
 * various info about Tdscdma cells.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class TdscdmaCellData extends CellData {

    public TdscdmaCellData(String cellIdentifier, int rawSignal, int processedSignal, int channelNumber,
            int stationIdentity, int areaCode, int signalQuality, int signalNoise, int timingAdvance, int bandwidth,
            int band, boolean isRegistered) {
        super(
                "Cell ID",
                "NodeB",
                "-",
                "RSCP",
                "UARFCN",
                "CPID",
                "LAC",
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
                timingAdvance,
                bandwidth,
                band,
                isRegistered);
    }
}
