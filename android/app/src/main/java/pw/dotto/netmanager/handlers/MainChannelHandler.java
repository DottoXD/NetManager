package pw.dotto.netmanager.handlers;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.app.PictureInPictureParams;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.location.LocationManager;
import android.os.Build;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Rational;
import android.widget.Toast;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.core.events.EventManager;
import pw.dotto.netmanager.core.events.NetManagerEvent;
import pw.dotto.netmanager.core.Manager;
import pw.dotto.netmanager.core.mobile.celldatas.CellData;
import pw.dotto.netmanager.core.mobile.SIMData;
import pw.dotto.netmanager.core.notifications.Service;
import pw.dotto.netmanager.fetchers.Location;
import pw.dotto.netmanager.fetchers.Sensors;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.speedtest.Client;
import pw.dotto.netmanager.speedtest.Scheduler;
import pw.dotto.netmanager.utils.Activities;
import pw.dotto.netmanager.utils.DebugLogger;
import pw.dotto.netmanager.utils.DeviceData;
import pw.dotto.netmanager.utils.FileManager;
import pw.dotto.netmanager.utils.Permissions;
import pw.dotto.netmanager.utils.PowerUtils;
import rikka.shizuku.Shizuku;

/**
 * NetManager's MainChannelHandler is the main handler for most native platform
 * calls across NetManager.
 * This class handles permission utilities, speed tests, cell data fetching &
 * more.
 *
 * @author DottoXD
 * @version 0.2.4
 */
public class MainChannelHandler implements MethodChannel.MethodCallHandler {
    private final WeakReference<MainActivity> activityReference;

