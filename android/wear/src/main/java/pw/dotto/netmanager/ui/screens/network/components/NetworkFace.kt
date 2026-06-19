package pw.dotto.netmanager.ui.screens.network.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.*
import pw.dotto.netmanager.types.CellData
import pw.dotto.netmanager.utils.Calculations.Companion.genLabel
import pw.dotto.netmanager.utils.Calculations.Companion.genToneColor
import pw.dotto.netmanager.utils.Calculations.Companion.signalFraction

@Composable
fun NetworkFace(
    data: CellData,
    simCount: Int,
    onSwitchSim: () -> Unit,
    onOpenDetails: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colorScheme = MaterialTheme.colorScheme
    val typography = MaterialTheme.typography
    val arcColor = genToneColor(data.networkGen)

    val animationSpec = spring<Float>(
        dampingRatio = Spring.DampingRatioMediumBouncy,
        stiffness = Spring.StiffnessMediumLow,
    )

    val animatedFraction by animateFloatAsState(
        targetValue = signalFraction(data.processedSignal, data.networkGen),
        animationSpec = animationSpec,
        label = "signalArc",
    )

    val trackColor = colorScheme.onSurfaceVariant.copy(alpha = 0.2f)

    Box(
        modifier = modifier
            .fillMaxSize()
            .clip(CircleShape)
            .background(colorScheme.background)
            .drawBehind {
                val stroke = 8.dp.toPx()
                val inset = stroke / 2f + 2.dp.toPx()
                val arcSize = Size(size.width - inset * 2, size.height - inset * 2)
                val topLeft = Offset(inset, inset)

                drawArc(
                    color = trackColor,
                    startAngle = 130f,
                    sweepAngle = 280f,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(stroke, cap = StrokeCap.Round),
                )

                drawArc(
                    color = arcColor,
                    startAngle = 130f,
                    sweepAngle = 280f * animatedFraction,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(stroke, cap = StrokeCap.Round),
                )
            },
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier
                .padding(horizontal = 28.dp)
                .padding(bottom = 24.dp),
        ) {
            if (simCount > 1) {
                Box(
                    modifier = Modifier
                        .padding(bottom = 6.dp)
                        .clip(RoundedCornerShape(50))
                        .background(colorScheme.surfaceContainerLow)
                        .clickable(onClick = onSwitchSim)
                        .padding(horizontal = 12.dp, vertical = 4.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        SimDots(
                            activeSim = data.simId,
                            color = arcColor,
                        )
                        Text(
                            text = "SIM ${data.simId + 1}",
                            style = typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                            color = colorScheme.onSurface
                        )
                    }
                }
            }

            AnimatedContent(
                targetState = genLabel(data.networkGen),
                transitionSpec = {
                    (fadeIn(tween(220)) + scaleIn(tween(220), initialScale = 0.88f)).togetherWith(
                        fadeOut(tween(180)) + scaleOut(tween(180), targetScale = 0.88f)
                    )
                },
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
                    InfoChip(
                        label = "${if (data.networkGen == 5) "N" else "B"}${data.band}",
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

        EdgeHuggingButton(
            label = "Details",
            color = arcColor,
            onClick = onOpenDetails,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

@Composable
private fun EdgeHuggingButton(
    label: String,
    color: Color,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val typography = MaterialTheme.typography

    val shape = RoundedCornerShape(
        topStart = 12.dp,
        topEnd = 12.dp,
        bottomStart = 28.dp,
        bottomEnd = 28.dp,
    )

    Box(
        modifier = modifier
            .clip(shape)
            .background(color.copy(alpha = 0.18f))
            .clickable(onClick = onClick)
            .padding(horizontal = 20.dp, vertical = 6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            style = typography.labelMedium.copy(fontWeight = FontWeight.Bold),
            color = color,
        )
    }
}