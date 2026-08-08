import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:netmanager/components/dialogs/error.dart';
import 'package:netmanager/components/dialogs/speedtest_detail.dart';
import 'package:netmanager/database/speedtest_database.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:netmanager/utils/format_utils.dart';
import 'package:netmanager/utils/gen_color.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/speed_methods.dart';

class SpeedtestHistoryModal extends StatefulWidget {
  const SpeedtestHistoryModal({
    super.key,
    required this.platform,
    required this.speedMeasurementUnitNotifier,
  });

  final MethodChannel platform;
  final ValueNotifier<int> speedMeasurementUnitNotifier;

  @override
  State<SpeedtestHistoryModal> createState() => _SpeedtestHistoryModalState();
}

class _SpeedtestHistoryModalState extends State<SpeedtestHistoryModal> {
  late Future<List<SpeedtestHistoryResult>> _speedtestResults;

  @override
  void initState() {
    super.initState();
    _speedtestResults = SpeedtestDatabase.fetchHistory();
  }

  void _refresh() {
    setState(() {
      _speedtestResults = SpeedtestDatabase.fetchHistory();
    });
  }

  Future<void> _delete(int id) async {
    await SpeedtestDatabase.deleteResult(id);

    _refresh();
  }

  Future<void> _importHistory() async {
    final appLocalizations = AppLocalizations.of(context)!;

    const XTypeGroup typeGroup = XTypeGroup(
      label: "Speed test history",
      extensions: ["csv"],
    );

    final XFile? selectedFile = await openFile(acceptedTypeGroups: [typeGroup]);
    if (selectedFile == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(appLocalizations.speedtestImportingHistory)),
          ],
        ),
      ),
    );

    try {
      const separator = ",";
      final String content = await selectedFile.readAsString();
      final List<String> lines = content
          .split(RegExp(r"\r\n|\n"))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        throw FormatException(appLocalizations.speedtestImportNoValidRows);
      }

      final List<String> firstRowFields = decodeRow(lines.first, separator);
      final bool firstRowIsHeader =
          firstRowFields.isEmpty ||
          DateTime.tryParse(firstRowFields.first) == null;
      final int startIndex = firstRowIsHeader ? 1 : 0;

      final List<SpeedtestHistoryResult> parsed = [];
      for (int i = startIndex; i < lines.length; i++) {
        try {
          if (mounted) {
            parsed.add(
              SpeedtestHistoryResult.fromCsvFields(
                decodeRow(lines[i], separator),
                context,
              ),
            );
          }
        } catch (_) {
          continue;
        }
      }

      if (parsed.isEmpty) {
        throw FormatException(appLocalizations.speedtestImportNoValidRows);
      }

      await SpeedtestDatabase.insertAll(parsed);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalizations.speedtestImportSuccess(parsed.length),
            ),
          ),
        );
      }

      _refresh();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) {
            return ErrorDialog(
              e: "${appLocalizations.speedtestImportHistory}: $e",
            );
          },
        );
      }
    }
  }

  Future<void> _exportHistory() async {
    final appLocalizations = AppLocalizations.of(context)!;

    final List<SpeedtestHistoryResult> results =
        await SpeedtestDatabase.fetchHistory();

    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.speedtestNoHistory)),
      );
      return;
    }

    final String? directoryPath = await getDirectoryPath();
    if (directoryPath == null) return;

    const separator = ",";
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(encodeRow(SpeedtestHistoryResult.csvHeader, separator));
    for (final result in results) {
      buffer.writeln(encodeRow(result.toCsvFields(), separator));
    }

    final String fileName =
        "NetManager_Speedtests_${DateTime.now().millisecondsSinceEpoch}.csv";
    final File file = File("$directoryPath/$fileName");

    try {
      await file.writeAsString(buffer.toString());
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return ErrorDialog(
              e: "${appLocalizations.speedtestExportHistory}: $e",
            );
          },
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appLocalizations.speedtestExportSuccess(results.length),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () async {
                    await HapticService().triggerHaptic(
                      HapticType.selection,
                      context,
                    );

                    await _importHistory();
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  tooltip: appLocalizations.speedtestImportHistory,
                ),
                IconButton(
                  onPressed: () async {
                    await HapticService().triggerHaptic(
                      HapticType.selection,
                      context,
                    );

                    await _exportHistory();
                  },
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: appLocalizations.speedtestExportHistory,
                ),
                FutureBuilder<List<SpeedtestHistoryResult>>(
                  future: _speedtestResults,
                  builder: (context, snapshot) {
                    final hasResults = (snapshot.data ?? []).isNotEmpty;
                    if (!hasResults) return const SizedBox.shrink();

                    return IconButton(
                      onPressed: () async {
                        await HapticService().triggerHaptic(
                          HapticType.selection,
                          context,
                        );

                        if (!context.mounted) return;

                        final bool? confirmed = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                appLocalizations.speedtestClearHistory,
                              ),
                              content: Text(
                                appLocalizations
                                    .speedtestClearHistoryConfirmation,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(appLocalizations.cancel),
                                ),
                                FilledButton.icon(
                                  icon: const Icon(
                                    Icons.cleaning_services_outlined,
                                  ),
                                  label: Text(
                                    appLocalizations.speedtestClearHistory,
                                  ),
                                  onPressed: () async {
                                    await HapticService().triggerHaptic(
                                      HapticType.selection,
                                      context,
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          await SpeedtestDatabase.clearHistory();
                          _refresh();
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: appLocalizations.speedtestClearHistory,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<SpeedtestHistoryResult>>(
              future: _speedtestResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = snapshot.data ?? [];

                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 40,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appLocalizations.speedtestNoHistory,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ValueListenableBuilder<int>(
                  valueListenable: widget.speedMeasurementUnitNotifier,
                  builder: (context, unitIndex, child) {
                    final String unitLabel = getUnitString(unitIndex);

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final result = results[i];
                        final genColor = getGenColor(
                          context,
                          result.networkGen,
                        );

                        return Dismissible(
                          key: ValueKey(result.id ?? i),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Icon(
                              Icons.delete_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            await HapticService().triggerHaptic(
                              HapticType.light,
                              context,
                            );

                            if (result.id != null) await _delete(result.id!);

                            return true;
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: genColor.withValues(alpha: 0.15),
                              child: Text(
                                result.getNetworkGenLabel(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: genColor,
                                ),
                              ),
                            ),
                            title: Text(
                              DateFormat(
                                "dd/MM/yyyy HH:mm:ss",
                              ).format(result.timestamp),
                            ),
                            subtitle: Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward_outlined,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "${formatSpeed(result.download, unitIndex)} $unitLabel",
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_upward_outlined,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "${formatSpeed(result.upload, unitIndex)} $unitLabel",
                                ),
                                if (result.hasLocation()) ...[
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_outlined),
                            onTap: () async {
                              await HapticService().triggerHaptic(
                                HapticType.selection,
                                context,
                              );

                              if (!context.mounted) return;

                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SpeedtestDetailDialog(
                                    platform: widget.platform,
                                    speedtestResult: result,
                                    unitIndex: unitIndex,
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
