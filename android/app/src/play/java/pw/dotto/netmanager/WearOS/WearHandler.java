package pw.dotto.netmanager.WearOS;

import static android.content.Context.MODE_PRIVATE;
import static pw.dotto.netmanager.Utils.Mobile.getGenerationLabel;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.MessageClient;
import com.google.android.gms.wearable.MessageEvent;
import com.google.android.gms.wearable.PutDataMapRequest;
import com.google.android.gms.wearable.Wearable;

import java.util.ArrayList;

import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.CellSnapshot;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's WearHandler Play class is the core component of the Android <->
 * WearOS bridge for NetManager.
 *
 * @author DottoXD
 * @version 0.1.5
 */
public class WearHandler implements WearIntegration, MessageClient.OnMessageReceivedListener {
    private Context context;
    private Manager wearManager;

    private final Handler watchKeepAliveHandler = new Handler(Looper.getMainLooper());
    private static final String WEAROS_CONSUMER_ID = "wearos";
    private static final int DEFAULT_POLL_INTERVAL = 3;
    private static final int KEEP_ALIVE_MS = 15000;
    private boolean isWearActive = false;

    private final Runnable stopWearPollingRunnable = () -> {
        if (wearManager != null && isWearActive) {
            wearManager.dispose();
            wearManager = null;
            isWearActive = false;
            DebugLogger.add("WearOS background polling stopped due to watch inactivity.");
        }
    };

    @Override
    public void onCreate(Context context) {
        this.context = context.getApplicationContext();

        Wearable.getMessageClient(this.context).addListener(this);
    }

    @Override
    public void onResume() {
    }

    @Override
    public void onPause() {
    }

    @Override
    public void onDestroy() {
        if (context != null) {
            Wearable.getMessageClient(context).removeListener(this);
        }

        watchKeepAliveHandler.removeCallbacks(stopWearPollingRunnable);

        if (wearManager != null) {
            wearManager.dispose();
            wearManager = null;
        }
        this.context = null;
    }

    /**
     * This method coordinates incoming communications with WearOS devices.
     *
     * @param messageEvent A valid MessageEvent from a WearOS device.
     */
    @Override
    public void onMessageReceived(@NonNull MessageEvent messageEvent) {
        DebugLogger.add("WearOS message received: " + messageEvent.getPath());
        if (messageEvent.getPath().equals("/request_wearos_data")) {
            if (!isWearActive || wearManager == null) {
                wearManager = new Manager(context, WEAROS_CONSUMER_ID, DEFAULT_POLL_INTERVAL);

                try {
                    SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences",
                            MODE_PRIVATE);
                    int updateInterval = ((Long) sharedPreferences.getLong("flutter.backgroundUpdateInterval", 3))
                            .intValue();
                    wearManager.updateInterval(updateInterval);
                } catch (Exception ignored) {
                }

                isWearActive = true;
                DebugLogger.add("WearOS background polling loop started.");
            }

            watchKeepAliveHandler.removeCallbacks(stopWearPollingRunnable);
            watchKeepAliveHandler.postDelayed(stopWearPollingRunnable, KEEP_ALIVE_MS);

            PutDataMapRequest request = PutDataMapRequest.create("/wearos_data");
            DataMap dataMap = request.getDataMap();

            byte[] data = messageEvent.getData();
            int id = data.length > 0 ? data[0] : 0;

            dataMap.putInt("id", id);
            dataMap.putIntegerArrayList("simSlotIds",
                    wearManager != null ? new ArrayList<>(wearManager.getSimSlotIds()) : new ArrayList<>());

            if (wearManager != null) {
                CellSnapshot snapshot = wearManager.getCellSnapshot(id);
                int simCount = wearManager.getSimCount();

                if (snapshot != null) {
                    int gen = snapshot.getNetworkGen();

                    dataMap.putString("network", snapshot.getNetwork());
                    dataMap.putString("node", snapshot.getNode());
                    dataMap.putInt("band", snapshot.getBand());
                    dataMap.putInt("networkGen", gen);
                    dataMap.putInt("processedSignal", snapshot.getProcessedSignal());
                    dataMap.putInt("simCount", simCount);
                    dataMap.putLong("timestamp", snapshot.getTimestamp());

                    ArrayList<DataMap> metricsList = new ArrayList<>();

                    DataMap networkTypeMetric = new DataMap();
                    networkTypeMetric.putString("label", "Technology");
                    networkTypeMetric.putString("value", getGenerationLabel(gen));
                    networkTypeMetric.putString("iconKey", "networkType");
                    metricsList.add(networkTypeMetric);

                    DataMap rawSignalMetric = new DataMap();
                    rawSignalMetric.putString("label", snapshot.getRawSignalString());
                    rawSignalMetric.putString("value", snapshot.getRawSignal() + "dBm");
                    rawSignalMetric.putString("iconKey", "rawSignal");
                    metricsList.add(rawSignalMetric);

                    DataMap signalQualityMetric = new DataMap();
                    signalQualityMetric.putString("label", snapshot.getSignalQualityString());
                    signalQualityMetric.putString("value", snapshot.getSignalQuality() + "dB");
                    signalQualityMetric.putString("iconKey", "signalQuality");
                    metricsList.add(signalQualityMetric);

                    DataMap signalNoiseMetric = new DataMap();
                    signalNoiseMetric.putString("label", snapshot.getSignalNoiseString());
                    signalNoiseMetric.putString("value", snapshot.getSignalNoise() + "dB");
                    signalNoiseMetric.putString("iconKey", "signalNoise");
                    metricsList.add(signalNoiseMetric);

                    DataMap channelNumberMetric = new DataMap();
                    channelNumberMetric.putString("label", snapshot.getChannelNumberString());
                    channelNumberMetric.putString("value", String.valueOf(snapshot.getChannelNumber()));
                    channelNumberMetric.putString("iconKey", "channelNumber");
                    metricsList.add(channelNumberMetric);

                    DataMap areaCodeMetric = new DataMap();
                    areaCodeMetric.putString("label", snapshot.getAreaCodeString());
                    areaCodeMetric.putString("value", String.valueOf(snapshot.getAreaCode()));
                    areaCodeMetric.putString("iconKey", "areaCode");
                    metricsList.add(areaCodeMetric);

                    DataMap stationIdentityMetric = new DataMap();
                    stationIdentityMetric.putString("label", snapshot.getStationIdentityString());
                    stationIdentityMetric.putString("value", String.valueOf(snapshot.getStationIdentity()));
                    stationIdentityMetric.putString("iconKey", "stationIdentity");
                    metricsList.add(stationIdentityMetric);

                    DataMap timingAdvanceMetric = new DataMap();
                    timingAdvanceMetric.putString("label", snapshot.getTimingAdvanceString());
                    timingAdvanceMetric.putString("value", String.valueOf(snapshot.getTimingAdvance()));
                    timingAdvanceMetric.putString("iconKey", "timingAdvance");
                    metricsList.add(timingAdvanceMetric);

                    dataMap.putDataMapArrayList("metrics", metricsList);
                } else {
                    dataMap.putLong("timestamp", System.currentTimeMillis());
                }
            }

            Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent());
        }
    }
}