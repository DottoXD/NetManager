package pw.dotto.netmanager;

import android.content.SharedPreferences;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.gson.Gson;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Core.Processors.DevicePatches;
import pw.dotto.netmanager.Fetchers.Location;
import pw.dotto.netmanager.Fetchers.Sensors;
import pw.dotto.netmanager.Handlers.AdvancedChannelHandler;
import pw.dotto.netmanager.Handlers.DiagChannelHandler;
import pw.dotto.netmanager.Handlers.DiagEventStreamHandler;
import pw.dotto.netmanager.Handlers.DiagRuntime;
import pw.dotto.netmanager.Handlers.ImsRuntime;
import pw.dotto.netmanager.Handlers.MainChannelHandler;
import pw.dotto.netmanager.Speedtest.Client;
import pw.dotto.netmanager.Utils.DeviceData;
import pw.dotto.netmanager.Utils.Permissions;
import pw.dotto.netmanager.WearOS.WearHandler;

import java.util.List;
import java.lang.ref.WeakReference;

/**
 * //todo
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "pw.dotto.netmanager/bridge";
    private static final String SPEEDTEST_CHANNEL = "pw.dotto.netmanager/speedtest";
    private static final String ADVANCED_CHANNEL = "pw.dotto.netmanager/advanced";
    private static final String DIAG_CHANNEL = "pw.dotto.netmanager/diag";
    private static final String DIAG_EVENTS_CHANNEL = "pw.dotto.netmanager/diag/events";
    public static final int SHIZUKU_REQ_CODE = 23;

    public static String PACKAGE_NAME;

    private Manager core;
    private int selectedSim;
    private final WearHandler wearHandler = new WearHandler();
    private final Gson gson = new Gson();
    private DiagRuntime diagRuntime;
    private ImsRuntime imsRuntime;

    private MethodChannel chn;
    private MethodChannel speedtestChn;
    private MethodChannel advancedChn;
    private MethodChannel diagChn;
    private EventChannel diagEventChn;
    private DiagEventStreamHandler diagEventStreamHandler;

    private SharedPreferences sharedPreferences;
    private Client activeSpeedtestClient;
    private boolean pipEnabled;
    private boolean advancedMode;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        initializeRuntimeHelpers();
        initializeSharedState();

        chn = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        speedtestChn = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), SPEEDTEST_CHANNEL);
        advancedChn = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), ADVANCED_CHANNEL);
        diagChn = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DIAG_CHANNEL);
        diagEventChn = new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), DIAG_EVENTS_CHANNEL);

        chn.setMethodCallHandler(new MainChannelHandler(this));
        advancedChn.setMethodCallHandler(new AdvancedChannelHandler(this));
        diagChn.setMethodCallHandler(new DiagChannelHandler(this));
        diagEventStreamHandler = new DiagEventStreamHandler(this);
        diagEventChn.setStreamHandler(diagEventStreamHandler);
    }

    private void initializeRuntimeHelpers() {
        if (diagRuntime == null)
            diagRuntime = new DiagRuntime(this);
        if (imsRuntime == null)
            imsRuntime = new ImsRuntime(this);
    }

    private void initializeSharedState() {
        if (sharedPreferences == null) {
            sharedPreferences = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
            advancedMode = sharedPreferences.getBoolean("flutter.advancedMode", false);

            if (advancedMode && !Permissions.checkShizuku())
                Permissions.requestShizuku(SHIZUKU_REQ_CODE);
        }
    }

    public void initializeCoreIfPermitted() {
        if (!Permissions.check(this, Permissions.READ_PHONE_STATE))
            return;

        if (core == null) {
            core = new Manager(this, advancedMode);
            updateCoreInterval();
        }
    }

    void updateCoreInterval() {
        try {
            if (core != null)
                core.updateInterval((int) sharedPreferences.getLong("flutter.updateInterval", 3));
        } catch (Exception ignored) {
        }
    }

    public void ensureValidSelectedSim() {
        if (core == null)
            return;

        List<Integer> slotIds = core.getSimSlotIds();
        if (slotIds.isEmpty())
            return;

        if (!slotIds.contains(selectedSim))
            selectedSim = slotIds.get(0);
    }

    public Manager getCore() {
        return core;
    }

    public int getSelectedSim() {
        return selectedSim;
    }

    public void setSelectedSim(int selectedSim) {
        this.selectedSim = selectedSim;
    }

    public boolean isAdvancedMode() {
        return advancedMode;
    }

    public void setAdvancedMode(boolean advancedMode) {
        this.advancedMode = advancedMode;
    }

    public void setPipEnabled(boolean pipEnabled) {
        this.pipEnabled = pipEnabled;
    }

    public SharedPreferences getPrefs() {
        return sharedPreferences;
    }

    public Gson getGson() {
        return gson;
    }

    public MethodChannel getMainChannel() {
        return chn;
    }

    public MethodChannel getSpeedtestChannel() {
        return speedtestChn;
    }

    public Client getActiveSpeedtestClient() {
        return activeSpeedtestClient;
    }

    public void setActiveSpeedtestClient(Client client) {
        activeSpeedtestClient = client;
    }

    public DiagRuntime getDiagRuntime() {
        if (diagRuntime == null)
            initializeRuntimeHelpers();
        return diagRuntime;
    }

    public ImsRuntime getImsRuntime() {
        if (imsRuntime == null)
            initializeRuntimeHelpers();
        return imsRuntime;
    }

    private void stopActiveSpeedtest() {
        if (activeSpeedtestClient != null) {
            try {
                activeSpeedtestClient.stopTest();
            } catch (Exception ignored) {
            }
            activeSpeedtestClient = null;
        }
    }

    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode);
        pipEnabled = isInPictureInPictureMode;

        if (chn != null)
            chn.invokeMethod("onPipChanged", isInPictureInPictureMode);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        PACKAGE_NAME = getPackageName();
        DevicePatches.registerAll();
        initializeRuntimeHelpers();
        initializeSharedState();
        DeviceData.getInstance(sharedPreferences);
        initializeCoreIfPermitted();
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
        if (sensors != null)
            sensors.destroy();

        if (pw.dotto.netmanager.Recording.Service.getInstance() == null) {
            Location locationFetcher = Location.getInstance(this);
            if (locationFetcher != null)
                locationFetcher.dispose();
        }

        super.onStop();
    }

    @Override
    public void onDestroy() {
        if (diagEventStreamHandler != null)
            diagEventStreamHandler.dispose();

        if (chn != null)
            chn.setMethodCallHandler(null);
        if (advancedChn != null)
            advancedChn.setMethodCallHandler(null);
        if (diagChn != null)
            diagChn.setMethodCallHandler(null);
        if (diagEventChn != null)
            diagEventChn.setStreamHandler(null);

        stopActiveSpeedtest();

        wearHandler.onDestroy();

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

        initializeSharedState();
        initializeCoreIfPermitted();
        updateCoreInterval();
    }

    @Override
    public void onPause() {
        super.onPause();

        boolean inPip = isInPictureInPictureMode();
        WeakReference<MainActivity> activityReference = new WeakReference<>(this);

        wearHandler.isWearConnected(isConnected -> {
            MainActivity activity = activityReference.get();
            if (activity != null && activity.core != null && !activity.pipEnabled && !inPip && !isConnected)
                activity.core.dispose();
        });

        wearHandler.onPause();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
            @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        Permissions.handleResult(this, requestCode, permissions, grantResults);
    }
}
