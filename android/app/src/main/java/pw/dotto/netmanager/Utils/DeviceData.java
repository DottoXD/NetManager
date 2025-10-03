package pw.dotto.netmanager.Utils;

import android.content.SharedPreferences;

import com.google.gson.Gson;

public class DeviceData {
    private final String manufacturer;
    private final String modem;

    public DeviceData(String manufacturer, String modem) {
        this.manufacturer = manufacturer;
        this.modem = modem;
    }

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
