package pw.dotto.netmanager.Core.Processors;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;

import pw.dotto.netmanager.Core.Processors.Postprocessors.Postprocessor;
import pw.dotto.netmanager.Core.Processors.Preprocessors.Preprocessor;
import pw.dotto.netmanager.Utils.DeviceData;

/**
 * NetManager's DevicePatchRegistry class is a core component which allows to
 * keep track of all preprocessing/postprocessing entries for a certain device.
 * This is especially useful to apply certain fixes to SIMData (postprocessing)
 * objects or cell lists (preprocessing) only on certain devices.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public final class DevicePatchRegistry {
    private static final List<Entry> PREPROCESSOR_ENTRIES = new ArrayList<>();
    private static final List<Entry> POSTPROCESSOR_ENTRIES = new ArrayList<>();

    private DevicePatchRegistry() {
    }

    public static void registerPreprocessor(String manufacturer, String modem, Supplier<Preprocessor> factory) {
        PREPROCESSOR_ENTRIES.add(new Entry(manufacturer, modem, factory));
    }

    public static void registerPostprocessor(String manufacturer, String modem, Supplier<Postprocessor> factory) {
        POSTPROCESSOR_ENTRIES.add(new Entry(manufacturer, modem, factory));
    }

    public static List<Preprocessor> preprocessorsFor(DeviceData deviceData) {
        List<Preprocessor> result = new ArrayList<>();
        for (Entry entry : PREPROCESSOR_ENTRIES) {
            if (entry.matches(deviceData))
                result.add((Preprocessor) entry.factory.get());
        }
        return result;
    }

    public static List<Postprocessor> postprocessorsFor(DeviceData deviceData) {
        List<Postprocessor> result = new ArrayList<>();
        for (Entry entry : POSTPROCESSOR_ENTRIES) {
            if (entry.matches(deviceData))
                result.add((Postprocessor) entry.factory.get());
        }
        return result;
    }
}