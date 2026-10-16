package pw.dotto.netmanager.core.processors.preprocessors;

import android.telephony.CellInfo;

import java.util.List;

import pw.dotto.netmanager.core.NetManagerCore;

/**
 * NetManager's Preprocessor interface is the template for a cell data
 * preprocessor.
 * A preprocessor is a simple set of instructions that shall be run before the
 * mobile cells are fully processed.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public interface Preprocessor {
    List<CellInfo> process(List<CellInfo> rawCellInfo, int simId, NetManagerCore netManagerCore);
}