    public MainChannelHandler(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    private interface ActivityAction {
        boolean open() throws Exception;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return;

        switch (call.method) {
            case "checkPermissions":
                boolean perms = call.hasArgument("perms")
                        ? Permissions.check(activity, call.argument("perms"))
                        : Permissions.check(activity);
                result.success(perms);
                break;

            case "requestPermissions":
                if (call.hasArgument("perms"))
                    Permissions.request(activity, call.argument("perms"));
                else
                    Permissions.request(activity);
                result.success(null);
                break;

            case "openRadioInfo":
                openActivity(result, "MENU_RADIO_INFO", () -> Activities.openRadioInfo(activity));
                break;

            case "openSamsungInfo":
                openActivity(result, "MENU_SAMSUNG_INFO", () -> Activities.openSamsungInfo(activity));
                break;

            case "openHuaweiInfo":
                openActivity(result, "MENU_HUAWEI_INFO", () -> Activities.openHuaweiInfo(activity));
                break;

            case "openMediatekInfo":
                openActivity(result, "MENU_MEDIATEK_INFO", () -> Activities.openMediatekInfo(activity));
                break;

            case "openXiaomiInfo":
                openActivity(result, "MENU_XIAOMI_INFO", () -> Activities.openXiaomiInfo(activity));
                break;

            case "getDebugLogs":
                result.success(activity.getGson().toJson(DebugLogger.getLogs()));
                break;

            case "getLocation":
                Location locationFetcher = Location.getInstance(activity);
                if (locationFetcher == null || locationFetcher.getLastLocation() == null) {
                    result.success(activity.getGson().toJson(new double[] { 0.000000, 0.000000 }));
                    break;
                }

                android.location.Location location = locationFetcher.getLastLocation();
                result.success(
                        activity.getGson().toJson(new double[] { location.getLatitude(), location.getLongitude() }));
                break;

            case "getAccelerometerData":
                Sensors sensors = Sensors.getInstance(activity);
                if (sensors == null) {
                    result.success(activity.getGson().toJson(new float[] { 0.0F, 0.0F, 0.0F }));
                    break;
                }
                result.success(activity.getGson().toJson(sensors.getAccelerometerData()));
                break;

            case "getVersion":
                String version = "Unknown";
                try {
                    version = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionName;
                } catch (Exception ignored) {
                }
                result.success(version);
                break;

            case "showToast":
                try {
                    String msg = call.argument("message");
                    Toast.makeText(activity, msg, Toast.LENGTH_SHORT).show();
                } catch (Exception ignored) {
                }
                result.success(null);
                break;

            case "share":
                handleShare(activity, call, result);
                break;

            case "startTest":
                String pingUrl = call.argument("pingUrl");
                String downloadUrl = call.argument("downloadUrl");
                String uploadUrl = call.argument("uploadUrl");

                DebugLogger.add("Starting a speed test with pingUrl '" + pingUrl + "', downloadUrl '" + downloadUrl
                        + "', uploadUrl '" + uploadUrl + "'.");

                Client activeSpeedtestClient = activity.getActiveSpeedtestClient();
                if (activeSpeedtestClient != null)
                    activeSpeedtestClient.stopTest();

                activeSpeedtestClient = new Client();
                activity.setActiveSpeedtestClient(activeSpeedtestClient);
                activeSpeedtestClient.runSpeedTest(activity, pingUrl, downloadUrl, uploadUrl,
                        activity.getSpeedtestChannel());
                result.success(null);
                break;

            case "stopTest":
                Client client = activity.getActiveSpeedtestClient();
                if (client != null) {
                    client.stopTest();
                    activity.setActiveSpeedtestClient(null);
                }
                result.success(null);
                break;

            case "startScheduledTest":
                SharedPreferences prefs = activity.getPrefs();
                String pUrl = call.argument("pingUrl");
                String dUrl = call.argument("downloadUrl");
                String uUrl = call.argument("uploadUrl");
                int interval = call.argument("intervalMs");
                prefs.edit().putBoolean("sIsScheduled", true).apply();

                Intent startIntent = new Intent(activity, Scheduler.class);
                startIntent.putExtra("pingUrl", pUrl);
                startIntent.putExtra("downloadUrl", dUrl);
                startIntent.putExtra("uploadUrl", uUrl);
                startIntent.putExtra("intervalMs", interval);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    activity.startForegroundService(startIntent);
                else
                    activity.startService(startIntent);
                result.success(true);
                break;

            case "stopScheduledTest":
                activity.getPrefs().edit().putBoolean("sIsScheduled", false).apply();
                Intent stopIntent = new Intent(activity, Scheduler.class);
                stopIntent.setAction("STOP_SCHEDULE");
                activity.startService(stopIntent);
                result.success(true);
                break;

            case "isScheduleActive":
                result.success(activity.getPrefs().getBoolean("sIsScheduled", false));
                break;

            case "isIgnoringBatteryOptimisations":
                result.success(PowerUtils.isIgnoringBatteryOptimisations(activity));
                break;

            case "requestIgnoreBatteryOptimisations":
                result.success(PowerUtils.requestIgnoreBatteryOptimisations(activity));
                break;

            default:
                handleCoreMethod(activity, call, result);
                break;
        }
    }

    private void handleCoreMethod(MainActivity activity, MethodCall call, MethodChannel.Result result) {
        if (!Permissions.check(activity, Permissions.READ_PHONE_STATE)) {
            result.error("BACKEND_PERMISSIONS", "App is missing READ_PHONE_STATE permissions.", null);
            return;
        }

        activity.initializeCoreIfPermitted();
        Manager core = activity.getCore();
        if (core == null) {
            result.error("BACKEND_CORE", "NetManager core is unavailable.", null);
            return;
        }

        activity.ensureValidSelectedSim();
        int selectedSim = activity.getSelectedSim();

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
                result.success(activity.getGson().toJson(core.getSimNetworkData(selectedSim)));
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

            case "isAirplaneMode":
                result.success(core.isAirplaneMode(selectedSim));
                break;

            case "getPlmn":
                result.success(core.getPlmn(selectedSim));
                break;

            case "sendNotification":
                sendNotification(activity, result);
                break;

            case "cancelNotification":
                cancelNotification(activity, result);
                break;

            case "switchSim":
                if (core.getSimCount() > 1)
                    activity.setSelectedSim(selectedSim == 0 ? 1 : 0);
                else
                    activity.setSelectedSim(0);
                if (activity.getMainChannel() != null)
                    activity.getMainChannel().invokeMethod("restartTimer", null);
                result.success(null);
                break;

            case "getSimCount":
                result.success(core.getSimCount());
                break;

            case "getEvents":
                EventManager eventManager = core.getEventManager();
                if (eventManager == null) {
                    result.success(activity.getGson().toJson(Collections.emptyList()));
                    break;
                }
                NetManagerEvent[] events = eventManager.getEvents();
                result.success(activity.getGson().toJson(events));
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
                        inactive = !(SubscriptionManager.getActiveDataSubscriptionId() == subscription
                                .getSubscriptionId());
                }
                result.success(!inactive);
                break;

            case "startRecording":
                handleStartRecording(activity, call, result, selectedSim);
                break;

            case "stopRecording":
                Intent stopRecordingIntent = new Intent(activity, pw.dotto.netmanager.recording.Service.class);
                activity.stopService(stopRecordingIntent);
                result.success(true);
                break;

            case "getLiveRecording":
                handleGetLiveRecording(activity, call, result, selectedSim);
                break;

            case "enterPip":
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    PictureInPictureParams params = new PictureInPictureParams.Builder()
                            .setAspectRatio(new Rational(16, 9))
                            .build();
                    activity.setPipEnabled(true);
                    activity.enterPictureInPictureMode(params);
                    result.success(true);
                } else {
                    result.error("PIP_UNSUPPORTED", "Device doesn't support PIP mode.", null);
                }
                break;

