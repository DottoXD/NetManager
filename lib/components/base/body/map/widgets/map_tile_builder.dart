import 'package:flutter/material.dart';

const ColorFilter _darkMapFilter = ColorFilter.matrix(<double>[
  -0.1, -0.5, -0.05, 0, 190, // Red
  -0.1, -0.5, -0.05, 0, 190, // Green
  -0.1, -0.5, -0.05, 0, 190, // Blue
  0, 0, 0, 1, 0, //alpha
]);

class MapTileBuilder extends StatelessWidget {
  const MapTileBuilder({super.key, required this.tileWidget});

  final Widget tileWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (theme.brightness == Brightness.light) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          theme.colorScheme.surface.withValues(alpha: 0.5),
          BlendMode.srcATop,
        ),
        child: tileWidget,
      );
    }

    return ColorFiltered(colorFilter: _darkMapFilter, child: tileWidget);
  }
}
