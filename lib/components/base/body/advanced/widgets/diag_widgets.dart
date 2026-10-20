import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class DiagBanner extends StatelessWidget {
  final DiagConnState state;
  final String? error;

  const DiagBanner({super.key, required this.state, required this.error});

  @override
  Widget build(BuildContext context) {
    if (state == DiagConnState.connected) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    final String label;
    final IconData icon;
    final Color bg;
    final Color fg;

    switch (state) {
      case DiagConnState.connecting:
        label = appLocalizations.advancedModeDiagConnecting;
        icon = Icons.sync_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.disconnected:
        label = appLocalizations.advancedModeDiagDisconnected;
        icon = Icons.link_off_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.error:
        label = error ?? appLocalizations.advancedModeDiagError;
        icon = Icons.error_outlined;
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        break;
      case DiagConnState.connected:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  final double? width;

  const DiagMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = "",
    this.width = 148,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
