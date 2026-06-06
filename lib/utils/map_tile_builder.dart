import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

const ColorFilter _darkMapFilter = ColorFilter.matrix(<double>[
  -0.1, -0.5, -0.05, 0, 190, //red
  -0.1, -0.5, -0.05, 0, 190, //green
  -0.1, -0.5, -0.05, 0, 190, //blue
  0, 0, 0, 1, 0, //alpha
]);

Widget mapTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  final theme = Theme.of(context);

  if (theme.brightness == Brightness.light) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        theme.colorScheme.surface.withValues(alpha: 255 * 0.85),
        BlendMode.modulate,
      ),
      child: tileWidget,
    );
  } else {
    return ColorFiltered(colorFilter: _darkMapFilter, child: tileWidget);
  }
}
