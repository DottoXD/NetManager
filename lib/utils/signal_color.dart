import 'package:material_ui/material_ui.dart';

Color getSignalColor(int gen, int signal) {
  double strength;

  switch (gen) {
    case 5:
      strength = (signal.clamp(-135, -60) + 135) / 75;
      return const Color(0xFF00C853).withValues(alpha: 0.1 + (strength * 0.7));
    case 4:
      strength = (signal.clamp(-135, -60) + 135) / 75;
      return const Color(0xFF99CC00).withValues(alpha: 0.1 + (strength * 0.7));
    case 3:
      strength = (signal.clamp(-115, -60) + 115) / 55;
      return const Color(0xFFFFAB00).withValues(alpha: 0.1 + (strength * 0.7));
    case 2:
      strength = (signal.clamp(-110, -50) + 110) / 60;
      return const Color(0xFFFF3D00).withValues(alpha: 0.1 + (strength * 0.7));

    default:
      return const Color(0xFF9E9E9E).withValues(alpha: 0.5);
  }
}
