import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/types/recording/record.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/types/recording/recorded_data.dart';

class RecordCard extends StatelessWidget {
  final Record? selectedRecord;
  final List<Record> liveRecords;
  final RecordedData? activeReplayData;
  final VoidCallback onClose;

  const RecordCard({
    super.key,
    required this.selectedRecord,
    required this.liveRecords,
    required this.activeReplayData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    if (selectedRecord == null) return const SizedBox.shrink();

    final record = selectedRecord!;
    int index = _getIndex();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Padding(
        key: ValueKey(record.dateTime.toString()),
        padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).colorScheme.secondaryContainer
              .withAlpha(200),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${index >= 0 ? "${appLocalizations.mapRecord} #$index - " : ""}${record.networkGen < 2 ? "N/A" : "${record.networkGen}G"}",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_outlined, size: 24),
                      tooltip: appLocalizations.closeMapRecord,
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await HapticService().triggerHaptic(
                          HapticType.selection,
                          context,
                        );

                        onClose();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations.mapSignalStrength,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appLocalizations.mapTimestamp,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          if (!record.usable) ...[
                            const SizedBox(height: 2),
                            Text(
                              appLocalizations.mapPingTimeout,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${record.processedSignal}dBm",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat("dd/MM/yyyy HH:mm:ss")
                              .format(record.dateTime.toLocal()),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getIndex() {
    if (selectedRecord == null) return -1;

    if (liveRecords.isNotEmpty) return liveRecords.indexOf(selectedRecord!);

    if (activeReplayData != null && activeReplayData!.records.isNotEmpty) {
      return activeReplayData!.records.indexOf(selectedRecord!);
    }

    return -1;
  }
}
