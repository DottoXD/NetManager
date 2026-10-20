import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/diag_hub.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class DiagUtilsPage extends StatefulWidget {
  final ValueListenable<int> simSlotNotifier;

  const DiagUtilsPage({super.key, required this.simSlotNotifier});

  @override
  State<DiagUtilsPage> createState() => _DiagUtilsPageState();
}

class _DiagUtilsPageState extends State<DiagUtilsPage> {
  static const MethodChannel _methodChn = MethodChannel(
    "pw.dotto.netmanager/diag",
  );

  static const List<String> _logFilters = [
    "ALL",
    "STATUS",
    "LTE MEAS",
    "CELL INFO",
    "BEARER",
    "ERROR",
    "DISCONNECT",
  ];

  final DiagHub _hub = DiagHub.instance;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _logFilter = ValueNotifier("ALL");
  final ValueNotifier<String> _query = ValueNotifier("");
  final ValueNotifier<bool> _stopping = ValueNotifier(false);

  late final Listenable _statusChanged = Listenable.merge([
    _hub.connState,
    _hub.lastError,
    _hub.status,
    _stopping,
  ]);
  late final Listenable _logChanged = Listenable.merge([
    _hub.logRevision,
    widget.simSlotNotifier,
    _logFilter,
    _query,
  ]);

  List<DiagLogEntry> _filteredLog() {
    final slot = widget.simSlotNotifier.value;
    final filter = _logFilter.value;
    final query = _query.value.toLowerCase();
    final result = <DiagLogEntry>[];

    for (final entry in _hub.log) {
      final entrySlot = entry.slot;
      if (entrySlot != null && entrySlot != slot) continue;
      if (filter != "ALL" && entry.type.toUpperCase() != filter) continue;
      if (query.isNotEmpty && !entry.lowerMessage.contains(query)) continue;
      result.add(entry);
    }

    return result;
  }

  Future<void> _confirmStop() async {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.stop_circle_outlined),
        title: Text(appLocalizations.advancedModeDiagStopTitle),
        content: Text(
          appLocalizations.advancedModeDiagStopDescription,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              await HapticService().triggerHaptic(
                HapticType.selection,
                context,
              );

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            icon: const Icon(Icons.close_outlined),
            label: Text(appLocalizations.advancedModeDiagStop),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _stopping.value = true;
    bool stopped = false;

    try {
      stopped = await _methodChn.invokeMethod<bool>("stopDaemon") ?? false;
    } on PlatformException catch (e) {
      if (mounted) {
        _hub.pushLog("ERROR", e.message ?? "", code: DiagLogCode.stopFailed);
      }
    } finally {
      if (mounted) {
        _hub.pushLog(
          "STATUS",
          "",
          code: stopped ? DiagLogCode.stopped : DiagLogCode.stopUnconfirmed,
        );
        _stopping.value = false;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _logFilter.dispose();
    _query.dispose();
    _stopping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: _statusChanged,
              builder: (context, _) => _buildStatusCard(context),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(child: _buildLogHeader(context)),
        ),
        ListenableBuilder(
          listenable: _logChanged,
          builder: (context, _) {
            final logs = _filteredLog();
            if (logs.isEmpty) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        appLocalizations.advancedModeDiagLogsEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
              sliver: SliverList.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LogEntry(entry: logs[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final connState = _hub.connState.value;
    final status = _hub.status.value;

    final String label;
    final IconData icon;
    final Color bg;
    final Color fg;

    switch (connState) {
      case DiagConnState.connecting:
        label = appLocalizations.advancedModeDiagConnecting;
        icon = Icons.sync_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.connected:
        final vendor = status?["vendor"] as String?;
        final transport = status?["transport"] as String?;
        label = (vendor != null && transport != null)
            ? appLocalizations.advancedModeDiagConnectedVia(vendor, transport)
            : appLocalizations.advancedModeDiagConnected;
        icon = Icons.check_circle_outlined;
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        break;
      case DiagConnState.disconnected:
        label = appLocalizations.advancedModeDiagDisconnecting;
        icon = Icons.link_off_outlined;
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
      case DiagConnState.error:
        label = _hub.lastError.value ?? appLocalizations.advancedModeDiagError;
        icon = Icons.error_outlined;
        bg = theme.colorScheme.errorContainer;
        fg = theme.colorScheme.onErrorContainer;
        break;
    }

    final canStop =
        connState == DiagConnState.connected ||
        connState == DiagConnState.error;
    final stopping = _stopping.value;

    return InfoCard(
      title: appLocalizations.advancedModeDiagCardTitle,
      icon: Icons.settings_phone_outlined,
      trailing: canStop
          ? IconButton(
              tooltip: appLocalizations.advancedModeDiagStopTooltip,
              icon: stopping
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.error,
                      ),
                    )
                  : Icon(
                      Icons.stop_circle_outlined,
                      color: theme.colorScheme.error,
                    ),
              onPressed: stopping ? null : _confirmStop,
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildLogHeader(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.list_alt_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appLocalizations.advancedModeDiagEventLog,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String>(
          valueListenable: _query,
          builder: (context, query, _) => SearchBar(
            controller: _searchController,
            hintText: appLocalizations.advancedModeDiagLogsSearch,
            leading: Icon(
              Icons.search_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            trailing: query.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.close_outlined),
                      onPressed: () {
                        _searchController.clear();
                        _query.value = "";
                      },
                    ),
                  ],
            onChanged: (v) => _query.value = v,
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerHigh,
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ValueListenableBuilder<String>(
            valueListenable: _logFilter,
            builder: (context, current, _) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _logFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _logFilters[i];
                final isSelected = current == f;
                return FilterChip(
                  label: Text(
                    f == "ALL" ? appLocalizations.advancedModeAll : f,
                  ),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  side: BorderSide.none,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  selectedColor: theme.colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (selected) {
                    if (selected) _logFilter.value = f;
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LogEntry extends StatelessWidget {
  final DiagLogEntry entry;

  const _LogEntry({required this.entry});

  (Color bg, Color fg) _typeColors(String type, ThemeData theme) {
    switch (type) {
      case "LTE MEAS":
      case "CELL INFO":
      case "BEARER":
        return (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        );
      case "STATUS":
        return (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        );
      case "ERROR":
        return (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        );
      case "DISCONNECT":
        return (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
        );
      default:
        return (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  String _message(AppLocalizations appLocalizations) {
    switch (entry.code) {
      case DiagLogCode.disconnected:
        return appLocalizations.advancedModeDiagLogsDisconnected;
      case DiagLogCode.unknownError:
        return appLocalizations.advancedModeDiagLogsUnknownError;
      case DiagLogCode.stopFailed:
        return appLocalizations.advancedModeDiagLogStopFailed(entry.message);
      case DiagLogCode.stopped:
        return appLocalizations.advancedModeDiagLogStopped;
      case DiagLogCode.stopUnconfirmed:
        return appLocalizations.advancedModeDiagLogStopUnconfirmed;
      case null:
        return entry.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final (chipBg, chipFg) = _typeColors(entry.type, theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  entry.type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: chipFg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                entry.time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: "monospace",
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _message(appLocalizations),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: "monospace",
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
