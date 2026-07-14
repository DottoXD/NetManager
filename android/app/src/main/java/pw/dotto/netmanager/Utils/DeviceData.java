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
 * @version 0.1.0
 */
public class DeviceData {
    private static DeviceData instance;

    private final String manufacturer;
    private final String modem;

    public DeviceData(String manufacturer, String modem) {
        this.manufacturer = manufacturer.toLowerCase();
        this.modem = modem.toLowerCase();
    }

    public static synchronized DeviceData getInstance(SharedPreferences prefs) {
        if (instance == null) {
            instance = new DeviceData(Build.MANUFACTURER, Build.HARDWARE);
            DebugLogger.add("DeviceData: " + instance.manufacturer + ", " + instance.modem);
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
}
