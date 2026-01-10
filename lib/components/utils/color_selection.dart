import 'package:flutter/material.dart';
import 'package:netmanager/components/utils/haptic_utils.dart';

const List<int> themeColors = [
  0xFFD1C4E9, // Purple
  0xFFB3E5FC, // Default cyan
  0xFFE6F0F2, // Gray
  0xFFC8E6C9, // Lime
  0xFFFFF9C4, // Yellow
  0xFFFFCDD2, // Pink
  0xFF1B4F41, // Dark green
  0xFF411B4F, // Dark purple
  0xFFA32E2E, // Red
  0xFFFFB93B, // Orange
];

Widget colorSelector(
  BuildContext context,
  int themeColor,
  void Function(int) onColorChanged,
) {
  final primaryColor = Theme.of(context).colorScheme.primary;
  final surfaceColor = Theme.of(context).colorScheme.surface;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 7.0),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: themeColors.map((color) {
          final bool selected = color == themeColor;

          return Padding(
            padding: const EdgeInsets.only(right: 3.0),
            child: HapticTap(
              type: HapticType.SELECTION,
              child: ChoiceChip(
                label: const SizedBox.shrink(),
                selected: selected,
                checkmarkColor: surfaceColor,
                selectedColor: Color(color),
                backgroundColor: Color(color),
                shape: const CircleBorder(),
                tooltip: "#$color",
                side: selected
                    ? BorderSide(color: primaryColor)
                    : BorderSide.none,
                onSelected: (_) {
                  onColorChanged(color);
                },
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}
