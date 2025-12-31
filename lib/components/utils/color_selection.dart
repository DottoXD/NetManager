import 'package:flutter/material.dart';

const List<int> themeColors = [
  0xFFD1C4E9, // Purple
  0xFFB3E5FC, // Default cyan
  0xFFE6F0F2, // Gray
  0xFFC8E6C9, // Lime
  0xFFFFF9C4, // Yellow
  0xFFFFCDD2, // Pink
];

Widget colorSelector(
  BuildContext context,
  int themeColor,
  void Function(int) onColorChanged,
) {
  final primaryColor = Theme.of(context).colorScheme.primary;
  final surfaceColor = Theme.of(context).colorScheme.surface;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: themeColors.map((color) {
        bool selected = color == themeColor;

        return ChoiceChip(
          label: const SizedBox.shrink(),
          selected: selected,
          checkmarkColor: surfaceColor,
          selectedColor: Color(color),
          backgroundColor: Color(color),
          shape: const CircleBorder(),
          side: selected ? BorderSide(color: primaryColor) : BorderSide.none,
          onSelected: (_) {
            onColorChanged(color);
          },
        );
      }).toList(),
    ),
  );
}
