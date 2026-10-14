import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:netmanager/components/base/body/advanced/widgets/info_card.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class ImsStatusPage extends StatelessWidget {
  final ValueListenable<Map<String, dynamic>> ims;

  const ImsStatusPage({super.key, required this.ims});

  static const Map<String, String> defaults = {
    "registration": "UNREGISTERED",
    "regTech": "N/A",
    "mmtel": "Unavailable",
    "mmtelVideo": "Unavailable",
    "mmtelSms": "Unavailable",
    "rcsState": "Unregistered",
    "epdgStatus": "Disconnected",
    "emergencyCapable": "Unsupported",
  };

  static String _local(AppLocalizations appLocalizations, String v) {
    switch (v) {
      case "Available":
        return appLocalizations.advancedModeImsValueAvailable;
      case "Unavailable":
        return appLocalizations.advancedModeImsValueUnavailable;
      case "Registered":
        return appLocalizations.advancedModeImsValueRegistered;
      case "Unregistered":
        return appLocalizations.advancedModeImsValueUnregistered;
      case "Connected":
        return appLocalizations.advancedModeImsValueConnected;
      case "Disconnected":
        return appLocalizations.advancedModeImsValueDisconnected;
      case "Supported":
        return appLocalizations.advancedModeImsValueSupported;
      case "Unsupported":
        return appLocalizations.advancedModeImsValueUnsupported;
      default:
        return v;
    }
  }

  static String _localState(AppLocalizations appLocalizations, String v) {
    switch (v) {
      case "REGISTERED":
        return appLocalizations.advancedModeImsStateRegistered;
      case "REGISTERING":
        return appLocalizations.advancedModeImsStateRegistering;
      case "UNREGISTERED":
        return appLocalizations.advancedModeImsStateUnregistered;
      default:
        return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ims,
      builder: (context, d, _) {
        String getField(String key) {
          return (d[key] as String?) ?? defaults[key]!;
        }

        final regState = getField("registration");

        final Color heroBg;
        final Color heroFg;
        final IconData regIcon;

        switch (regState) {
          case "REGISTERED":
            heroBg = theme.colorScheme.primaryContainer;
            heroFg = theme.colorScheme.onPrimaryContainer;
            regIcon = Icons.verified_outlined;
            break;
          case "REGISTERING":
            heroBg = theme.colorScheme.tertiaryContainer;
            heroFg = theme.colorScheme.onTertiaryContainer;
            regIcon = Icons.autorenew_outlined;
            break;
          default:
            heroBg = theme.colorScheme.errorContainer;
            heroFg = theme.colorScheme.onErrorContainer;
            regIcon = Icons.error_outlined;
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 64),
          children: [
            _RegistrationHero(
              regState: _localState(appLocalizations, regState),
              regTech: getField("regTech"),
              bgColor: heroBg,
              fgColor: heroFg,
              icon: regIcon,
            ),
            const SizedBox(height: 14),
            InfoCard(
              title: appLocalizations.advancedModeImsMmtel,
              icon: Icons.phone_in_talk_outlined,
              child: DividedColumn(
                children: [
                  _FeatureRow(
                    icon: Icons.record_voice_over_outlined,
                    label: appLocalizations.advancedModeImsVoice,
                    raw: getField("mmtel"),
                  ),
                  _FeatureRow(
                    icon: Icons.videocam_outlined,
                    label: appLocalizations.advancedModeImsVideo,
                    raw: getField("mmtelVideo"),
                  ),
                  _FeatureRow(
                    icon: Icons.sms_outlined,
                    label: appLocalizations.advancedModeImsSms,
                    raw: getField("mmtelSms"),
                  ),
                  _FeatureRow(
                    icon: Icons.sos_outlined,
                    label: appLocalizations.advancedModeImsEmergency,
                    raw: getField("emergencyCapable"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InfoCard(
              title: appLocalizations.advancedModeImsRcsTunnelTitle,
              icon: Icons.forum_outlined,
              child: DividedColumn(
                children: [
                  _FeatureRow(
                    icon: Icons.forum_outlined,
                    label: appLocalizations.advancedModeImsRcsState,
                    raw: getField("rcsState"),
                  ),
                  _FeatureRow(
                    icon: Icons.vpn_lock_outlined,
                    label: appLocalizations.advancedModeImsEpdg,
                    raw: getField("epdgStatus"),
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

class _RegistrationHero extends StatelessWidget {
  final String regState;
  final String regTech;
  final Color bgColor;
  final Color fgColor;
  final IconData icon;

  const _RegistrationHero({
    required this.regState,
    required this.regTech,
    required this.bgColor,
    required this.fgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fgColor, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            appLocalizations.advancedModeImsStateTitle(regState),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              appLocalizations.advancedModeImsActiveRatTitle(regTech),
              style: theme.textTheme.labelMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String raw;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.raw,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final positive =
        raw.contains("Available") ||
        raw.contains("Registered") ||
        raw.contains("Connected") ||
        raw.contains("Supported");

    final badgeBg = positive
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final badgeFg = positive
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              ImsStatusPage._local(appLocalizations, raw),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
