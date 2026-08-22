import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class ScreenshotButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ScreenshotButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.selection, context);
        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.screenshotPage,
      child: const Icon(Icons.save_outlined, size: 18),
    );
  }
}
