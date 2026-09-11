package pw.dotto.netmanager.Core.Processors.Postprocessors;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.content.Context;
import android.os.Build;
import android.telephony.CellSignalStrength;
import android.telephony.CellSignalStrengthNr;
import android.telephony.TelephonyManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;
import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's SignalPostprocessor is a cell data postprocessor
 * which tries to assign signal data (if available) to cells that are missing
 * any piece of signal information.
 * This postprocessor tries its best at assigning signal data to the correct
 * cells, but it might sometimes make mistakes.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class SignalPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getPrimaryCell() == null
                || !(data.getPrimaryCell() instanceof LteCellData || data.getPrimaryCell() instanceof NrCellData))
            return data;

        SIMSlotState simSlotState = netManagerCore.getSlot(simId);
        if (simSlotState == null || simSlotState.telephony == null)
            return data;

        List<NrCellData> nrCells = new ArrayList<>();
        for (CellData cellData : data.getActiveCells()) {
            if (cellData instanceof NrCellData nrCellData) {
                if (nrCellData.getProcessedSignal() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getRawSignal() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getSignalNoise() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getSignalQuality() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getChannelQuality() == CELL_INFO_UNAVAILABLE) {
                    nrCells.add(nrCellData);
                }
            }
        }

        DebugLogger.add("NR cells for signal strength fixes for SIM " + simSlotState.simId + ": " + nrCells);

        if (nrCells.isEmpty())
            return data;

        nrCells.sort((a, b) -> {
            int freqA = (a != null && a.getBasicCellData() != null) ? a.getBasicCellData().getFrequency() : -1;
            int freqB = (b != null && b.getBasicCellData() != null) ? b.getBasicCellData().getFrequency() : -1;
            return Integer.compare(freqB, freqA);
        });

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
            return data;

        Context context = netManagerCore.getAppContext();
        TelephonyManager telephony = simSlotState.telephony;
        CellSignalStrength[] rawSignalStrengths = TelephonyCellDataSource.getSignalStrengths(context, simSlotState,
                telephony);
        DebugLogger
                .add("Raw signal strengths for SIM " + simSlotState.simId + ": " + Arrays.toString(rawSignalStrengths));

        if (rawSignalStrengths == null)
            return data;

        List<CellSignalStrengthNr> signalStrengths = new ArrayList<>();
        for (CellSignalStrength cellSignalStrength : rawSignalStrengths) {
            if (cellSignalStrength instanceof CellSignalStrengthNr) {
                signalStrengths.add((CellSignalStrengthNr) cellSignalStrength);
            }
        }

        if (signalStrengths.isEmpty())
            return data;

        signalStrengths.sort(Comparator.comparingInt(CellSignalStrengthNr::getSsRsrp));

        int limit = Math.min(nrCells.size(), signalStrengths.size());
        for (int i = 0; i < limit; i++) {
            NrCellData nrCell = nrCells.get(i);
            CellSignalStrengthNr ssNr = signalStrengths.get(i);

            if (nrCell == null || ssNr == null)
                continue;

            if (nrCell.getProcessedSignal() == CELL_INFO_UNAVAILABLE && ssNr.getSsRsrp() != CELL_INFO_UNAVAILABLE)
                nrCell.setProcessedSignal(ssNr.getSsRsrp());

            if (nrCell.getRawSignal() == CELL_INFO_UNAVAILABLE && ssNr.getCsiRsrp() != CELL_INFO_UNAVAILABLE)
                nrCell.setRawSignal(ssNr.getCsiRsrp());

            if (nrCell.getSignalNoise() == CELL_INFO_UNAVAILABLE) {
                if (ssNr.getSsSinr() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalNoise(ssNr.getSsSinr());
                } else if (ssNr.getCsiSinr() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalNoise(ssNr.getCsiSinr());
                    nrCell.setSignalNoiseString("CSI SINR");
                }
            }

            if (nrCell.getSignalQuality() == CELL_INFO_UNAVAILABLE) {
                if (ssNr.getSsRsrq() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalQuality(ssNr.getSsRsrq());
                } else if (ssNr.getCsiRsrq() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalQuality(ssNr.getCsiRsrq());
                    nrCell.setSignalQualityString("CSI RSRQ");
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && nrCell.getChannelQuality() == CELL_INFO_UNAVAILABLE) {
                List<Integer> cqiReport = ssNr.getCsiCqiReport();
                if (cqiReport != null && !cqiReport.isEmpty()) {
                    nrCell.setChannelQuality(cqiReport.get(0));
                }
            }

            if (nrCell.getTimingAdvance() == CELL_INFO_UNAVAILABLE) {
                nrCell.setTimingAdvance(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        ? ssNr.getTimingAdvanceMicros()
                        : CELL_INFO_UNAVAILABLE);
            }
        }

        return data;
    }
}