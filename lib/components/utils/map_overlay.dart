import 'package:flutter/material.dart';

Widget mapOverlay(
  BuildContext context,
  List<String> displayTitles,
  List<String> displayValues,
) {
  final theme = Theme.of(context);

  return Align(
    alignment: Alignment.topCenter,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      elevation: 2,
      shadowColor: Colors.transparent,
      //color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 36.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(displayTitles.length, (index) {
            final isLast = index == displayTitles.length - 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      displayTitles[index],
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValues[index],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (!isLast) SizedBox(width: 24),
              ],
            );
          }),
        ),
      ),
    ),
  );
}
