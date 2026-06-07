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
}
