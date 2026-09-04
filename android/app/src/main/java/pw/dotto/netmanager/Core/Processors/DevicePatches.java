package pw.dotto.netmanager.Core.Processors;

import pw.dotto.netmanager.Core.Processors.Postprocessors.DuplicateCellsPostprocessor;
import pw.dotto.netmanager.Core.Processors.Postprocessors.InvalidDataPostprocessor;
import pw.dotto.netmanager.Core.Processors.Postprocessors.PixelDataPostprocessor;
import pw.dotto.netmanager.Core.Processors.Postprocessors.QualcommActiveCellsPostprocessor;
import pw.dotto.netmanager.Core.Processors.Postprocessors.SamsungNrNsaPostprocessor;

/**
 * NetManager's DevicePatches class is a core component which registers
 * preprocessors and postprocessors to the DevicePatchRegistry.
 *
 * @author DottoXD
 * @version 0.1.6
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
        DevicePatchRegistry.registerPostprocessor("*", "*", DuplicateCellsPostprocessor::new);
        DevicePatchRegistry.registerPostprocessor("*", "*", InvalidDataPostprocessor::new);

        registered = true;
    }
}
