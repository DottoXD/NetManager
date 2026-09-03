package pw.dotto.netmanager.utils

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BarChart
import androidx.compose.material.icons.rounded.CellTower
import androidx.compose.material.icons.rounded.Landscape
import androidx.compose.material.icons.rounded.Lightbulb
import androidx.compose.material.icons.rounded.PermIdentity
import androidx.compose.material.icons.rounded.SettingsInputAntenna
import androidx.compose.material.icons.rounded.Shortcut
import androidx.compose.material.icons.rounded.SignalCellularAlt
import androidx.compose.material.icons.rounded.SpatialTracking
import androidx.compose.material.icons.rounded.WifiChannel
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.wear.compose.material3.MaterialTheme


class Calculations {
    companion object {
        fun signalFraction(dbm: Int, gen: Int): Float {
            val (minDbm, maxDbm) = when (gen) {
                5, 4 -> -140 to -44
                3 -> -120 to -60
                2 -> -110 to -50
                else -> -120 to -50
            }

            val clamped = dbm.coerceIn(minDbm, maxDbm)
            return (clamped - minDbm).toFloat() / (maxDbm - minDbm).toFloat()
        }

        fun genLabel(gen: Int): String = when (gen) {
            5 -> "5G"
            4 -> "4G"
            3 -> "3G"
            2 -> "2G"
            else -> "-"
        }

        @Composable
        fun genToneColor(gen: Int): Color = when (gen) {
            5 -> MaterialTheme.colorScheme.primary
            4 -> MaterialTheme.colorScheme.secondary
            3 -> MaterialTheme.colorScheme.tertiary
            else -> MaterialTheme.colorScheme.outline
        }

        @Composable
        fun mapKeyToIcon(key: String): ImageVector {
            return when (key) {
                "networkType" -> Icons.Rounded.CellTower
                "rawSignal" -> Icons.Rounded.SignalCellularAlt
                "areaCode" -> Icons.Rounded.Landscape
                "stationIdentity" -> Icons.Rounded.PermIdentity
                "channelNumber" -> Icons.Rounded.WifiChannel
                "signalNoise" -> Icons.Rounded.SpatialTracking
                "channelQuality" -> Icons.Rounded.Lightbulb
                "signalQuality" -> Icons.Rounded.SettingsInputAntenna
                "timingAdvance" -> Icons.Rounded.Shortcut
                else -> Icons.Rounded.BarChart
            }
        }

        fun isValidString(value: String): Boolean {
            return !((value.contains("-1") && (!value.endsWith("dB") && !value.contains("dB"))) || value.contains(
                "2147483647"
            ) || value.contains("268435455") || value.contains("null") || value.contains("-1dBm") || value.trim() == "0.0" || value.trim() == "-")
        }

        fun isValidSignal(dbm: Int): Boolean {
            return dbm != Int.MAX_VALUE && dbm != 268435455 && dbm != -1 && dbm != 0
        }
    }
}