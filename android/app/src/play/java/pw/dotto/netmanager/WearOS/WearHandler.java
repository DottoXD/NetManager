package pw.dotto.netmanager.WearOS;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.MessageClient;
import com.google.android.gms.wearable.MessageEvent;
import com.google.android.gms.wearable.PutDataMapRequest;
import com.google.android.gms.wearable.Wearable;

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
                    dataMap.putString("network", snapshot.getNetwork());
                    dataMap.putString("node", snapshot.getNode());
                    dataMap.putInt("band", snapshot.getBand());
                    dataMap.putInt("networkGen", snapshot.getNetworkGen());
                    dataMap.putInt("rawSignal", snapshot.getRawSignal());
                    dataMap.putInt("processedSignal", snapshot.getProcessedSignal());
                    dataMap.putLong("timestamp", snapshot.getTimestamp());
                }
            }

            Wearable.getDataClient(context).putDataItem(request.asPutDataRequest().setUrgent());
        }
    }
}