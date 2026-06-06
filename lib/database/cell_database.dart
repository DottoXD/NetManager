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
      },
    );
  }

  static Future<Map<int, String>> fetchCells(
    String plmn,
    Set<int> targetCids,
  ) async {
    if (_database == null || targetCids.isEmpty || plmn.isEmpty) return {};

    final Map<int, String> results = {};
    final String idPlaceholders = targetCids.map((_) => "?").join(", ");

    final List<Map<String, dynamic>> records = await _database!.rawQuery(
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
}
