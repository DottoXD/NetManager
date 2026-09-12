package pw.dotto.netmanager;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.app.PictureInPictureParams;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Rational;
import android.widget.Toast;

import androidx.annotation.NonNull;
import com.google.gson.Gson;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.NetManagerEvent;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Core.Processors.DevicePatches;
import pw.dotto.netmanager.Fetchers.Location;
import pw.dotto.netmanager.Fetchers.Sensors;
import pw.dotto.netmanager.Speedtest.Client;
import pw.dotto.netmanager.Speedtest.Scheduler;
import pw.dotto.netmanager.Utils.Activities;
import pw.dotto.netmanager.Utils.DeviceData;
import pw.dotto.netmanager.Utils.FileManager;
import pw.dotto.netmanager.Utils.Permissions;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.PowerUtils;
import pw.dotto.netmanager.WearOS.WearHandler;

/**
 * NetManager's MainActivity class is the core component which coordinates
 * almost any operation performed with the Flutter <-> Native bridge.
 * This class also manages communications with WearOS devices.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "pw.dotto.netmanager/bridge";
  private static final int SHIZUKU_REQ_CODE = 23;

  private Manager core = null;
  private int selectedSim = 0;
  private final WearHandler wearHandler = new WearHandler();

  private MethodChannel chn;
  private SharedPreferences sharedPreferences;
  private Client activeSpeedtestClient = null;
  private boolean pipEnabled = false;
  private boolean advancedMode = false;

  /**
   * This method is used to force NetManager Core to only get data for existing
   * subscriptions.
   */
  private void ensureValidSelectedSim() {
    if (core == null)
      return;

    List<Integer> slotIds = core.getSimSlotIds();
    if (slotIds.isEmpty())
      return;

    if (!slotIds.contains(selectedSim))
      selectedSim = slotIds.get(0);
  }

  /**
   * This method is essentially NetManager's core on Android.
   *
   * @param flutterEngine The Flutter engine.
   */
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    Gson gson = new Gson();

    if (sharedPreferences == null) {
      sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
      advancedMode = sharedPreferences.getBoolean("advancedMode", false);

      if (advancedMode == true && !Permissions.checkShizuku())
        Permissions.requestShizuku(SHIZUKU_REQ_CODE);
    }

    chn = new MethodChannel(
        flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);

    chn.setMethodCallHandler((call, result) -> {
      switch (call.method) {
        case "checkPermissions":
          boolean perms;
          if (call.hasArgument(("perms"))) {
            perms = Permissions.check(this, call.argument("perms"));
          } else {
            perms = Permissions.check(this);
          }

          result.success(perms);
          break;

        case "requestPermissions":
          if (call.hasArgument(("perms"))) {
            Permissions.request(this, call.argument("perms"));
          } else {
            Permissions.request(this);
          }

          result.success(null);
          break;

        case "openRadioInfo":
          try {
            boolean success = Activities.openRadioInfo(this);
            result.success(success);
          } catch (Exception e) {
            result.error("MENU_RADIO_INFO", e.getMessage(), e.getStackTrace());
          }
          break;

        case "openSamsungInfo":
          try {
            boolean success = Activities.openSamsungInfo(this);
            result.success(success);
          } catch (Exception e) {
            result.error("MENU_SAMSUNG_INFO", e.getMessage(), e.getStackTrace());
          }
          break;

        case "openHuaweiInfo":
          try {
            boolean success = Activities.openHuaweiInfo(this);
            result.success(success);
          } catch (Exception e) {
            result.error("MENU_HUAWEI_INFO", e.getMessage(), e.getStackTrace());
          }
          break;

        case "openMediatekInfo":
          try {
            boolean success = Activities.openMediatekInfo(this);
            result.success(success);
          } catch (Exception e) {
            result.error("MENU_MEDIATEK_INFO", e.getMessage(), e.getStackTrace());
          }
          break;

        case "openXiaomiInfo":
          try {
            boolean success = Activities.openXiaomiInfo(this);
            result.success(success);
          } catch (Exception e) {
            result.error("MENU_XIAOMI_INFO", e.getMessage(), e.getStackTrace());
          }
          break;

        case "getDebugLogs":
          String[] logs = DebugLogger.getLogs();
          String jsonLogs = gson.toJson(logs);
          result.success(jsonLogs);
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

        case "showToast":
          try {
            String msg = call.argument("message");
            Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
          } catch (Exception ignored) {
          }

          result.success(null);
          break;

        case "share":
          String path = call.argument("path");

          if (path != null) {
            if (path.endsWith(".txt")) {
              FileManager.shareFile(this, path, "text/plain", "Share logs");
            } else if (path.endsWith(".csv")) {
              FileManager.shareFile(this, path, "text/csv", "Share CSV Export");
            } else if (path.endsWith(".kml")) {
              FileManager.shareFile(this, path, "application/vnd.google-earth.kml+xml", "Share KML Export");
            } else {
              FileManager.shareFile(this, path, "image/png", "Share image");
            }

            result.success(null);
          } else {
            result.error(
                "BACKEND_SHARE", "Path is null.", null);
          }
          break;

        case "startTest":
          String pingUrl = call.argument("pingUrl");
          String downloadUrl = call.argument("downloadUrl");
          String uploadUrl = call.argument("uploadUrl");

          DebugLogger.add("Starting a speed test with pingUrl '" + pingUrl + "', downloadUrl '" + downloadUrl
              + "', uploadUrl '" + uploadUrl + "'.");

          if (activeSpeedtestClient != null) {
            activeSpeedtestClient.stopTest();
          }

          activeSpeedtestClient = new Client();
          activeSpeedtestClient.runSpeedTest(this, pingUrl, downloadUrl, uploadUrl,
              new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL));
          result.success(null);
          break;

        case "stopTest":
          if (activeSpeedtestClient != null) {
            activeSpeedtestClient.stopTest();
            activeSpeedtestClient = null;
          }

          result.success(null);
          break;

        case "startScheduledTest":
          String pUrl = call.argument("pingUrl");
          String dUrl = call.argument("downloadUrl");
          String uUrl = call.argument("uploadUrl");
          int interval = call.argument("intervalMs");

          sharedPreferences.edit().putBoolean("sIsScheduled", true).apply();

          Intent startIntent = new Intent(this, Scheduler.class);
          startIntent.putExtra("pingUrl", pUrl);
          startIntent.putExtra("downloadUrl", dUrl);
          startIntent.putExtra("uploadUrl", uUrl);
          startIntent.putExtra("intervalMs", interval);

          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(startIntent);
          } else {
            startService(startIntent);
          }

          result.success(true);
          break;

        case "stopScheduledTest":
          sharedPreferences.edit().putBoolean("sIsScheduled", false).apply();

          Intent stopIntent = new Intent(this, Scheduler.class);
          stopIntent.setAction("STOP_SCHEDULE");
          startService(stopIntent);

          result.success(true);
          break;

        case "isScheduleActive":
          result.success(sharedPreferences.getBoolean("sIsScheduled", false));
          break;

        case "isIgnoringBatteryOptimisations":
          result.success(PowerUtils.isIgnoringBatteryOptimisations(this));
          break;

        case "requestIgnoreBatteryOptimisations":
          boolean opened = PowerUtils.requestIgnoreBatteryOptimisations(this);
          result.success(opened);
          break;

        default:
          if (!Permissions.check(this, Permissions.READ_PHONE_STATE)) {
            result.error("BACKEND_PERMISSIONS", "App is missing READ_PHONE_STATE permissions.", null);
            return;
          }

          if (core == null) {
            core = new Manager(this, advancedMode);

            try {
              int updateInterval = ((Long) sharedPreferences.getLong("flutter.updateInterval", 3)).intValue();
              core.updateInterval(updateInterval);
            } catch (Exception ignored) {
            }
          }

          ensureValidSelectedSim();

          switch (call.method) {
            case "getOperator":
              String operator = core.getSimOperator(selectedSim);
              if ("NetManager".equals(operator))
                DebugLogger.add("Could not detect SIM operator...");

              result.success(operator);
              break;

            case "getCarrier":
              String carrier = core.getSimCarrier(selectedSim);
              if ("NetManager".equals(carrier))
                DebugLogger.add("Could not detect SIM carrier...");

              result.success(carrier);
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

            case "getEmergencyOnly":
              result.success(core.getEmergencyStatus(selectedSim));
              break;

            case "getPlmn":
              String plmn = core.getPlmn(selectedSim);
              result.success(plmn);
              break;

            case "sendNotification":
              try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                  startForegroundService(new Intent(this, pw.dotto.netmanager.Core.Notifications.Service.class));
                } else {
                  startService(new Intent(this, pw.dotto.netmanager.Core.Notifications.Service.class));
                }

                result.success(null);
              } catch (Exception e) {
                result.error("BACKEND_NOTIFICATION_SEND", e.getMessage(), e.getStackTrace());
              }
              break;

            case "cancelNotification":
              try {
                stopService(new Intent(this, pw.dotto.netmanager.Core.Notifications.Service.class));
                result.success(null);
              } catch (Exception e) {
                result.error("BACKEND_NOTIFICATION_CANCEL", e.getMessage(), e.getStackTrace());
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

              NetManagerEvent[] events = eventManager.getEvents();
              result.success(gson.toJson(events));
              break;

            case "isActiveSubscriptionSelected":
              boolean inactive = false;

              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                int status = core.getDataStatus(selectedSim);

                switch (status) {
                  case TelephonyManager.DATA_DISCONNECTED:
                  case TelephonyManager.DATA_DISCONNECTING:
                  case TelephonyManager.DATA_SUSPENDED:
                  case TelephonyManager.DATA_UNKNOWN:
                    inactive = true;
                    break;
                }
              } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
                TelephonyManager subscription = core.getSubscription(selectedSim);
                if (subscription != null)
                  inactive = !(SubscriptionManager.getActiveDataSubscriptionId() == subscription.getSubscriptionId());
              }

              result.success(!inactive);
              break;

            case "startRecording":
              String recordingName = call.argument("name");
              int recordingInterval = call.argument("interval");
              String recordingPath = call.argument("path");
              boolean trackUsable = call.argument("trackUsable");
              boolean dualSimMode = Boolean.TRUE.equals(call.argument("dualSimMode"));
              String usabilityTestUrl = call.argument("usabilityTestUrl");

              if (recordingInterval < 1 || recordingInterval > 300 || recordingName == null || recordingPath == null) {
                result.error(
                    "RECORDING_PARAMS", "Invalid recording params!", null);
                return;
              }

              try {
                Intent recordingIntent = new Intent(this, pw.dotto.netmanager.Recording.Service.class);
                recordingIntent.putExtra("name", recordingName);
                recordingIntent.putExtra("interval", recordingInterval);
                recordingIntent.putExtra("path", recordingPath);
                recordingIntent.putExtra("selectedSim", selectedSim);
                recordingIntent.putExtra("dualSimMode", dualSimMode);
                recordingIntent.putExtra("trackUsable", trackUsable);
                recordingIntent.putExtra("usabilityTestUrl", usabilityTestUrl);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                  startForegroundService(recordingIntent);
                } else {
                  startService(recordingIntent);
                }
              } catch (Exception e) {
                result.error(
                    "BACKEND_RECORDING", e.getMessage(), e.getStackTrace());
              }
              result.success(null);
              break;

            case "stopRecording":
              Intent stopRecordingIntent = new Intent(this, pw.dotto.netmanager.Recording.Service.class);
              stopService(stopRecordingIntent);
              result.success(true);
              break;

            case "getLiveRecording":
              pw.dotto.netmanager.Recording.Service serviceInstance = pw.dotto.netmanager.Recording.Service
                  .getInstance();
              if (serviceInstance != null) {
                Integer requestedSim = call.argument("simSlot");
                int targetSlot = (requestedSim != null) ? requestedSim : selectedSim;

                if (serviceInstance.getRecordedData(targetSlot) != null) {
                  String jsonStr = gson.toJson(serviceInstance.getRecordedData(targetSlot));
                  result.success(jsonStr);
                  break;
                }
              } else {
                result.success(null);
              }
              break;

            case "enterPip":
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PictureInPictureParams params = new PictureInPictureParams.Builder()
                    .setAspectRatio(new Rational(16, 9))
                    .build();
                pipEnabled = true;
                enterPictureInPictureMode(params);
                result.success(true);
              } else {
                result.error("PIP_UNSUPPORTED", "Device doesn't support PIP mode.", null);
              }
              break;

            case "checkShizuku":
              result.success(Permissions.checkShizuku());
              break;

            case "requestShizuku":
              Permissions.requestShizuku(SHIZUKU_REQ_CODE);
              result.success(null);
              break;

            case "toggleAdvancedMode":
              advancedMode = !advancedMode;
              result.success(null);
              core.setAdvancedMode(advancedMode);

              if (advancedMode && !Permissions.checkShizuku())
                Permissions.requestShizuku(SHIZUKU_REQ_CODE);
              break;

            case "getDebugReport":
              try {
                Map<String, Object> debugMap = new HashMap<>();

                if (core != null) {
                  SIMData unredactedData = core.getSimNetworkData(selectedSim);

                  if (unredactedData != null) {
                    for (CellData cell : unredactedData.getActiveCells()) {
                      cell.setCellIdentifier(String.valueOf(CELL_INFO_UNAVAILABLE));
                      cell.setAreaCode(CELL_INFO_UNAVAILABLE);
                    }

                    if (unredactedData.getPrimaryCell() != null) {
                      unredactedData.getPrimaryCell().setCellIdentifier(String.valueOf(CELL_INFO_UNAVAILABLE));
                      unredactedData.getPrimaryCell().setAreaCode(CELL_INFO_UNAVAILABLE);
                    }

                    debugMap.put("simData", unredactedData);
                  }

                  debugMap.put("operator", core.getSimOperator(selectedSim));
                  debugMap.put("carrier", core.getSimCarrier(selectedSim));
                  debugMap.put("gen", core.getSimNetworkGen(selectedSim));
                  debugMap.put("plmn", core.getPlmn(selectedSim));
                  debugMap.put("simCount", core.getSimCount());
                  debugMap.put("nsaStatus", core.getNsaStatus(selectedSim));
                  debugMap.put("bandwidths", core.getCellBandwidths(selectedSim));
                  debugMap.put("signalStrengths", core.getCellSignalStrengths(selectedSim));
                }

                debugMap.put("advancedMode", advancedMode);
                debugMap.put("logs", DebugLogger.getLogs());
                debugMap.put("deviceData", DeviceData.getInstance(null).toString());
                debugMap.put("androidVersion", Build.VERSION.RELEASE);
                debugMap.put("sdkInt", Build.VERSION.SDK_INT);

                result.success(gson.toJson(debugMap));
              } catch (Exception e) {
                result.error("DEBUG_FETCH_FAILED", e.getMessage(), e.getStackTrace());
              }
              break;

            default:
              result.notImplemented();
              break;
          }

          break;
      }
    });
  }

  @Override
  public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode);

    if (chn != null) {
      pipEnabled = isInPictureInPictureMode;
      chn.invokeMethod("onPipChanged", isInPictureInPictureMode);
    }
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    DevicePatches.registerAll();

    if (sharedPreferences == null) {
      sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
      advancedMode = sharedPreferences.getBoolean("advancedMode", false);

      if (advancedMode == true && !Permissions.checkShizuku())
        Permissions.requestShizuku(SHIZUKU_REQ_CODE);
    }

    DeviceData.getInstance(sharedPreferences);

    if (Permissions.check(this, Permissions.READ_PHONE_STATE)) {
      if (core == null) {
        core = new Manager(this, advancedMode);

        try {
          int updateInterval = ((Long) sharedPreferences.getLong("flutter.updateInterval", 3)).intValue();
          core.updateInterval(updateInterval);
        } catch (Exception ignored) {
        }
      }
    }

    wearHandler.onCreate(this);
  }

  @Override
  public void onStop() {
    if (core != null
        && (sharedPreferences == null || !sharedPreferences.getBoolean("flutter.backgroundService", false))) {
      SimReceiverManager simReceiverManager = core.getSimReceiverManager();
      if (simReceiverManager != null)
        simReceiverManager.unregisterStateReceiver();
    }

    Sensors sensors = Sensors.getInstance(this);
    if (sensors != null) {
      sensors.destroy();
    }

    if (pw.dotto.netmanager.Recording.Service.getInstance() == null) {
      Location locationFetcher = Location.getInstance(this);
      if (locationFetcher != null) {
        locationFetcher.dispose();
      }
    }

    super.onStop();
  }

  @Override
  public void onDestroy() {
    if (wearHandler != null) {
      wearHandler.onDestroy();
    }

    if (core != null) {
      core.dispose();
      core = null;
    }

    super.onDestroy();
  }

  @Override
  public void onResume() {
    super.onResume();
    wearHandler.onResume();

    if (core == null && Permissions.check(this, Permissions.READ_PHONE_STATE)) {
      core = new Manager(this, advancedMode);
    }

    try {
      if (core != null) {
        int updateInterval = ((Long) sharedPreferences.getLong("flutter.updateInterval", 3)).intValue();
        core.updateInterval(updateInterval);
      }
    } catch (Exception ignored) {
    }
  }

  @Override
  public void onPause() {
    super.onPause();

    wearHandler.isWearConnected(isConnected -> {
      if (core != null && !pipEnabled && !isConnected) {
        core.dispose();
      }
    });

    wearHandler.onPause();
  }

  @Override
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    Permissions.handleResult(this, requestCode, permissions, grantResults);
  }
}
