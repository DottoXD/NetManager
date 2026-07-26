package pw.dotto.netmanager.Core.Processors;

import pw.dotto.netmanager.Core.Processors.Postprocessors.PixelTAPostprocessor;

/**
 * NetManager's DevicePatches class is a core component which registers
 * preprocessors and postprocessors to the DevicePatchRegistry.
 *
 * @author DottoXD
 * @version 0.1.2
 */
public class DevicePatches {
    private static volatile boolean registered = false;

    private DevicePatches() {
    }

    public static synchronized void registerAll() {
        if (registered)
            return;

        DevicePatchRegistry.registerPostprocessor("google", "*", PixelTAPostprocessor::new);

        registered = true;
    }
}
