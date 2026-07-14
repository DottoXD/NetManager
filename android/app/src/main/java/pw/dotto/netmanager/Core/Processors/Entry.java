package pw.dotto.netmanager.Core.Processors;

import java.util.function.Supplier;

import pw.dotto.netmanager.Utils.DeviceData;

/**
 * NetManager's Entry class is a utility that allows to associate a
 * preprocessing/postprocessing class to a certain device (give its DeviceData
 * info).
 * An Entry is usually added to the DevicePatchRegistry, which keeps a record of
 * the various entries that shall be ran on certain devices.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class Entry {
    private final DeviceData deviceData;
    public final Supplier<?> factory;

    public Entry(String manufacturer, String modem, Supplier<?> factory) {
        this.deviceData = new DeviceData(manufacturer, modem);
        this.factory = factory;
    }

    public boolean matches(DeviceData deviceData) {
        boolean manufacturerMatches = deviceData.getManufacturer().equals("*")
                || this.deviceData.getManufacturer().equalsIgnoreCase(deviceData.getManufacturer());
        boolean modemMatches = deviceData.getModem().equals("*")
                || this.deviceData.getModem().equalsIgnoreCase(deviceData.getModem());

        return manufacturerMatches && modemMatches;
    }
}