import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class HistoryButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const HistoryButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);

        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.speedtestHistory,
      child: const Icon(Icons.history_outlined),
    );
  }
}
