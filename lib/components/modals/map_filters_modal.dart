import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/types/map/tower_filter.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/gen_color.dart';

class MapFilters extends StatelessWidget {
  const MapFilters({super.key, required this.filterNotifier});

  final ValueNotifier<TowerFilter> filterNotifier;

  static const int _minCellCountMinimum = 2;
  static const int _minCellCountMaximum = 20;
  static const int _defaultMinCellCount = 2;

  void _toggleGeneration(TowerFilter current, int gen) {
    final Set<int> selected = {
      ...(current.allowedGenerations ?? TowerFilter.mobileGenerations),
    };

    if (selected.contains(gen)) {
      if (selected.length == 1) return;

      selected.remove(gen);
    } else {
      selected.add(gen);
    }

    final bool isEverything =
        selected.length == TowerFilter.mobileGenerations.length;

    filterNotifier.value = current.copyWith(
      allowedGenerations: isEverything ? null : selected,
      clearAllowedGenerations: isEverything,
    );
  }

  void _toggleMinCellCount(TowerFilter current, bool enabled) {
    filterNotifier.value = enabled
        ? current.copyWith(minCellCount: _defaultMinCellCount)
        : current.copyWith(clearMinCellCount: true);
  }

  void _setMinCellCount(TowerFilter current, double value) {
    filterNotifier.value = current.copyWith(minCellCount: value.round());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: filterNotifier,
      builder: (context, filter, _) {
        final Set<int> selectedGenerations =
            filter.allowedGenerations ?? TowerFilter.mobileGenerations.toSet();
        final bool minCellCountEnabled = filter.minCellCount != null;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(appLocalizations.displayedCellTowers),
                    subtitle: Text(appLocalizations.cellTowersTechFiltering),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TowerFilter.mobileGenerations.map((gen) {
                        final bool selected = selectedGenerations.contains(gen);
                        final Color genColor = getGenColor(context, gen);

                        return FilterChip(
                          label: Text("${gen}G"),
                          tooltip: "${gen}G",
                          selected: selected,
                          showCheckmark: false,
                          avatar: selected
                              ? Icon(
                                  Icons.cell_tower_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSecondaryContainer,
                                )
                              : null,
                          selectedColor: genColor.withValues(alpha: 0.25),
                          onSelected: (_) async {
                            await HapticService().triggerHaptic(
                              HapticType.selection,
                              context,
                            );

                            _toggleGeneration(filter, gen);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(appLocalizations.minimumCellsPerTower),
                    subtitle: Text(
                      minCellCountEnabled
                          ? appLocalizations.minimumCellsFiltering(
                              filter.minCellCount ?? 2,
                            )
                          : appLocalizations.noMinimumCellsFiltering,
                    ),
                    trailing: Switch(
                      value: minCellCountEnabled,
                      onChanged: (enabled) async {
                        await HapticService().triggerHaptic(
                          HapticType.selection,
                          context,
                        );

                        _toggleMinCellCount(filter, enabled);
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: minCellCountEnabled
                        ? Slider(
                            inactiveColor: theme.colorScheme.outlineVariant,
                            value: (filter.minCellCount ?? _defaultMinCellCount)
                                .clamp(
                                  _minCellCountMinimum,
                                  _minCellCountMaximum,
                                )
                                .toDouble(),
                            min: _minCellCountMinimum.toDouble(),
                            max: _minCellCountMaximum.toDouble(),
                            label: "${filter.minCellCount}",
                            onChanged: (value) async {
                              await HapticService().triggerHaptic(
                                HapticType.selection,
                                context,
                              );

                              _setMinCellCount(filter, value);
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
