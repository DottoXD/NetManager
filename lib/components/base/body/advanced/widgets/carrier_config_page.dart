import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class CarrierConfigPage extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>> data;

  const CarrierConfigPage({super.key, required this.data});

  static const List<String> dataKeys = [
    "nrEnabled",
    "nsaSupported",
    "saSupported",
    "volte",
    "vonr",
    "wfc",
    "vt",
    "crossSimIms",
    "emergencyWfc",
    "lteCa",
    "rcsSupported",
    "rcsSingleReg",
    "wfcWifiOnly",
    "wfcDefaultEnabled",
  ];

  static bool hasKeys(Map<String, dynamic> d) => dataKeys.any(d.containsKey);

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: data,
      builder: (context, d, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 64),
          children: [
            InfoCard(
              title: appLocalizations.advancedModeNRCapabilities,
              icon: Icons.five_g_outlined,
              child: DividedColumn(
                children: [
                  _ConfigRow(
                    title: appLocalizations.advancedModeNRAvailableTitle,
                    subtitle: appLocalizations.advancedModeNRAvailableSubtitle,
                    enabled: d["nrEnabled"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeNsaTitle,
                    subtitle: appLocalizations.advancedModeNsaSubtitle,
                    enabled: d["nsaSupported"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeSaTitle,
                    subtitle: appLocalizations.advancedModeSaSubtitle,
                    enabled: d["saSupported"] == true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: appLocalizations.advancedModeVoice,
              icon: Icons.phone_in_talk_outlined,
              child: DividedColumn(
                children: [
                  _ConfigRow(
                    title: appLocalizations.advancedModeVolteTitle,
                    subtitle: appLocalizations.advancedModeVolteSubtitle,
                    enabled: d["volte"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeVonrTitle,
                    subtitle: appLocalizations.advancedModeVonrSubtitle,
                    enabled: d["vonr"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWifiTitle,
                    subtitle: appLocalizations.advancedModeWifiSubtitle,
                    enabled: d["wfc"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeVilteTitle,
                    subtitle: appLocalizations.advancedModeVilteSubtitle,
                    enabled: d["vt"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeCrossTitle,
                    subtitle: appLocalizations.advancedModeCrossSubtitle,
                    enabled: d["crossSimIms"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeEmergencyTitle,
                    subtitle: appLocalizations.advancedModeEmergencySubtitle,
                    enabled: d["emergencyWfc"] == true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: appLocalizations.advancedModeAggregation,
              icon: Icons.speed_outlined,
              child: DividedColumn(
                children: [
                  _ConfigRow(
                    title: appLocalizations.advancedModeLteCaTitle,
                    subtitle: appLocalizations.advancedModeLteCaSubtitle,
                    enabled: d["lteCa"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeRcsTitle,
                    subtitle: appLocalizations.advancedModeRcsSubtitle,
                    enabled: d["rcsSupported"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeRcsSingleRegTitle,
                    subtitle: appLocalizations.advancedModeRcsSingleRegSubtitle,
                    enabled: d["rcsSingleReg"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWfcWifiOnlyTitle,
                    subtitle: appLocalizations.advancedModeWfcWifiOnlySubtitle,
                    enabled: d["wfcWifiOnly"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWfcDefaultTitle,
                    subtitle: appLocalizations.advancedModeWfcDefaultSubtitle,
                    enabled: d["wfcDefaultEnabled"] == true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool enabled;

  const _ConfigRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    final chipBg = enabled
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final chipFg = enabled
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            enabled
                ? Icons.check_circle_outlined
                : Icons.remove_circle_outlined,
            color: chipFg,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              enabled
                  ? appLocalizations.advancedModeYes
                  : appLocalizations.advancedModeNo,
              style: theme.textTheme.labelMedium?.copyWith(
                color: chipFg,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
