package pw.dotto.netmanager.ui.screens.network

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.SwipeToDismissBox
import pw.dotto.netmanager.types.CellData
import pw.dotto.netmanager.types.isPlaceholder
import pw.dotto.netmanager.ui.screens.network.components.DetailSheet
import pw.dotto.netmanager.ui.screens.network.components.NetworkFace

@Composable
fun NetworkScreen(
    data: CellData,
    simCount: Int,
    onSwitchSim: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var showDetails by remember { mutableStateOf(false) }

    AnimatedContent(
        targetState = data.isPlaceholder,
        transitionSpec = {
            (fadeIn(tween(400)) + scaleIn(tween(400), initialScale = 0.92f)).togetherWith(
                    fadeOut(
                        tween(300)
                    ) + scaleOut(tween(300), targetScale = 0.92f)
                )
        },
        label = "loadingToMain",
    ) { isPlaceholder ->
        if (isPlaceholder) {
            LoadingScreen(modifier)
        } else {
            if (showDetails) {
                SwipeToDismissBox(
                    onDismissed = { showDetails = false },
                    backgroundKey = "main_face",
                    contentKey = "details_sheet"
                ) { isBackground ->
                    if (isBackground) {
                        NetworkFace(
                            data = data,
                            simCount = simCount,
                            onSwitchSim = onSwitchSim,
                            onOpenDetails = {},
                            modifier = modifier,
                        )
                    } else {
                        DetailSheet(
                            data = data,
                        )
                    }
                }
            } else {
                NetworkFace(
                    data = data,
                    simCount = simCount,
                    onSwitchSim = onSwitchSim,
                    onOpenDetails = { showDetails = true },
                    modifier = modifier,
                )
            }
        }
    }
}

@Composable
private fun LoadingScreen(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center,
    ) {
        CircularProgressIndicator(modifier = Modifier.size(48.dp))
    }
}