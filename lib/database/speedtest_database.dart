import 'package:netmanager/types/speedtest/history_result.dart';
import 'package:sqflite/sqflite.dart';

class SpeedtestDatabase {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = "${await getDatabasesPath()}/netmanager_speedtests.db";

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE speedtest_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER,
            downloadMbps REAL,
            uploadMbps REAL,
            ping INTEGER,
            jitter INTEGER,
            packetLoss REAL,
            carrier TEXT,
            plmn TEXT,
            networkGen INTEGER,
            serverName TEXT,
            latitude REAL,
            longitude REAL,
            deviceModel TEXT,
          )
        ''');

        await db.execute(
          "CREATE INDEX idx_speedtest_history_timestamp ON speedtest_history (timestamp)",
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE speedtest_history ADD COLUMN latitude REAL",
          );
          await db.execute(
            "ALTER TABLE speedtest_history ADD COLUMN longitude REAL",
          );
        }

        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE speedtest_history ADD COLUMN deviceModel TEXT",
          );
        }
      },
    );
  }

  static Future<int> insertResult(SpeedtestHistoryResult result) async {
    final db = await getDatabase();
    return await db.insert("speedtest_history", result.toMap());
  }

  static Future<int> insertAll(List<SpeedtestHistoryResult> results) async {
    final db = await getDatabase();
    final batch = db.batch();

    for (final result in results) {
      batch.insert("speedtest_history", result.toMap());
    }

    final List<Object?> inserted = await batch.commit();
    return inserted.length;
  }

  static Future<List<SpeedtestHistoryResult>> fetchHistory({int? limit}) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> records = await db.query(
      "speedtest_history",
      orderBy: "timestamp DESC",
      limit: limit,
    );

    return records.map((row) => SpeedtestHistoryResult.fromMap(row)).toList();
  }

  static Future<void> deleteResult(int id) async {
    final db = await getDatabase();
    await db.delete("speedtest_history", where: "id = ?", whereArgs: [id]);
  }

  static Future<void> clearHistory() async {
    final db = await getDatabase();
    await db.delete("speedtest_history");
  }
}
