import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:netmanager/components/modals/tower_modal.dart';
import 'package:netmanager/types/database/cell_tower.dart';

class CellTowers extends StatelessWidget {
  final List<CellTower> cellTowers;
  final Function(LatLng latLng) onTowerTap;

  const CellTowers({
    super.key,
    required this.cellTowers,
    required this.onTowerTap,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: cellTowers.map((tower) {
        return Marker(
          point: tower.getLatLng(),
          width: 32,
          height: 32,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                useSafeArea: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                builder: (BuildContext context) => towerModal(context, tower),
              );

              onTowerTap(tower.getLatLng());
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cell_tower_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
