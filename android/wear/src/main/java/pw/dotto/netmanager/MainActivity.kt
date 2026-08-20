package pw.dotto.netmanager

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.dynamicColorScheme
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMap
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import pw.dotto.netmanager.types.CellData
import pw.dotto.netmanager.types.NetworkMetric
import pw.dotto.netmanager.ui.screens.network.NetworkScreen

/**
 * NetManager's WearOS MainActivity class is the core of the app's WearOS
 * bridge.
 * This class currently handles all of WearOS NetManager's interactions with the
 * main app.
 *
 * @author DottoXD
 * @version 0.1.1
 */
class MainActivity : ComponentActivity(), DataClient.OnDataChangedListener {
    private val cellDataState = mutableStateOf(CellData())
    private val simCountState = mutableIntStateOf(1)
    private var currentSim = 0
    private var knownSimSlotIds: List<Int> = listOf(0)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        lifecycleScope.launch {
            lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
                while (true) {
                    requestWearOSData()
                    delay(POLL_INTERVAL_MS)
                }
            }
        }

        setContent {
            MaterialTheme(colorScheme = dynamicColorScheme(this) ?: ColorScheme()) {
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
    }

    override fun onPause() {
        super.onPause()
        Wearable.getDataClient(this).removeListener(this)
    }

    private fun requestWearOSData() {
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes: List<Node> ->
            val payload = byteArrayOf(currentSim.toByte())
            nodes.forEach { node ->
                Wearable.getMessageClient(this).sendMessage(node.id, PATH_REQUEST, payload)
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

        val slotIds = map.getIntegerArrayList("simSlotIds")?.toList() ?: emptyList()
        if (slotIds.isNotEmpty()) {
            knownSimSlotIds = slotIds

            if (currentSim !in slotIds) {
                currentSim = slotIds.first()
                requestWearOSData()
                return
            }
        }

        if (simId != currentSim) return

        val totalSims = map.getInt("simCount", 1)
        simCountState.intValue = totalSims

        val serializedMetrics = map.getDataMapArrayList("metrics") ?: ArrayList()
        val parsedMetrics = serializedMetrics.map { metricMap ->
            NetworkMetric(
                label = metricMap.getString("label", "Unknown"),
                value = metricMap.getString("value", "N/A"),
                iconKey = metricMap.getString("iconKey", "default")
            )
        }

        cellDataState.value = CellData(
            simId = simId,
            network = map.getString("network", ""),
            node = map.getString("node", ""),
            band = map.getInt("band", 0),
            networkGen = map.getInt("networkGen", 0),
            processedSignal = map.getInt("processedSignal", 0),
            timestamp = map.getLong("timestamp", 0L),
            metrics = parsedMetrics
        )
    }

    private fun switchSim() {
        val ids = knownSimSlotIds

        currentSim = when {
            ids.size > 1 -> {
                val idx = ids.indexOf(currentSim)
                ids[(idx + 1) % ids.size]
            }

            ids.isNotEmpty() -> ids.first()
            else -> 0
        }
        requestWearOSData()
    }

    companion object {
        private const val PATH_REQUEST = "/request_wearos_data"
        private const val PATH_RESPONSE = "/wearos_data"
        private const val POLL_INTERVAL_MS = 3000L
    }
}