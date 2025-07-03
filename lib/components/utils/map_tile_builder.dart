import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

Widget mapTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  if (Theme.of(context).brightness == Brightness.light) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Theme.of(context).colorScheme.surface.withOpacity(0.85),
        BlendMode.modulate,
      ),
      child: tileWidget,
    );
  } else {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.1, -0.5, -0.05, 0, 180, //red
        -0.1, -0.5, -0.05, 0, 180, //green
        -0.1, -0.5, -0.05, 0, 180, //blue
        0, 0, 0, 1, 0, //alpha
      ]),
      child: tileWidget,
    );
  }
}
