import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:netmanager/components/modals/tower_modal.dart';
import 'package:netmanager/types/database/cell_tower.dart';
import 'package:netmanager/utils/haptic_service.dart';
import 'package:netmanager/utils/gen_color.dart';

class CellTowers extends StatelessWidget {
  final List<CellTower> cellTowers;
  final CellTower? connectedTower;
  final Function(LatLng latLng) onTowerTap;

  const CellTowers({
    super.key,
    required this.cellTowers,
    required this.connectedTower,
    required this.onTowerTap,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: cellTowers.map((tower) {
        final isConnected = connectedTower != null && tower == connectedTower;
        final towerColor = getGenColor(context, tower.getMaxGen());

        return Marker(
          point: tower.getLatLng(),
          width: 32,
          height: 32,
          child: GestureDetector(
            onTap: () async {
              await HapticService().triggerHaptic(
                HapticType.selection,
                context,
              );

              if (context.mounted) {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  builder: (BuildContext context) {
                    return TowerModal(cellTower: tower);
                  },
                );
              }

              onTowerTap(tower.getLatLng());
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: isConnected
                    ? Border.all(color: towerColor, width: 2.5)
                    : null,
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color: towerColor.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.cell_tower_outlined,
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
