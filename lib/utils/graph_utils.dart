import 'package:flutter/material.dart';

enum ValueQuality { excellent, good, fair, poor, unknown }

ValueQuality classifyQuality(String label, double value) {
  final String capsLabel = label.toUpperCase();

  if (capsLabel.contains("RSRP") || capsLabel.contains("RSCP")) {
    if (value >= -80) return ValueQuality.excellent;
    if (value >= -95) return ValueQuality.good;
    if (value >= -110) return ValueQuality.fair;
    return ValueQuality.poor;
  }

  if (capsLabel.contains("RSSI") || capsLabel.contains("RXL")) {
    if (value >= -65) return ValueQuality.excellent;
    if (value >= -75) return ValueQuality.good;
    if (value >= -90) return ValueQuality.fair;
    return ValueQuality.poor;
  }

  if (capsLabel.contains("RSRQ")) {
    if (value >= -10) return ValueQuality.excellent;
    if (value >= -14) return ValueQuality.good;
    if (value >= -18) return ValueQuality.fair;
    return ValueQuality.poor;
  }

  if (capsLabel.contains("SNR") || capsLabel.contains("EC/IO")) {
    if (value >= 18) return ValueQuality.excellent;
    if (value >= 13) return ValueQuality.good;
    if (value >= 5) return ValueQuality.fair;
    return ValueQuality.poor;
  }

  if (capsLabel.contains("TA")) {
    if (value <= 40) return ValueQuality.excellent;
    if (value <= 150) return ValueQuality.good;
    if (value <= 350) return ValueQuality.fair;
    return ValueQuality.poor;
  }

  return ValueQuality.unknown;
}

Color colorForQuality(BuildContext context, ValueQuality quality) {
  final theme = Theme.of(context);

  switch (quality) {
    case ValueQuality.excellent:
      return theme.colorScheme.primary;
    case ValueQuality.good:
      return theme.colorScheme.tertiary;
    case ValueQuality.fair:
      return theme.colorScheme.secondary;
    case ValueQuality.poor:
      return theme.colorScheme.error;
    case ValueQuality.unknown:
      return theme.colorScheme.onSurfaceVariant;
  }
}
