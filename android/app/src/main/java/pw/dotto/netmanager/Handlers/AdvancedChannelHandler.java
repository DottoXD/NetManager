package pw.dotto.netmanager.Handlers;

import android.annotation.SuppressLint;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Shizuku.ShizukuClient;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.Utils.Permissions;

public class AdvancedChannelHandler implements MethodChannel.MethodCallHandler {
    private final WeakReference<MainActivity> activityReference;

    public AdvancedChannelHandler(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    @SuppressLint("MissingPermission")
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return;

        switch (call.method) {
            case "getAdvancedModeData":
                if (!activity.isAdvancedMode()) {
                    result.error("ADVANCED_MODE_DISABLED", "Advanced mode is not enabled.", null);
                    return;
                }

                ImsRuntime imsRuntime = activity.getImsRuntime();
                WeakReference<MainActivity> activityReference = this.activityReference;

                new Thread(() -> {
                    try {
                        MainActivity currentActivity = activityReference.get();
                        if (currentActivity == null)
                            return;

                        int selectedSim = currentActivity.getSelectedSim();
                        int subId = currentActivity.getCore() != null
                                ? currentActivity.getCore().getSubscriptionId(selectedSim)
                                : -1;

                        Map<String, Object> advancedData = ShizukuClient.fetch(subId, selectedSim);

                        Map<String, Object> runtimeIms = null;
                        currentActivity = activityReference.get();

                        if (currentActivity != null && Permissions.check(activity))
                            runtimeIms = imsRuntime.readImsRuntimeState();

                        @SuppressWarnings("unchecked")
                        Map<String, Object> imsMap = (Map<String, Object>) advancedData.get("ims");
                        if (imsMap == null) {
                            imsMap = new HashMap<>();
                            advancedData.put("ims", imsMap);
                        }

                        if (runtimeIms != null)
                            imsMap.putAll(runtimeIms);

                        currentActivity = activityReference.get();
                        if (currentActivity != null) {
                            MainActivity finalActivity = currentActivity;
                            finalActivity
                                    .runOnUiThread(() -> result.success(finalActivity.getGson().toJson(advancedData)));
                        }
                    } catch (Exception e) {
                        MainActivity finalActivity = activityReference.get();
                        if (finalActivity != null) {
                            finalActivity
                                    .runOnUiThread(() -> result.error("ADVANCED_DATA_ERROR", e.getMessage(), null));
                        }
                    }
                }).start();
                break;

            default:
                result.notImplemented();
                break;
        }
    }
}
