package pw.dotto.netmanager.Core.Processors.Postprocessors;

import android.os.Build;
import android.telephony.CellSignalStrength;
import android.telephony.CellSignalStrengthNr;

import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.Extractors.BasicData.DataManager;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's SamsungNrNsaPostprocessor is a cell data postprocessor which
 * adds missing NR NSA cells on Samsung devices running on Snapdragon modems.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class SamsungNrNsaPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (netManagerCore == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || data == null
                || data.getNetworkGen() != 4 || data.getActiveCells() == null)
            return data;

        SIMSlotState simSlotState = netManagerCore.getSlot(simId);

        if (simSlotState == null)
            return data;

        CellSignalStrength[] signalStrengths;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            signalStrengths = simSlotState.signalStrengthsListener.getLatestSignalStrengths();
        } else {
            signalStrengths = simSlotState.legacyPhoneStateListener.getLatestSignalStrengths();
        }

        if (signalStrengths == null)
            return data;

        List<CellSignalStrengthNr> foundNrCells = new ArrayList<>();
        for (CellSignalStrength cellSignalStrength : signalStrengths) {
            if (cellSignalStrength instanceof CellSignalStrengthNr) {
                foundNrCells.add((CellSignalStrengthNr) cellSignalStrength);
            }
        }

        if (foundNrCells.isEmpty())
            return data;

        List<NrCellData> presentNrCells = new ArrayList<>();
        for (CellData cellData : data.getActiveCells()) {
            if (cellData instanceof NrCellData) {
                presentNrCells.add((NrCellData) cellData);
            }
        }

        for (CellSignalStrengthNr foundNrCell : foundNrCells) {
            boolean found = false;

            for (NrCellData nrCellData : presentNrCells) {
                if ((nrCellData.getProcessedSignal() == foundNrCell.getSsRsrp()
                        || nrCellData.getProcessedSignal() == foundNrCell.getCsiRsrp())
                        && (nrCellData.getSignalNoise() == foundNrCell.getSsSinr()
                                || nrCellData.getSignalNoise() == foundNrCell.getCsiSinr())
                        && (nrCellData.getSignalQuality() == foundNrCell.getSsRsrq()
                                || nrCellData.getSignalQuality() == foundNrCell.getCsiRsrq())) {
                    found = true;
                    break;
                }
            }

            if (!found) {
                NrCellData newNrCell = new NrCellData("-1", foundNrCell.getCsiRsrp(), foundNrCell.getSsRsrp(), -1, -1,
                        -1, foundNrCell.getSsRsrq(), foundNrCell.getSsSinr(),
                        (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !foundNrCell.getCsiCqiReport().isEmpty()
                                ? foundNrCell.getCsiCqiReport().get(0)
                                : -1),
                        (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                                ? foundNrCell.getTimingAdvanceMicros()
                                : -1),
                        -1, -1, false);
                newNrCell.setBasicCellData(DataManager.getBasicData(newNrCell, 0));
                data.addActiveCell(newNrCell);
            }
        }

        return data;
    }
}
