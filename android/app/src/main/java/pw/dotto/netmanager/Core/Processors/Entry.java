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
 * @version 0.1.2
 */
public class Entry {
    private final DeviceData targetData;
    public final Supplier<?> factory;

    public Entry(String manufacturer, String modem, Supplier<?> factory) {
        this.targetData = new DeviceData(manufacturer, modem);
        this.factory = factory;
    }

    public boolean matches(DeviceData deviceData) {
        boolean manufacturerMatches = this.targetData.getManufacturer().trim().equals("*")
                || this.targetData.getManufacturer().trim().equalsIgnoreCase(deviceData.getManufacturer().trim());
        boolean modemMatches = this.targetData.getModem().trim().equals("*")
                || this.targetData.getModem().trim().equalsIgnoreCase(deviceData.getModem().trim());

        return manufacturerMatches && modemMatches;
    }
}