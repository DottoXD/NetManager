package pw.dotto.netmanager.Handlers;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;
import java.util.HashSet;
import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Diag.NetManagerDiagClient;
import pw.dotto.netmanager.MainActivity;

public class DiagChannelHandler implements MethodChannel.MethodCallHandler {
    private final WeakReference<MainActivity> activityReference;

    public DiagChannelHandler(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return;

        NetManagerDiagClient diagClient = NetManagerDiagClient.getInstance(activity);
        switch (call.method) {
            case "isSupported":
                result.success(activity.getDiagRuntime().isDiagSupported());
                break;

            case "isAvailable":
                NetManagerDiagClient existing = NetManagerDiagClient.getInstanceIfCreated();
                result.success(existing != null && existing.isConnected());
                break;

            case "connect":
                diagClient.connect();
                result.success(null);
                break;

            case "requestFeatures":
                List<String> features = call.argument("features");
                Boolean wanted = call.argument("wanted");
                if (features == null || wanted == null) {
                    result.error("DIAG_BAD_ARGS",
                            "Missing 'features' (List<String>) or 'wanted' parameters (bool).", null);
                    return;
                }

                diagClient.requestFeatures("flutter", new HashSet<>(features), wanted);
                result.success(null);
                break;

            case "getLastStatus":
                NetManagerDiagClient.StatusMessage status = diagClient.getLastStatus();
                result.success(status != null ? activity.getGson().toJson(status) : null);
                break;

            case "stopDaemon":
                DiagRuntime diagRuntime = activity.getDiagRuntime();
                WeakReference<MainActivity> activityReference = this.activityReference;

                new Thread(() -> {
                    boolean stopped = diagRuntime.stopDiagDaemon();
                    MainActivity currentActivity = activityReference.get();
                    if (currentActivity != null)
                        currentActivity.runOnUiThread(() -> result.success(stopped));
                }).start();
                break;

            default:
                result.notImplemented();
                break;
        }
    }
}
