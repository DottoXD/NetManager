package pw.dotto.netmanager.core.processors.postprocessors;

import pw.dotto.netmanager.core.mobile.SIMData;
import pw.dotto.netmanager.core.NetManagerCore;

/**
 * NetManager's Postprocessor interface is the template for a cell data
 * postprocessor.
 * A postprocessor is a simple set of instructions that shall be run after the
 * mobile cells are fully processed.
 *
 * @author DottoXD
 * @version 0.1.2
 */
public interface Postprocessor {
    SIMData process(SIMData data, int simId, NetManagerCore netManagerCore);
}
