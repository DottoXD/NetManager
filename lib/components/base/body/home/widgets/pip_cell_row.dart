import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/cell_utils.dart';
import 'package:netmanager/types/cell/cell_data.dart';

class PipCellRow extends StatelessWidget {
  final CellData cell;
  final bool isPrimary;
  final bool isLikely;

  const PipCellRow({
    super.key,
    required this.cell,
    required this.isPrimary,
    required this.isLikely,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    final bandPrefix = cell.channelNumberString == "NR-ARFCN" ? "N" : "B";
    final bandStr = cell.basicCellData.band > 0
        ? "$bandPrefix${cell.basicCellData.band}"
        : "N/A";
    final signalStr = isValidInt(cell.processedSignal)
        ? "${cell.processedSignal}dBm"
        : (isValidInt(cell.rawSignal) ? "${cell.rawSignal}dBm" : "N/A");

    final borderColor = isPrimary
        ? theme.colorScheme.primary
        : (isLikely
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant);

    final primaryTextColor = isPrimary
        ? theme.colorScheme.onSurface
        : (isLikely
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface);

    final accentColor = isPrimary
        ? theme.colorScheme.primary
        : (isLikely ? theme.colorScheme.outline : theme.colorScheme.secondary);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor, width: isPrimary ? 1.5 : 1.0),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$bandStr  ",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    TextSpan(
                      text:
                          "${isValidString(cell.cellIdentifier) ? cell.cellIdentifier : appLocalizations.unknownCell}"
                          "${isValidInt(cell.bandwidth) && cell.bandwidth > 0 ? " (${cell.bandwidth}MHz)" : ""}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: isPrimary
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              signalStr,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
