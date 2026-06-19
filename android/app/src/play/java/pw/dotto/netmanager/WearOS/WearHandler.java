package pw.dotto.netmanager.WearOS;

import android.content.Context;
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

/**
 * NetManager's WearHandler Play class is the core component of the Android <->
 * WearOS bridge for NetManager.
 *
 * @author DottoXD
 * @version 0.0.5
 */
public class WearHandler implements WearIntegration, MessageClient.OnMessageReceivedListener {
    private Context context;
    private Manager core;

    @Override
    public void onCreate(Context context) {
        this.context = context;

        if (context instanceof MainActivity) {
            this.core = ((MainActivity) context).getCore();
        }
    }

    @Override
    public void onResume() {
        Wearable.getMessageClient(context).addListener(this);
    }

    @Override
    public void onPause() {
        Wearable.getMessageClient(context).removeListener(this);
    }

    @Override
    public void onDestroy() {
        if (context != null) {
            Wearable.getMessageClient(context).removeListener(this);
        }

        this.context = null;
        this.core = null;
    }

    /**
     * This method coordinates incoming communications with WearOS devices.
     *
     * @param messageEvent A valid MessageEvent from a WearOS device.
     */
    @Override
    public void onMessageReceived(@NonNull MessageEvent messageEvent) {
        Log.d("wear", "Message received: " + messageEvent.getPath());
        if (messageEvent.getPath().equals("/request_wearos_data")) {
            PutDataMapRequest request = PutDataMapRequest.create("/wearos_data");

            DataMap dataMap = request.getDataMap();

            byte[] data = messageEvent.getData();
            int id = data.length > 0 ? data[0] : 0;

            dataMap.putInt("id", id);

            if (core != null) {
                CellSnapshot snapshot = core.getCellSnapshot(id);

                if (snapshot != null) {
                    int gen = snapshot.getNetworkGen();

                    dataMap.putString("network", snapshot.getNetwork());
                    dataMap.putString("node", snapshot.getNode());
                    dataMap.putInt("band", snapshot.getBand());
                    dataMap.putInt("networkGen", gen);
                    dataMap.putInt("processedSignal", snapshot.getProcessedSignal());
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
                }
            }

            Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent());
        }
    }

    private String getGenerationLabel(int gen) {
        return switch (gen) {
            case 5 -> "5G NR";
            case 4 -> "4G LTE";
            case 3 -> "3G";
            case 2 -> "2G";
            default -> "N/A";
        };
    }
}