package pw.dotto.netmanager.ui.screens.network.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material3.*
import pw.dotto.netmanager.types.CellData
import pw.dotto.netmanager.utils.Calculations.Companion.genToneColor
import pw.dotto.netmanager.utils.Calculations.Companion.isValidString
import pw.dotto.netmanager.utils.Calculations.Companion.mapKeyToIcon

@Composable
fun DetailSheet(
    data: CellData,
) {
    val listState = rememberScalingLazyListState()
    val arcColor = genToneColor(data.networkGen)

    val validMetrics = remember(data.metrics) {
        data.metrics.filter { metric ->
            isValidString(metric.label) && isValidString(metric.value)
        }
    }

    AppScaffold {
        ScreenScaffold(
            scrollState = listState, scrollIndicator = { ScrollIndicator(listState) }) {
            ScalingLazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                item {
                    ExpressiveHeader(text = "Details", accentColor = arcColor)
                }

                items(validMetrics) { metric ->
                    ExpressiveDetailCard(
                        label = metric.label,
                        value = metric.value,
                        iconKey = metric.iconKey,
                        accentColor = arcColor,
                    )
                }
            }
        }
    }
}

@Composable
private fun ExpressiveHeader(
    text: String,
    accentColor: Color,
    modifier: Modifier = Modifier,
) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Black),
        color = accentColor,
        modifier = modifier.padding(bottom = 10.dp),
    )
}

@Composable
private fun ExpressiveDetailCard(
    label: String,
    value: String,
    iconKey: String,
    accentColor: Color,
    modifier: Modifier = Modifier,
) {
    val colorScheme = MaterialTheme.colorScheme
    val typography = MaterialTheme.typography

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(colorScheme.surfaceContainer)
            .padding(horizontal = 10.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(30.dp)
                .clip(CircleShape)
                .background(accentColor.copy(alpha = 0.18f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = mapKeyToIcon(iconKey),
                contentDescription = label,
                tint = accentColor,
                modifier = Modifier.size(16.dp)
            )
        }

        Text(
            text = label,
            style = typography.labelMedium,
            color = colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(1f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )

        Text(
            text = value,
            style = typography.labelMedium.copy(fontWeight = FontWeight.ExtraBold),
            color = accentColor,
            textAlign = TextAlign.End,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}