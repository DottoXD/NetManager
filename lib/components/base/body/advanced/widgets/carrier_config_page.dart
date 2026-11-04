import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/components/dialogs/carrier_config_edit.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class CarrierConfigPage extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>> data;
  final Future<void> Function(String feature, String value)? onEdit;

  const CarrierConfigPage({super.key, required this.data, this.onEdit});

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

  static const List<String> editableKeys = [
    "canEditNr",
    "canEditVolte",
    "canEditVonr",
    "canEditWfc",
  ];

  static const List<String> allKeys = [...dataKeys, ...editableKeys];

  static bool hasKeys(Map<String, dynamic> d) => dataKeys.any(d.containsKey);

  Future<void> _edit(
    BuildContext context, {
    required String feature,
    required String featureTitle,
    required String currentValue,
    required List<(String, String)> options,
  }) async {
    final selected = await CarrierConfigEditDialog.show(
      context,
      featureTitle: featureTitle,
      currentValue: currentValue,
      options: options,
    );

    if (selected != null && onEdit != null) {
      await onEdit!(feature, selected);
    }
  }

  Future<void> _editNr(BuildContext context, Map<String, dynamic> data) {
    final appLocalizations = AppLocalizations.of(context)!;
    final nsa = data["nsaSupported"] == true;
    final sa = data["saSupported"] == true;
    final current = nsa && sa
        ? "nsa_sa"
        : nsa
        ? "nsa"
        : sa
        ? "sa"
        : "off";

    return _edit(
      context,
      feature: "nr",
      featureTitle: appLocalizations.advancedModeCarrierNROptionTitle,
      currentValue: current,
      options: [
        ("off", appLocalizations.advancedModeCarrierNROff),
        ("nsa", appLocalizations.advancedModeCarrierNRNSA),
        ("sa", appLocalizations.advancedModeCarrierNRSA),
        ("nsa_sa", appLocalizations.advancedModeCarrierNRBoth),
      ],
    );
  }

  Future<void> _editToggle(
    BuildContext context, {
    required String feature,
    required String featureTitle,
    required bool enabled,
  }) {
    final appLocalizations = AppLocalizations.of(context)!;

    return _edit(
      context,
      feature: feature,
      featureTitle: featureTitle,
      currentValue: enabled ? "true" : "false",
      options: [
        ("true", appLocalizations.advancedModeCarrierEnabled),
        ("false", appLocalizations.advancedModeCarrierDisabled),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
      valueListenable: data,
      builder: (context, dataKeys, _) {
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
                    enabled: dataKeys["nrEnabled"] == true,
                    onEdit: onEdit != null && dataKeys["canEditNr"] == true
                        ? () => _editNr(context, dataKeys)
                        : null,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeNsaTitle,
                    subtitle: appLocalizations.advancedModeNsaSubtitle,
                    enabled: dataKeys["nsaSupported"] == true,
                    onEdit: onEdit != null && dataKeys["canEditNr"] == true
                        ? () => _editNr(context, dataKeys)
                        : null,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeSaTitle,
                    subtitle: appLocalizations.advancedModeSaSubtitle,
                    enabled: dataKeys["saSupported"] == true,
                    onEdit: onEdit != null && dataKeys["canEditNr"] == true
                        ? () => _editNr(context, dataKeys)
                        : null,
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
                    enabled: dataKeys["volte"] == true,
                    onEdit: onEdit != null && dataKeys["canEditVolte"] == true
                        ? () => _editToggle(
                            context,
                            feature: "volte",
                            featureTitle:
                                appLocalizations.advancedModeVolteTitle,
                            enabled: dataKeys["volte"] == true,
                          )
                        : null,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeVonrTitle,
                    subtitle: appLocalizations.advancedModeVonrSubtitle,
                    enabled: dataKeys["vonr"] == true,
                    onEdit: onEdit != null && dataKeys["canEditVonr"] == true
                        ? () => _editToggle(
                            context,
                            feature: "vonr",
                            featureTitle:
                                appLocalizations.advancedModeVonrTitle,
                            enabled: dataKeys["vonr"] == true,
                          )
                        : null,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWifiTitle,
                    subtitle: appLocalizations.advancedModeWifiSubtitle,
                    enabled: dataKeys["wfc"] == true,
                    onEdit: onEdit != null && dataKeys["canEditWfc"] == true
                        ? () => _editToggle(
                            context,
                            feature: "wfc",
                            featureTitle:
                                appLocalizations.advancedModeWifiTitle,
                            enabled: dataKeys["wfc"] == true,
                          )
                        : null,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeVilteTitle,
                    subtitle: appLocalizations.advancedModeVilteSubtitle,
                    enabled: dataKeys["vt"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeCrossTitle,
                    subtitle: appLocalizations.advancedModeCrossSubtitle,
                    enabled: dataKeys["crossSimIms"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeEmergencyTitle,
                    subtitle: appLocalizations.advancedModeEmergencySubtitle,
                    enabled: dataKeys["emergencyWfc"] == true,
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
                    enabled: dataKeys["lteCa"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeRcsTitle,
                    subtitle: appLocalizations.advancedModeRcsSubtitle,
                    enabled: dataKeys["rcsSupported"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeRcsSingleRegTitle,
                    subtitle: appLocalizations.advancedModeRcsSingleRegSubtitle,
                    enabled: dataKeys["rcsSingleReg"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWfcWifiOnlyTitle,
                    subtitle: appLocalizations.advancedModeWfcWifiOnlySubtitle,
                    enabled: dataKeys["wfcWifiOnly"] == true,
                  ),
                  _ConfigRow(
                    title: appLocalizations.advancedModeWfcDefaultTitle,
                    subtitle: appLocalizations.advancedModeWfcDefaultSubtitle,
                    enabled: dataKeys["wfcDefaultEnabled"] == true,
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
  final VoidCallback? onEdit;

  const _ConfigRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onEdit,
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

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            enabled
                ? appLocalizations.advancedModeYes
                : appLocalizations.advancedModeNo,
            style: theme.textTheme.labelMedium?.copyWith(
              color: chipFg,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 5),
            Icon(Icons.edit_outlined, size: 12, color: chipFg),
          ],
        ],
      ),
    );

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
          if (onEdit == null)
            chip
          else
            Tooltip(
              message: "${appLocalizations.edit} $title",
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(100),
                  splashColor: theme.colorScheme.primary.withValues(
                    alpha: 0.10,
                  ),
                  child: chip,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
