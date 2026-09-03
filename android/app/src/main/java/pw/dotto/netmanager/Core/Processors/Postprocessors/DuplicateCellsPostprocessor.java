package pw.dotto.netmanager.Core.Processors.Postprocessors;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;

/**
 * NetManager's DuplicateCellsPostprocessor is a cell data postprocessor
 * which removes duplicate active cells & neighbor cells.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class DuplicateCellsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getNeighborCells() == null || data.getActiveCells() == null)
            return data;

        Set<String> seenIdentifiers = new HashSet<>();
        Set<Integer> seenChannelNumbers = new HashSet<>();
        List<CellData> activeDuplicates = new ArrayList<>();
        List<CellData> neighborDuplicates = new java.util.ArrayList<>();

        for (CellData cell : data.getActiveCells()) {
            if (cell == null)
                continue;

            boolean isDuplicate = false;

            String id = cell.getCellIdentifier();
            if (isValidIdentifier(id)) {
                if (!seenIdentifiers.add(id)) {
                    isDuplicate = true;
                }
            }

            int channelNumber = cell.getChannelNumber();
            if (!isDuplicate && isValidChannelNumber(channelNumber)) {
                if (!seenChannelNumbers.add(channelNumber)) {
                    isDuplicate = true;
                }
            }

            if (isDuplicate) {
                activeDuplicates.add(cell);
            }
        }

        for (CellData cell : data.getNeighborCells()) {
            if (cell == null)
                continue;

            boolean isDuplicate = false;

            String id = cell.getCellIdentifier();
            if (isValidIdentifier(id)) {
                if (!seenIdentifiers.add(id)) {
                    isDuplicate = true;
                }
            }

            if (isDuplicate) {
                neighborDuplicates.add(cell);
            }
        }

        for (CellData cell : activeDuplicates)
            data.removeActiveCell(cell);
        for (CellData cell : neighborDuplicates)
            data.removeNeighborCell(cell);

        return data;
    }

    private boolean isValidIdentifier(String id) {
        return id != null && !id.equals(String.valueOf(CELL_INFO_UNAVAILABLE)) && !id.equals("0")
                && !id.equals("-1");
    }

    private boolean isValidChannelNumber(int channelNumber) {
        return channelNumber != CELL_INFO_UNAVAILABLE && channelNumber > 0;
    }
}