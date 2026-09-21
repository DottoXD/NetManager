import 'package:flutter/material.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class AdvancedModeStatusDialog extends StatelessWidget {
  const AdvancedModeStatusDialog({
    required this.shizukuStatus,
    required this.diagStatus,
    super.key,
  });

  final int shizukuStatus;
  final int diagStatus;

  String _getShizukuStatusText(AppLocalizations appLocalizations) {
    switch (shizukuStatus) {
      case 0:
        return appLocalizations.advancedMenuEnabledWorking;
      case 1:
        return appLocalizations.advancedMenuPermissionDenied;
      case 2:
        return appLocalizations.advancedMenuNotInstalledRunning;
      case 3:
      default:
        return appLocalizations.advancedMenuUnknown;
    }
  }

  String _getDiagStatusText(AppLocalizations appLocalizations) {
    switch (diagStatus) {
      case 0:
        return appLocalizations.advancedMenuEnabledWorking;
      case 1:
        return appLocalizations.advancedMenuPermissionDenied;
      case 2:
        return appLocalizations.advancedMenuNotInstalledRunning;
      case 3:
      default:
        return appLocalizations.advancedMenuUnknown;
    }
  }

  IconData _getShizukuStatusIcon(AppLocalizations appLocalizations) {
    switch (shizukuStatus) {
      case 0:
        return Icons.check_circle_outline;
      case 1:
        return Icons.gpp_maybe_outlined;
      case 2:
        return Icons.no_cell_outlined;
      case 3:
      default:
        return Icons.help_outline;
    }
  }

  IconData _getDiagStatusIcon(AppLocalizations appLocalizations) {
    switch (diagStatus) {
      case 0:
        return Icons.check_circle_outline;
      case 1:
        return Icons.gpp_maybe_outlined;
      case 2:
        return Icons.no_cell_outlined;
      case 3:
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.tune_outlined),
      title: Text(appLocalizations.settingsAdvancedModeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizations.advancedMenuNoBackends,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_getShizukuStatusIcon(appLocalizations)),
                  title: Text(appLocalizations.advancedMenuShizuku),
                  subtitle: Text(_getShizukuStatusText(appLocalizations)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(_getDiagStatusIcon(appLocalizations)),
                  title: Text(appLocalizations.advancedMenuDiag),
                  subtitle: Text(_getDiagStatusText(appLocalizations)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.advancedMenuOk),
        ),
      ],
    );
  }
}
