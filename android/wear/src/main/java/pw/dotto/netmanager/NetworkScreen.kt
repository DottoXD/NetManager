package pw.dotto.netmanager

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.*

data class CellData(
    val simId: Int = 0,
    val network: String = "",
    val node: String = "",
    val band: Int = 0,
    val networkGen: Int = 0,
    val rawSignal: Int = 0,
    val processedSignal: Int = 0,
    val timestamp: Long = 0L,
)

private fun signalFraction(dbm: Int, gen: Int): Float {
    val (minDbm, maxDbm) = when (gen) {
        5, 4 -> -140 to -44
        3 -> -120 to -60
        2 -> -110 to -50
        else -> -120 to -50
    }

    val clamped = dbm.coerceIn(minDbm, maxDbm)
    return (clamped - minDbm).toFloat() / (maxDbm - minDbm).toFloat()
}

private fun genLabel(gen: Int): String = when (gen) {
    5 -> "5G"
    4 -> "4G"
    3 -> "3G"
    2 -> "2G"
    else -> "-"
}

@Composable
private fun genToneColor(gen: Int): Color {
    val scheme = MaterialTheme.colorScheme
    return when (gen) {
        5 -> scheme.primary
        4 -> scheme.secondary
        3 -> scheme.tertiary
        else -> scheme.outline
    }
}

@Composable
fun NetworkScreen(
    data: CellData,
    simCount: Int,
    onSwitchSim: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colorScheme = MaterialTheme.colorScheme
    val typography = MaterialTheme.typography

    val targetFraction = signalFraction(data.processedSignal, data.networkGen)
    val animatedFraction by animateFloatAsState(
        targetValue = targetFraction,
        animationSpec = tween(durationMillis = 600, easing = EaseInOutCubic),
        label = "signalArc",
    )

    val arcColor = genToneColor(data.networkGen)
    val arcTrackColor = colorScheme.onSurfaceVariant

    Box(
        modifier = modifier
            .fillMaxSize()
            .clip(CircleShape)
            .background(colorScheme.background)
            .clickable(enabled = simCount > 1, onClick = onSwitchSim)
            .drawBehind {
                val strokeWidth = 8.dp.toPx()
                val inset = strokeWidth / 2f + 2.dp.toPx()
                val arcSize = Size(size.width - inset * 2, size.height - inset * 2)
                val topLeft = Offset(inset, inset)

                drawArc(
                    color = arcTrackColor,
                    startAngle = 130f,
                    sweepAngle = 280f,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
                )

                drawArc(
                    color = arcColor,
                    startAngle = 130f,
                    sweepAngle = 280f * animatedFraction,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round),
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(horizontal = 28.dp),
        ) {
            if (simCount > 1) {
                SimDots(
                    activeSim = data.simId,
                    color = arcColor,
                    modifier = Modifier.padding(bottom = 4.dp),
                )
            }

            AnimatedContent(
                targetState = genLabel(data.networkGen),
                label = "genBadge",
            ) { label ->
                Text(
                    text = label,
                    style = typography.displayLarge.copy(
                        fontSize = 52.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = (-1).sp,
                    ),
                    color = arcColor,
                    textAlign = TextAlign.Center,
                )
            }

            Spacer(Modifier.height(2.dp))

            Text(
                text = data.network.ifBlank { "No service" },
                style = typography.titleSmall.copy(fontWeight = FontWeight.Medium),
                color = colorScheme.onBackground,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )

            Text(
                text = if (data.processedSignal != 0) "${data.processedSignal} dBm" else "- dBm",
                style = typography.bodySmall,
                color = colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )

            Spacer(Modifier.height(8.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (data.band > 0) {
                    val prefix = if (data.networkGen == 5) "N" else "B"

                    InfoChip(
                        label = "$prefix${data.band}",
                        containerColor = colorScheme.surfaceContainer,
                        contentColor = colorScheme.onSurface,
                    )
                }
                if (data.node.isNotBlank()) {
                    InfoChip(
                        label = data.node,
                        containerColor = colorScheme.surfaceContainer,
                        contentColor = colorScheme.onSurface,
                    )
                }
            }
        }
    }
}

@Composable
private fun InfoChip(
    label: String,
    containerColor: Color,
    contentColor: Color,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .clip(MaterialTheme.shapes.small)
            .background(containerColor)
            .padding(horizontal = 8.dp, vertical = 3.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
            color = contentColor,
            maxLines = 1,
        )
    }
}

@Composable
private fun SimDots(
    activeSim: Int,
    color: Color,
    modifier: Modifier = Modifier,
    dotSize: Dp = 5.dp,
) {
    val inactive = MaterialTheme.colorScheme.outline.copy(alpha = 0.4f)
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(2) { i ->
            Box(
                modifier = Modifier
                    .size(dotSize)
                    .clip(CircleShape)
                    .background(if (i == activeSim) color else inactive),
            )
        }
    }
}