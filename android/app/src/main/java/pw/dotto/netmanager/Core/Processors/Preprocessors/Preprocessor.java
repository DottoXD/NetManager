package pw.dotto.netmanager.Core.Processors.Preprocessors;

import android.telephony.CellInfo;

import java.util.List;

/**
 * NetManager's Preprocessor interface is the template for a cell data
 * preprocessor.
 * A preprocessor is a simple set of instructions that shall be run before the
 * mobile cells are fully processed.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public interface Preprocessor {
    List<CellInfo> process(List<CellInfo> rawCellInfo, int simId);
}