            case "checkShizuku":
                int status = 0;
                if (!Permissions.checkShizuku())
                    status = 2;
                if (!Shizuku.pingBinder())
                    status = 1;
                result.success(status);
                break;

            case "checkDiag":
                DiagRuntime diagRuntime = activity.getDiagRuntime();
                WeakReference<MainActivity> activityReference = this.activityReference;
                new Thread(() -> {
                    int diagStatus = diagRuntime.checkDiagStatus();
                    MainActivity currentActivity = activityReference.get();
                    if (currentActivity != null)
                        currentActivity.runOnUiThread(() -> result.success(diagStatus));
                }).start();
                break;

            case "requestShizuku":
                Permissions.requestShizuku(MainActivity.SHIZUKU_REQ_CODE);
                result.success(null);
                break;

            case "toggleAdvancedMode":
                boolean advancedMode = !activity.isAdvancedMode();
                activity.setAdvancedMode(advancedMode);
                core.setAdvancedMode(advancedMode);
                if (advancedMode && !Permissions.checkShizuku())
                    Permissions.requestShizuku(MainActivity.SHIZUKU_REQ_CODE);
                result.success(null);
                break;

            case "getDebugReport":
                handleDebugReport(activity, result, core, selectedSim);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    private static void openActivity(MethodChannel.Result result, String errorCode, ActivityAction action) {
        try {
            result.success(action.open());
        } catch (Exception e) {
            result.error(errorCode, e.getMessage(), e.getStackTrace());
        }
    }

    private static void handleShare(MainActivity activity, MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        if (path == null) {
            result.error("BACKEND_SHARE", "Path is null.", null);
            return;
        }

        if (path.endsWith(".txt"))
            FileManager.shareFile(activity, path, "text/plain", "Share logs");
        else if (path.endsWith(".csv"))
            FileManager.shareFile(activity, path, "text/csv", "Share CSV Export");
        else if (path.endsWith(".kml"))
            FileManager.shareFile(activity, path, "application/vnd.google-earth.kml+xml", "Share KML Export");
        else
            FileManager.shareFile(activity, path, "image/png", "Share image");
        result.success(null);
    }

