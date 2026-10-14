import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class ImsLogsPage extends StatefulWidget {
  final ValueListenable<List<dynamic>> logs;

  const ImsLogsPage({super.key, required this.logs});

  @override
  State<ImsLogsPage> createState() => _ImsLogsPageState();
}

class _ImsLogsPageState extends State<ImsLogsPage>
    with AutomaticKeepAliveClientMixin {
  static const List<String> _filters = [
    "ALL",
    "REGISTRATION",
    "HANDOVER",
    "MMTEL",
    "RCS",
    "IWLAN/ePDG",
    "WARNING",
    "IMS_EVENT",
  ];

  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _filter = ValueNotifier("ALL");
  final ValueNotifier<String> _query = ValueNotifier("");
  late final Listenable _listChanged = Listenable.merge([
    widget.logs,
    _filter,
    _query,
  ]);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _filter.dispose();
    _query.dispose();
    super.dispose();
  }

  List<dynamic> _filtered() {
    final logs = widget.logs.value;
    final filter = _filter.value;
    final query = _query.value.toLowerCase();
    final result = <dynamic>[];

    for (int i = logs.length - 1; i >= 0; i--) {
      final log = logs[i];

      if (filter != "ALL" &&
          (log["type"] ?? "").toString().toUpperCase() != filter) {
        continue;
      }
      if (query.isNotEmpty &&
          !(log["message"] ?? "").toString().toLowerCase().contains(query)) {
        continue;
      }

      result.add(log);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: ValueListenableBuilder<String>(
            valueListenable: _query,
            builder: (context, query, _) => SearchBar(
              controller: _searchController,
              hintText: appLocalizations.advancedModeImsLogsSearch,
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
        ),
        SizedBox(
          height: 38,
          child: ValueListenableBuilder<String>(
            valueListenable: _filter,
            builder: (context, current, _) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final filter = _filters[i];
                final isSelected = current == filter;

                return FilterChip(
                  label: Text(
                    filter == "ALL" ? appLocalizations.advancedModeAll : filter,
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
                    if (selected) _filter.value = filter;
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: _listChanged,
            builder: (context, _) {
              final logs = _filtered();
              if (logs.isEmpty) {
                return Center(
                  child: Text(
                    appLocalizations.advancedModeImsLogsEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 64),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _LogEntry(log: logs[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LogEntry extends StatelessWidget {
  final dynamic log;

  const _LogEntry({required this.log});

  (Color bg, Color fg) _typeColors(String type, ThemeData theme) {
    switch (type) {
      case "REGISTRATION":
        return (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        );
      case "HANDOVER":
      case "MMTEL":
        return (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        );
      case "RCS":
      case "IWLAN/ePDG":
        return (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
        );
      case "WARNING":
        return (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        );
      default:
        return (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String time = log["time"] ?? "Now";
    final String type = log["type"] ?? "IMS";
    final String msg = log["message"] ?? "";
    final (chipBg, chipFg) = _typeColors(type, theme);

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
                  type,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: chipFg,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: "monospace",
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            style: theme.textTheme.bodyMedium?.copyWith(
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
