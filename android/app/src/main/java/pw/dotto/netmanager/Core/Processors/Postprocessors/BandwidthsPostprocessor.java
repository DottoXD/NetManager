package pw.dotto.netmanager.Core.Processors.Postprocessors;

import static pw.dotto.netmanager.Core.Mobile.Extractors.Cells.NrExtractor.getMaximumNrMhz;
import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's BandwidthsPostprocessor is a cell data postprocessor
 * which assigns bandwidth data to LTE and NR cells which, for whatever reason,
 * don't have any.
 * This postprocessor tries its best at assigning bandwidth data to the correct
 * cells, but it might sometimes make mistakes.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class BandwidthsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null)
            return data;

        CellData[] activeCells = data.getActiveCells();
        if (activeCells == null || activeCells.length == 0)
            return data;

        Arrays.sort(activeCells, (a, b) -> {
            if (a == null && b == null)
                return 0;
            if (a == null)
                return 1;
            if (b == null)
                return -1;

            boolean invalidA = a.getBandwidth() <= 0 || a.getBandwidth() == CELL_INFO_UNAVAILABLE;
            boolean invalidB = b.getBandwidth() <= 0 || b.getBandwidth() == CELL_INFO_UNAVAILABLE;

            if (invalidA != invalidB)
                return Boolean.compare(invalidA, invalidB);

            if (invalidA) {
                boolean isNrA = a instanceof NrCellData;
                boolean isNrB = b instanceof NrCellData;
                if (isNrA != isNrB)
                    return Boolean.compare(isNrA, isNrB);

                int freqA = (a.getBasicCellData() != null) ? a.getBasicCellData().getFrequency() : -1;
                int freqB = (b.getBasicCellData() != null) ? b.getBasicCellData().getFrequency() : -1;

                return Integer.compare(freqB, freqA);
            }

            return 0;
        });

        data.setActiveCells(activeCells);

        List<Integer> cellBandwidths = netManagerCore.getCellBandwidths(simId);
        List<Integer> availableBandwidths = new ArrayList<>(cellBandwidths);

        for (CellData cell : activeCells) {
            if (cell == null)
                continue;

            int bw = cell.getBandwidth();
            if (bw > 0 && bw != CELL_INFO_UNAVAILABLE)
                availableBandwidths.remove(Integer.valueOf(bw));
        }

        availableBandwidths.sort(Collections.reverseOrder());

        for (CellData cell : data.getActiveCells()) {
            if (cell == null)
                continue;

            int bw = cell.getBandwidth();
            if (bw > 0 && bw != CELL_INFO_UNAVAILABLE)
                continue;

            if (cell instanceof NrCellData) {
                int freq = (cell.getBasicCellData() != null) ? cell.getBasicCellData().getFrequency() : -1;
                int maxBw = getMaximumNrMhz(freq);
                Optional<Integer> possibleBw = availableBandwidths.stream().filter(b -> b <= maxBw).findFirst();
                if (possibleBw.isPresent()) {
                    int nrBw = possibleBw.get();
                    cell.setBandwidth(nrBw);
                    availableBandwidths.remove(Integer.valueOf(nrBw));
                }
            } else if (cell instanceof LteCellData) {
                Optional<Integer> possibleBw = availableBandwidths.stream().filter(b -> b <= 20).findFirst();
                if (possibleBw.isPresent()) {
                    int lteBw = possibleBw.get();
                    cell.setBandwidth(lteBw);
                    availableBandwidths.remove(Integer.valueOf(lteBw));
                }
            }
        }

        return data;
    }
}