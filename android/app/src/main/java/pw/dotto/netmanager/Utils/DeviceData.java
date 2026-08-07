package pw.dotto.netmanager.Utils;

import android.content.SharedPreferences;
import android.os.Build;

import com.google.gson.Gson;

/**
 * NetManager's DeviceData is a component that stores the device's manufacturer
 * and modem data.
 * This is useful to filter vendor-specific features.
 *
 * @author DottoXD
 * @version 0.1.3
 */
public class DeviceData {
    private static DeviceData instance;

    private final String manufacturer;
    private final String modem;
    private final String model;

    public DeviceData(String manufacturer, String modem, String model) {
        this.manufacturer = manufacturer.toLowerCase();
        this.modem = modem.toLowerCase();
        this.model = model;
    }

    public static synchronized DeviceData getInstance(SharedPreferences prefs) {
        if (instance == null) {
            instance = new DeviceData(Build.MANUFACTURER, Build.HARDWARE, Build.MODEL);
            DebugLogger.add("DeviceData: " + instance.manufacturer + ", " + instance.modem + ", " + instance.model + ".");
            instance.save(prefs);
        }

        return instance;
    }

    /**
     * Saves the phone's DeviceData in JSON format in Android's SharedPreferences.
     *
     * @param sharedPreferences A valid SharedPreferences instance.
     */
    public void save(SharedPreferences sharedPreferences) {
        SharedPreferences.Editor sharedEditor = sharedPreferences.edit();
        String json = new Gson().toJson(this);
        sharedEditor.putString("flutter.deviceData", json);
        sharedEditor.apply();
    }

    public String getManufacturer() {
        return manufacturer;
    }

    public String getModem() {
        return modem;
    }

    public String getModel() {
        return model;
    }
}
