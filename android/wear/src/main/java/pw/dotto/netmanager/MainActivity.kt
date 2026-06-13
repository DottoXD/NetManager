package pw.dotto.netmanager

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.wear.compose.material3.MaterialTheme
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable

/**
 * NetManager's WearOS MainActivity class is the core of the app's WearOS
 * bridge.
 * This class currently handles all of WearOS NetManager's interactions with the
 * main app.
 *
 * @author DottoXD
 * @version 0.0.5
 */
class MainActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private val cellDataState = mutableStateOf(CellData())
    private val simCountState = mutableIntStateOf(1)
    private var currentSim = 0

    private val pollingHandler = Handler(Looper.getMainLooper())
    private val pollRunnable = object : Runnable {
        override fun run() {
            requestWearOSData()
            pollingHandler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            MaterialTheme {
                val data by cellDataState
                val simCount by simCountState

                NetworkScreen(
                    data = data,
                    simCount = simCount,
                    onSwitchSim = ::switchSim,
                )
            }
        }
    }

    override fun onResume() {
        super.onResume()
        Wearable.getDataClient(this).addListener(this)
        pollingHandler.post(pollRunnable)
    }

    override fun onPause() {
        super.onPause()
        Wearable.getDataClient(this).removeListener(this)
        pollingHandler.removeCallbacks(pollRunnable)
    }

    private fun requestWearOSData() {
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes: List<Node> ->
                val payload = byteArrayOf(currentSim.toByte())
                nodes.forEach { node ->
                    Wearable.getMessageClient(this)
                        .sendMessage(node.id, PATH_REQUEST, payload)
                }
            }
    }

    override fun onDataChanged(buffer: DataEventBuffer) {
        for (event in buffer) {
            val path = event.dataItem.uri.path ?: continue
            if (event.type == DataEvent.TYPE_CHANGED && path.startsWith(PATH_RESPONSE)) {
                val map = DataMapItem.fromDataItem(event.dataItem).dataMap
                updateState(map)
            }
        }
    }

    private fun updateState(map: DataMap) {
        val simId = map.getInt("id", -1)
        if (simId != currentSim) return

        cellDataState.value = CellData(
            simId = simId,
            network = map.getString("network", ""),
            node = map.getString("node", ""),
            band = map.getInt("band", 0),
            networkGen = map.getInt("networkGen", 0),
            rawSignal = map.getInt("rawSignal", 0),
            processedSignal = map.getInt("processedSignal", 0),
            timestamp = map.getLong("timestamp", 0L),
        )
    }

    private fun switchSim() {
        currentSim = if (currentSim == 0) 1 else 0
        requestWearOSData()
    }

    companion object {
        private const val PATH_REQUEST = "/request_wearos_data"
        private const val PATH_RESPONSE = "/wearos_data"
        private const val POLL_INTERVAL_MS = 3_000L
    }
}