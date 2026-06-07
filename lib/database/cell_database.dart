import 'package:latlong2/latlong.dart';
import 'package:netmanager/types/database/cell_tower.dart';
import 'package:netmanager/types/database/database_cell.dart';
import 'package:sqflite/sqflite.dart';

class CellDatabase {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = "${await getDatabasesPath()}/netmanager_cells.db";

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cells (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            networkgen INTEGER,
            plmn TEXT,
            cid INTEGER,
            latitude REAL,
            longitude REAL,
            description TEXT,
            channelnumber INTEGER
          )
        ''');

        await db.execute(
          "CREATE INDEX idx_cells_plmn_cid ON cells (plmn, cid)",
        );

        // check shared preferences for map feature!!
        await db.execute(
          "CREATE INDEX idx_cells_plmn_lat_lng ON cells (plmn, latitude, longitude)",
        );
      },
    );
  }

  static Future<Map<int, String>> fetchCells(
    String plmn,
    Set<int> targetCids,
  ) async {
    if (targetCids.isEmpty || plmn.isEmpty) return {};
    Database db = await getDatabase();

    final Map<int, String> results = {};
    final String idPlaceholders = targetCids.map((_) => "?").join(", ");

    final List<Map<String, dynamic>> records = await db.rawQuery(
      '''
        SELECT cid, description FROM cells 
        WHERE plmn = ? AND cid IN ($idPlaceholders)
      ''',
      [plmn, ...targetCids],
    );

    for (final row in records) {
      final int cid = row["cid"] as int;
      final String desc = row["description"] as String;
      if (desc.isNotEmpty) {
        results[cid] = desc;
      }
    }

    return results;
  }

  static Future<List<CellTower>> fetchMapCellTowers({
    required String plmn,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    if (plmn.isEmpty) return [];
    Database db = await getDatabase();

    final List<Map<String, dynamic>> records = await db.rawQuery(
      '''
        SELECT cid, networkgen, latitude, longitude, description, channelnumber 
        FROM cells 
        WHERE plmn = ? 
          AND latitude BETWEEN ? AND ? 
          AND longitude BETWEEN ? AND ?
        LIMIT 500
      ''',
      [plmn, minLat, maxLat, minLng, maxLng],
    );

    final Map<String, List<DatabaseCell>> groupedTowers = {};
    final Map<String, LatLng> coordinateMap = {};

    for (final row in records) {
      final double lat = (row["latitude"] as num).toDouble();
      final double lng = (row["longitude"] as num).toDouble();

      final String shortCoords =
          "${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}";

      final cell = DatabaseCell(
        cid: row["cid"] as int,
        networkGen: row["networkgen"] as int,
        description: row["description"] as String? ?? "",
        channelNumber: row["channelnumber"] as int?,
      );

      if (!groupedTowers.containsKey(shortCoords)) {
        groupedTowers[shortCoords] = [];
        coordinateMap[shortCoords] = LatLng(lat, lng);
      }

      groupedTowers[shortCoords]!.add(cell);
    }

    return groupedTowers.entries.map((entry) {
      final coords = coordinateMap[entry.key]!;
      return CellTower(
        latitude: coords.latitude,
        longitude: coords.longitude,
        cells: entry.value,
      );
    }).toList();
  }
}
