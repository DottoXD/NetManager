package pw.dotto.netmanager.Core.Processors.Postprocessors;

import static pw.dotto.netmanager.Core.Mobile.Extractors.Cells.LteExtractor.MAXIMUM_LTE_MHZ;
import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Utils.DeviceData;

/**
 * NetManager's LikelyCellsPostprocessor is a cell data postprocessor
 * which flags neighboring cells that are likely to be active cells as likely
 * active cells.
 * This postprocessor is run on all devices, but its implementation is likely to
 * change between OEMs and different modems.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class LikelyCellsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getNeighborCells() == null || data.getActiveCells() == null
                || data.getLikelyCells() == null || data.getNetworkGen() < 4)
            return data;

        DeviceData deviceData = DeviceData.getInstance(null);

        if ((deviceData.getManufacturer().equals("xiaomi") || deviceData.getManufacturer().equals("redmi")
                || deviceData.getManufacturer().equals("poco")) && deviceData.getModem().equals("qcom")) {
            // get bw, with 4g qcom xiaomis return all lte bws
            List<Integer> rawBandwidths = netManagerCore.getCellBandwidths(simId);

            if (rawBandwidths == null || rawBandwidths.size() <= 1) {
                return data;
            }

            List<Integer> targetBandwidths = new ArrayList<>();
            for (Integer bw : rawBandwidths) {
                if (bw == null)
                    continue;

                if (bw <= MAXIMUM_LTE_MHZ) {
                    targetBandwidths.add(bw);
                }
            }

            if (targetBandwidths.size() <= 1) {
                return data;
            }

            Set<Integer> activeEarfcnSet = new HashSet<>();
            for (CellData activeCell : data.getActiveCells()) {
                activeEarfcnSet.add(activeCell.getChannelNumber());

                if (targetBandwidths.contains(activeCell.getBandwidth())) {
                    targetBandwidths.remove(Integer.valueOf(activeCell.getBandwidth()));
                } else if (!targetBandwidths.isEmpty()) {
                    targetBandwidths.remove(0);
                }
            }

            if (targetBandwidths.isEmpty()) {
                return data;
            }

            CellData[] neighborCells = data.getNeighborCells();
            List<CellData> candidates = new ArrayList<>();

            for (CellData neighbor : neighborCells) {
                if (activeEarfcnSet.contains(neighbor.getChannelNumber()) || neighbor.getChannelNumber() <= 0) {
                    continue;
                }

                if (getEffectiveSignal(neighbor) == CELL_INFO_UNAVAILABLE) {
                    continue;
                }

                candidates.add(neighbor);
            }

            for (Integer targetBw : targetBandwidths) {
                CellData bestCandidate = null;
                int bestSignal = Integer.MIN_VALUE;

                for (CellData candidate : candidates) {
                    boolean bwMatches = candidate.getBandwidth() == CELL_INFO_UNAVAILABLE
                            || candidate.getBandwidth() == targetBw;

                    if (bwMatches) {
                        int currentSignal = getEffectiveSignal(candidate);

                        if (currentSignal != CELL_INFO_UNAVAILABLE && currentSignal > bestSignal) {
                            bestSignal = currentSignal;
                            bestCandidate = candidate;
                        }
                    }
                }

                if (bestCandidate != null) {
                    bestCandidate.setBandwidth(targetBw);
                    data.addLikelyCell(bestCandidate);

                    int matchedEarfcn = bestCandidate.getChannelNumber();
                    candidates.removeIf(c -> c.getChannelNumber() == matchedEarfcn);
                    activeEarfcnSet.add(matchedEarfcn);
                }
            }
        }

        return data;
    }

    private int getEffectiveSignal(CellData cell) {
        int processedSignal = cell.getProcessedSignal();

        if (processedSignal != CELL_INFO_UNAVAILABLE && processedSignal < 0) {
            return processedSignal;
        }

        int rawSignal = cell.getRawSignal();
        if (rawSignal != CELL_INFO_UNAVAILABLE && rawSignal < 0) {
            return rawSignal;
        }

        return CELL_INFO_UNAVAILABLE;
    }
}