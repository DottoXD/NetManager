import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class ScheduleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final ValueNotifier<bool> scheduleActionNotifier;

  const ScheduleButton({
    super.key,
    this.onPressed,
    required this.scheduleActionNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        if (onPressed == null) return;

        await HapticService().triggerHaptic(HapticType.selection, context);

        onPressed?.call();
      },
      tooltip: appLocalizations.speedtestPlan,
      child: ValueListenableBuilder(
        valueListenable: scheduleActionNotifier,
        builder: (context, isScheduled, child) {
          return Icon(
            isScheduled ? Icons.alarm_off_outlined : Icons.alarm_add_outlined,
            size: 18,
          );
        },
      ),
    );
  }
}
