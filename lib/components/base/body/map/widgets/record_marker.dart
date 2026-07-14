import 'package:flutter/material.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/signal_color.dart';
import 'package:netmanager/types/recording/record.dart';

class RecordMarker extends StatelessWidget {
  final Record record;
  final bool isSelected;
  final ValueChanged<Record> onMarkerTap;

  const RecordMarker({
    super.key,
    required this.record,
    required this.isSelected,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    Color signalColor = getSignalColor(
      record.networkGen,
      record.processedSignal,
    );

    final fixedAlpha = signalColor.a * (record.usable ? 1.0 : 0.2);

    return GestureDetector(
      onTap: () async {
        await HapticService().triggerHaptic(HapticType.selection, context);

        onMarkerTap(record);
      },
      child: Container(
        decoration: BoxDecoration(
          color: signalColor.withValues(alpha: fixedAlpha),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.2),
              blurRadius: isSelected ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
