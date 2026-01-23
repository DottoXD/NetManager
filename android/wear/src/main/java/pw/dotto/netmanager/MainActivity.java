package pw.dotto.netmanager;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.TextView;

import com.google.android.gms.wearable.DataClient;
import com.google.android.gms.wearable.DataEvent;
import com.google.android.gms.wearable.DataEventBuffer;
import com.google.android.gms.wearable.DataMap;
import com.google.android.gms.wearable.DataMapItem;
import com.google.android.gms.wearable.Node;
import com.google.android.gms.wearable.Wearable;

public class MainActivity extends Activity implements DataClient.OnDataChangedListener {
    private Handler pollingHandler;
    private int currentSim = 0;
    private TextView networkName, signalText, infoText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);

        networkName = findViewById(R.id.network_name);
        signalText = findViewById(R.id.signal_text);
        infoText = findViewById(R.id.info_text);

        findViewById(R.id.root_layout).setOnClickListener(v -> {
            currentSim = (currentSim == 0) ? 1 : 0;
            requestWearOSData();
        });

        pollingHandler = new Handler(Looper.getMainLooper());
    }

    private final Runnable pollRunnable = new Runnable() {
        @Override
        public void run() {
            requestWearOSData();
            pollingHandler.postDelayed(this, 3000);
        }
    };

    @Override
    protected void onResume() {
        super.onResume();
        Wearable.getDataClient(this).addListener(this);
        pollingHandler.post(pollRunnable);
    }

    @Override
    protected void onPause() {
        super.onPause();
        Wearable.getDataClient(this).removeListener(this);
        pollingHandler.removeCallbacks(pollRunnable);
    }

    private void requestWearOSData() {
        Wearable.getNodeClient(this).getConnectedNodes().addOnSuccessListener(nodes -> {
            byte[] payload = new byte[] { (byte) currentSim };

            Log.d("wear", "Detected nodes: " + nodes.size());

            for (Node node : nodes) {
                Wearable.getMessageClient(this).sendMessage(node.getId(), "/request_wearos_data", payload);
            }
        });
    }

    @Override
    public void onDataChanged(DataEventBuffer dataEventBuffer) {
        for (DataEvent dataEvent : dataEventBuffer) {
            String path = dataEvent.getDataItem().getUri().getPath();
            if (path == null)
                continue;

            if (dataEvent.getType() == DataEvent.TYPE_CHANGED
                    && path.startsWith("/wearos_data")) {
                DataMap map = DataMapItem.fromDataItem(dataEvent.getDataItem()).getDataMap();
                updateUI(map);
            }
        }
    }

    private void updateUI(DataMap map) {
        int simId = map.getInt("id", -1);
        if (simId != currentSim)
            return;

        runOnUiThread(() -> {
            networkName.setText(map.getString("network") + " (SIM " + currentSim + ")");
            signalText.setText(map.getInt("processedSignal") + "dBm");
            infoText.setText(String.format("Band " + map.getInt("band") + " - " + map.getInt("networkGen") + "G"));
        });
    }
}
