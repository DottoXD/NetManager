import 'package:material_ui/material_ui.dart';
import 'package:netmanager/l10n/app_localizations.dart';
import 'package:netmanager/utils/haptic_service.dart';

class FilterButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const FilterButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      elevation: 1,
      mini: true,
      onPressed: () async {
        await HapticService().triggerHaptic(HapticType.light, context);

        onPressed!();
      },
      tooltip: AppLocalizations.of(context)!.mapFilters,
      child: const Icon(Icons.filter_alt_outlined),
    );
  }
}
