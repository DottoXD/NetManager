import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class ShareResultButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ShareResultButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);

        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.speedtestShareResult,
      child: const Icon(Icons.camera_alt_outlined, size: 18),
    );
  }
}
