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
      version: 2,
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

        await db.execute(
          "CREATE INDEX idx_cells_plmn_lat_lng ON cells (plmn, latitude, longitude)",
        );

        await db.execute(
          "CREATE INDEX idx_cells_plmn_channelnumber ON cells (plmn, channelnumber)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "CREATE INDEX IF NOT EXISTS idx_cells_plmn_channelnumber ON cells (plmn, channelnumber)",
          );
        }
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

  static Future<bool> cellExists(String plmn, int cid) async {
    if (plmn.isEmpty) return false;
    Database db = await getDatabase();

    final List<Map<String, dynamic>> rows = await db.rawQuery(
      "SELECT 1 FROM cells WHERE plmn = ? AND cid = ? LIMIT 1",
      [plmn, cid],
    );

    return rows.isNotEmpty;
  }

  static Future<({int cid, String description, bool strongMatch})?>
  guessActiveCellCid({
    required String plmn,
    required int channelNumber,
    required int targetFactor,
    required int primaryNode,
    required int primaryLastDigit,
  }) async {
    if (plmn.isEmpty || targetFactor <= 0) return null;
    Database db = await getDatabase();

    final List<Map<String, dynamic>> strongRows = await db.rawQuery(
      '''
        SELECT cid, description FROM cells
        WHERE plmn = ? AND channelnumber = ?
          AND (cid / ?) = ?
          AND (cid % 10) = ?
        LIMIT 1
      ''',
      [plmn, channelNumber, targetFactor, primaryNode, primaryLastDigit],
    );

    if (strongRows.isNotEmpty) {
      return (
        cid: strongRows.first["cid"] as int,
        description: strongRows.first["description"] as String? ?? "",
        strongMatch: true,
      );
    }

    final List<Map<String, dynamic>> weakRows = await db.rawQuery(
      '''
        SELECT cid, description FROM cells
        WHERE plmn = ? AND channelnumber = ?
          AND (cid / ?) = ?
        LIMIT 1
      ''',
      [plmn, channelNumber, targetFactor, primaryNode],
    );

    if (weakRows.isNotEmpty) {
      return (
        cid: weakRows.first["cid"] as int,
        description: weakRows.first["description"] as String? ?? "",
        strongMatch: false,
      );
    }

    return null;
  }

  static Future<List<CellTower>> fetchMapCellTowers(
    String plmn,
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
    int limit,
  ) async {
    if (plmn.isEmpty) return [];
    Database db = await getDatabase();

    final List<Map<String, dynamic>> records = await db.rawQuery(
      '''
        SELECT cid, networkgen, latitude, longitude, description, channelnumber 
        FROM cells 
        WHERE plmn = ? 
          AND latitude BETWEEN ? AND ? 
          AND longitude BETWEEN ? AND ?
        LIMIT ?
      ''',
      [plmn, minLat, maxLat, minLng, maxLng, limit],
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

  static Future<List<Map<String, dynamic>>> getCellsForPlmn(
    String plmn, {
    String searchQuery = "",
    int limit = 100,
  }) async {
    final db = await getDatabase();
    if (searchQuery.trim().isEmpty) {
      return await db.query(
        "cells",
        where: "plmn = ?",
        whereArgs: [plmn],
        limit: limit,
        orderBy: "cid ASC",
      );
    }

    final intSearch = int.tryParse(searchQuery);
    if (intSearch != null) {
      return await db.query(
        "cells",
        where: "plmn = ? AND cid LIKE ?",
        whereArgs: [plmn, "%$intSearch%"],
        limit: limit,
        orderBy: "cid ASC",
      );
    } else {
      return await db.query(
        "cells",
        where: "plmn = ? AND description LIKE ?",
        whereArgs: [plmn, "%$searchQuery%"],
        limit: limit,
        orderBy: "cid ASC",
      );
    }
  }

  static Future<int> updateCell({
    required int id,
    required int cid,
    required int networkGen,
    required double latitude,
    required double longitude,
    required String description,
    int? channelNumber,
  }) async {
    final db = await getDatabase();
    return await db.update(
      "cells",
      {
        "cid": cid,
        "networkgen": networkGen,
        "latitude": latitude,
        "longitude": longitude,
        "description": description,
        "channelnumber": channelNumber,
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
