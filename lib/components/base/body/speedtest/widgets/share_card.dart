import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:netmanager/utils/speed_methods.dart';

class SpeedtestShareCard extends StatelessWidget {
  const SpeedtestShareCard({
    super.key,
    required this.speedtestResult,
    required this.unitIndex,
  });

  final SpeedtestHistoryResult speedtestResult;
  final int unitIndex;

  static const _darkInvertFilter = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, // red
    0, -1, 0, 0, 255, // green
    0, 0, -1, 0, 255, // blue
    0, 0, 0, 1, 0,
  ]);

  Widget _mainStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _extraStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _infoLine(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = Image.asset("assets/icon.png", width: 32, height: 32);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 1,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat("dd/MM/yyyy HH:mm:ss")
                      .format(speedtestResult.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: Theme.of(context).brightness == Brightness.light
                      ? img
                      : ColorFiltered(
                          colorFilter: _darkInvertFilter,
                          child: img,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _mainStat(
                    context,
                    icon: Icons.south_outlined,
                    label: "DOWNLOAD",
                    value:
                        "${formatSpeed(speedtestResult.download, unitIndex)}${getUnitString(unitIndex)}",
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _mainStat(
                    context,
                    icon: Icons.north_outlined,
                    label: "UPLOAD",
                    value:
                        "${formatSpeed(speedtestResult.upload, unitIndex)}${getUnitString(unitIndex)}",
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _extraStat(
                  context,
                  icon: Icons.podcasts_outlined,
                  label: "PING",
                  value: "${speedtestResult.ping}ms",
                ),
                _extraStat(
                  context,
                  icon: Icons.graphic_eq_outlined,
                  label: "JITTER",
                  value: "${speedtestResult.jitter}ms",
                ),
                _extraStat(
                  context,
                  icon: Icons.signal_cellular_alt_outlined,
                  label: "LOSS",
                  value: "${speedtestResult.packetLoss.toStringAsFixed(1)}%",
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            _infoLine(
              context,
              icon: Icons.sim_card_outlined,
              text:
                  "${speedtestResult.carrier} (${speedtestResult.plmn}) - ${speedtestResult.getNetworkGenLabel()}",
            ),
            if (speedtestResult.serverName != null) ...[
              const SizedBox(height: 4),
              _infoLine(
                context,
                icon: Icons.dns_outlined,
                text: speedtestResult.serverName!,
              ),
            ],
            if (speedtestResult.deviceModel != null) ...[
              const SizedBox(height: 4),
              _infoLine(
                context,
                icon: Icons.phone_android_outlined,
                text: speedtestResult.deviceModel!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
