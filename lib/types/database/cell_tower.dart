import 'package:latlong2/latlong.dart';
import 'package:netmanager/types/database/database_cell.dart';

class CellTower {
  final double latitude;
  final double longitude;
  final List<DatabaseCell> cells;

  CellTower({
    required this.latitude,
    required this.longitude,
    required this.cells,
  });

  LatLng getLatLng() {
    return LatLng(latitude, longitude);
  }

  int getMaxGen() {
    if (cells.isEmpty) return 0;

    int gen = cells
        .map((c) {
          if (c.description.contains("DSS") || c.description.contains("5G")) {
            return 5;
          }
          return c.networkGen;
        })
        .reduce((a, b) => a > b ? a : b);

    return gen;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CellTower) return false;

    if (other.latitude != latitude || other.longitude != longitude) {
      return false;
    }

    if (other.cells.length != cells.length) return false;
    if (other.cells.firstOrNull != cells.firstOrNull) return false;

    return true;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, cells.length);
}
