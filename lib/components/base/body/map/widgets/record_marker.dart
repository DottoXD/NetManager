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
    return GestureDetector(
      onTap: () async {
        await HapticService().triggerHaptic(HapticType.SELECTION, context);

        onMarkerTap(record);
      },
      child: Container(
        decoration: BoxDecoration(
          color: getSignalColor(
            record.networkGen,
            record.processedSignal,
          ).withValues(alpha: record.usable ? 1.0 : 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
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
