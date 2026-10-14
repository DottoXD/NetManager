import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';

class AdvancedSubpage {
  final String Function(AppLocalizations appLocalizations) title;
  final IconData icon;
  final Widget Function(BuildContext context) builder;

  const AdvancedSubpage({
    required this.title,
    required this.icon,
    required this.builder,
  });
}
