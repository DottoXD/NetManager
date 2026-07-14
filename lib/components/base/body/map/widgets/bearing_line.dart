import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BearingLine extends StatelessWidget {
  final LatLng userLocation;
  final LatLng towerLocation;

  const BearingLine({
    super.key,
    required this.userLocation,
    required this.towerLocation,
  });

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: [userLocation, towerLocation],
          strokeWidth: 2.0,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          pattern: const StrokePattern.dotted(),
        ),
      ],
    );
  }
}
