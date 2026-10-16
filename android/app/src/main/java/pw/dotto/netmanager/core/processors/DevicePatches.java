package pw.dotto.netmanager.core.processors;

import pw.dotto.netmanager.core.processors.postprocessors.BandwidthsPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.DuplicateCellsPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.ImpossibleCellsPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.InvalidDataPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.LikelyCellsPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.PixelDataPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.QualcommActiveCellsPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.SamsungNrNsaPostprocessor;
import pw.dotto.netmanager.core.processors.postprocessors.SignalPostprocessor;
import pw.dotto.netmanager.core.processors.preprocessors.ExtraCellsPreprocessor;

/**
 * NetManager's DevicePatches class is a core component which registers
 * preprocessors and postprocessors to the DevicePatchRegistry.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class DevicePatches {
    private static volatile boolean registered = false;

    private DevicePatches() {
    }

    public static synchronized void registerAll() {
        if (registered)
            return;

        DevicePatchRegistry.registerPostprocessor("google", "*", PixelDataPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("samsung", "qcom", SamsungNrNsaPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "qcom", QualcommActiveCellsPostprocessor::new);

        DevicePatchRegistry.registerPostprocessor("*", "*", InvalidDataPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", LikelyCellsPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", ImpossibleCellsPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", BandwidthsPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", SignalPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", DuplicateCellsPostprocessor::new);

        DevicePatchRegistry.registerPreprocessor("*", "*", ExtraCellsPreprocessor::new);

        registered = true;
    }
}
