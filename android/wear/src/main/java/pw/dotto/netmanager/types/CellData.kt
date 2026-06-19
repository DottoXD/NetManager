package pw.dotto.netmanager.types

import androidx.compose.runtime.Immutable

@Immutable
data class CellData(
    val simId: Int = 0,
    val network: String = "",
    val node: String = "",
    val band: Int = 0,
    val networkGen: Int = 0,
    val processedSignal: Int = 0,
    val timestamp: Long = 0L,
    val metrics: List<NetworkMetric> = emptyList()
)

val CellData.isPlaceholder: Boolean
    get() = timestamp == 0L