import 'package:flutter/material.dart';

Color getTowerColor(BuildContext context, int maxGen) {
  final colorScheme = Theme.of(context).colorScheme;

  switch (maxGen) {
    case 5:
      return colorScheme.primary;
    case 4:
      return colorScheme.secondary;
    case 3:
      return colorScheme.tertiary;
    default:
      return colorScheme.outline;
  }
}
