import 'package:latlong2/latlong.dart';
import 'package:netmanager/types/database/cell_tower.dart';
import 'package:netmanager/types/database/database_cell.dart';

List<CellTower> clusterMapTowers(
  List<CellTower> rawTowers,
  double currentZoom,
) {
  final List<CellTower> processedList = [];
  final List<int> clusterCounts = [];
  const Distance distance = Distance();

  final bool isZoomedOut = currentZoom < 13.0;
  final double distanceThreshold = isZoomedOut ? 1500.0 : 20.0;

  for (final tower in rawTowers) {
    bool isMerged = false;

    for (int i = 0; i < processedList.length; i++) {
      final existingTower = processedList[i];
      final dist = distance.as(
        LengthUnit.Meter,
        tower.getLatLng(),
        existingTower.getLatLng(),
      );

      if (dist <= distanceThreshold) {
        if (isZoomedOut) {
          final int currentCount = clusterCounts[i];
          final int newCount = currentCount + 1;

          final double newLat =
              ((existingTower.latitude * currentCount) + tower.latitude) /
              newCount;
          final double newLon =
              ((existingTower.longitude * currentCount) + tower.longitude) /
              newCount;

          processedList[i] = CellTower(
            latitude: newLat,
            longitude: newLon,
            cells: [],
          );
          clusterCounts[i] = newCount;
        } else {
          final combinedCells = List<DatabaseCell>.from(existingTower.cells)
            ..addAll(tower.cells);

          processedList[i] = CellTower(
            latitude: existingTower.latitude,
            longitude: existingTower.longitude,
            cells: combinedCells,
          );
          clusterCounts[i]++;
        }
        isMerged = true;

        break;
      }
    }

    if (!isMerged) {
      processedList.add(
        CellTower(
          latitude: tower.latitude,
          longitude: tower.longitude,
          cells: List<DatabaseCell>.from(tower.cells),
        ),
      );
      clusterCounts.add(1);
    }
  }

  return processedList;
}