    private static void sendNotification(MainActivity activity, MethodChannel.Result result) {
        try {
            Intent intent = new Intent(activity, Service.class);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                activity.startForegroundService(intent);
            else
                activity.startService(intent);
            result.success(null);
        } catch (Exception e) {
            result.error("BACKEND_NOTIFICATION_SEND", e.getMessage(), e.getStackTrace());
        }
    }

    private static void cancelNotification(MainActivity activity, MethodChannel.Result result) {
        try {
            activity.stopService(new Intent(activity, Service.class));
            result.success(null);
        } catch (Exception e) {
            result.error("BACKEND_NOTIFICATION_CANCEL", e.getMessage(), e.getStackTrace());
        }
    }

    private static void handleStartRecording(MainActivity activity, MethodCall call, MethodChannel.Result result,
            int selectedSim) {
        String recordingName = call.argument("name");
        int recordingInterval = call.argument("interval");
        String recordingPath = call.argument("path");
        boolean trackUsable = call.argument("trackUsable");
        boolean dualSimMode = Boolean.TRUE.equals(call.argument("dualSimMode"));
        String usabilityTestUrl = call.argument("usabilityTestUrl");

        if (recordingInterval < 1 || recordingInterval > 300 || recordingName == null || recordingPath == null) {
            result.error("RECORDING_PARAMS", "Invalid recording params!", null);
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            try {
                LocationManager lm = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);

                if (lm != null && !lm.isLocationEnabled()) {
                    result.error("BACKEND_RECORDING", "Location services are disabled. Enable them to start recording.",
                            null);
                    return;
                }
            } catch (Exception ignored) {
                result.error("BACKEND_RECORDING", "Location services are disabled. Enable them to start recording.",
                        null);
            }
        }

        try {
            Intent recordingIntent = new Intent(activity, pw.dotto.netmanager.recording.Service.class);
            recordingIntent.putExtra("name", recordingName);
            recordingIntent.putExtra("interval", recordingInterval);
            recordingIntent.putExtra("path", recordingPath);
            recordingIntent.putExtra("selectedSim", selectedSim);
            recordingIntent.putExtra("dualSimMode", dualSimMode);
            recordingIntent.putExtra("trackUsable", trackUsable);
            recordingIntent.putExtra("usabilityTestUrl", usabilityTestUrl);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                activity.startForegroundService(recordingIntent);
            else
                activity.startService(recordingIntent);
        } catch (Exception e) {
            result.error("BACKEND_RECORDING", e.getMessage(), e.getStackTrace());
            return;
        }

        result.success(null);
    }

    private static void handleGetLiveRecording(MainActivity activity, MethodCall call, MethodChannel.Result result,
            int selectedSim) {
        pw.dotto.netmanager.recording.Service serviceInstance = pw.dotto.netmanager.recording.Service.getInstance();
        if (serviceInstance == null) {
            result.success(null);
            return;
        }

        Integer requestedSim = call.argument("simSlot");
        int targetSlot = requestedSim != null ? requestedSim : selectedSim;
        Object data = serviceInstance.getRecordedData(targetSlot);
        result.success(data != null ? activity.getGson().toJson(data) : null);
    }

    private static void handleDebugReport(MainActivity activity, MethodChannel.Result result, Manager core,
            int selectedSim) {
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

            debugMap.put("advancedMode", activity.isAdvancedMode());
            debugMap.put("logs", DebugLogger.getLogs());
            debugMap.put("deviceData", DeviceData.getInstance(null).toString());
            debugMap.put("androidVersion", Build.VERSION.RELEASE);
            debugMap.put("sdkInt", Build.VERSION.SDK_INT);
            result.success(activity.getGson().toJson(debugMap));
        } catch (Exception e) {
            result.error("DEBUG_FETCH_FAILED", e.getMessage(), e.getStackTrace());
        }
    }
}
