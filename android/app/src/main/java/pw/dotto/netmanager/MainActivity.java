package pw.dotto.netmanager;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.NetmanagerEvent;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Core.Notifications.Service;
import pw.dotto.netmanager.Fetchers.Location;
import pw.dotto.netmanager.Fetchers.Sensors;
import pw.dotto.netmanager.Utils.Activities;
import pw.dotto.netmanager.Utils.DeviceData;
import pw.dotto.netmanager.Utils.Permissions;
import pw.dotto.netmanager.Utils.DebugLogger;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "pw.dotto.netmanager/telephony";

  private Manager core = null;
  private int selectedSim = 0;

  private MethodChannel chn;
  private SharedPreferences sharedPreferences;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    Gson gson = new Gson();

    if (sharedPreferences == null)
      sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);

    if (!sharedPreferences.contains("deviceData"))
      new DeviceData(Build.MANUFACTURER, Build.HARDWARE).save(sharedPreferences);

    chn = new MethodChannel(
        flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

    chn.setMethodCallHandler((call, result) -> {
      if (core == null) {
        core = new Manager(this);
      }

      switch (call.method) {
        case "checkPermissions":
          boolean perms = Permissions.check(this);
          if (!perms) {
            Permissions.request(this);
          }
          result.success(perms);
          break;

        case "requestPermissions":
          Permissions.request(this);
          result.success(null);
          break;

        case "getOperator":
          String operator = core.getSimOperator(selectedSim);
          if (!"NetManager".equals(operator)) {
            result.success(operator);
          } else {
            result.error(
                "Unknown", "Unknown", null); // add proper error handling
          }
          break;

        case "getCarrier":
          String carrier = core.getSimCarrier(selectedSim);
          if (!"NetManager".equals(carrier)) {
            result.success(carrier);
          } else {
            result.error(
                "Unknown", "Unknown", null); // add proper error handling
          }
          break;

        case "getNetworkData":
          SIMData simData = core.getSimNetworkData(selectedSim);
          result.success(gson.toJson(simData));
          break;

        case "getNetworkGen":
          int gen = core.getSimNetworkGen(selectedSim);
          if (core.getNsaStatus(selectedSim))
            gen = 5;
          result.success(gen);
          break;

        case "getPlmn":
          String plmn = core.getPlmn(selectedSim);
          result.success(plmn);
          break;

        case "sendNotification":
          try {
            startForegroundService(new Intent(this, Service.class));
            result.success(null);
          } catch (Exception e) {
            result.error("Unknown", e.getMessage(), null); // add proper error handling
          }
          break;

        case "cancelNotification":
          try {
            stopService(new Intent(this, Service.class));
            result.success(null);
          } catch (Exception e) {
            result.error("Unknown", e.getMessage(), null); // add proper error handling
          }
          break;

        case "openRadioInfo":
          try {
            Activities.openRadioInfo(this);
            result.success(null);
          } catch (Exception e) {
            result.error("Unknown", e.getMessage(), null); // add proper error handling
          }
          break;

        case "openSamsungInfo":
          try {
            Activities.openSamsungInfo(this);
            result.success(null);
          } catch (Exception e) {
            result.error("Unknown", e.getMessage(), null); // add proper error handling
          }
          break;

        case "switchSim":
          if (core.getSimCount() > 1) {
            if (selectedSim == 0)
              selectedSim = 1;
            else
              selectedSim = 0;
          } else {
            selectedSim = 0;
          }

          chn.invokeMethod("restartTimer", null);
          result.success(null);
          break;

        case "getSimCount":
          int count = core.getSimCount();
          result.success(count);
          break;

        case "getEvents":
          EventManager eventManager = core.getEventManager();
          if (eventManager == null) {
            result.success(gson.toJson(List.of()));
            break;
          }

          NetmanagerEvent[] events = eventManager.getEvents();
          result.success(gson.toJson(events));
          break;

        case "getDebugLogs":
          String[] logs = DebugLogger.getLogs();
          result.success(gson.toJson(logs));
          break;

        case "getLocation":
          Location locationFetcher = Location.getInstance(this);

          if (locationFetcher == null || locationFetcher.getLastLocation() == null) {
            result.success(gson.toJson(new double[] { 0.000000, 0.000000 })); // hopefully nobody will ever use
                                                                              // netmanager there...
            break;
          }

          android.location.Location location = locationFetcher.getLastLocation();
          result.success(gson.toJson(new double[] { location.getLatitude(), location.getLongitude() }));
          break;

        case "getAccelerometerData":
          Sensors sensors = Sensors.getInstance(this);

          if (sensors == null) {
            result.success(gson.toJson(new float[] { 0.0F, 0.0F, 0.0F }));
            break;
          }

          result.success(gson.toJson(sensors.getAccelerometerData()));
          break;

        case "getVersion":
          String version = "Unknown";
          try {
            version = getPackageManager().getPackageInfo(getPackageName(), 0).versionName;
          } catch (Exception ignored) {
          }

          result.success(version);
          break;

        default:
          result.notImplemented();
          break;
      }
    });
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    if (sharedPreferences == null)
      sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);

    if (core == null)
      core = new Manager(this);
  }

  @Override
  public void onStop() {
    if (sharedPreferences == null || !sharedPreferences.getBoolean("flutter.backgroundService", false)) {
      SimReceiverManager simReceiverManager = core.getSimReceiverManager();
      if (simReceiverManager != null)
        simReceiverManager.unregisterStateReceiver();
    }

    super.onStop();
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    Permissions.handleResult(this, requestCode, permissions, grantResults);
  }
}
