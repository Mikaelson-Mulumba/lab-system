import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();



  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('powers_lab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Use a user-writable folder instead of system-protected path
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        Directory.current.path; // fallback to current working dir

    final dbDir = join(home, 'powers_lab_data');
    await Directory(dbDir).create(recursive: true);

    final path = join(dbDir, filePath);

    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );

    return db;
  }

 Future _createDB(Database db, int version) async {
  // ---------- Create all tables ----------
  await _createPatientsTable(db);
  await _createUsersTable(db);
  await _createTestTypesTable(db);
  await _createTestsTable(db);
  await _createSpecimensTable(db);
  await _createUrinalysisTable(db);
  await _createReportsTable(db);
  await _createStockTable(db);

  // ---------- Seed datasets ----------
  await _seedLabTests(db);       // seeds lab_tests.json
  await _seedSpecimens(db);      // seeds specimens.json
  await _seedUrinalysis(db);     // seeds urinalysis.json
  await _seedDefaultAdmin(db);   // seeds default admin user
}

Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // previously added columns
    await db.execute('ALTER TABLE patients ADD COLUMN patient_code TEXT');
  }
  if (oldVersion < 3) {
    // if you want to enforce uniqueness, you need to rebuild the table
    // but for now just ensure patient_code exists
    // (SQLite cannot add UNIQUE via ALTER TABLE)
  }
}



  // ---------- Table creation helpers ----------
  Future<void> _createTestTypesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS test_types (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      test_type TEXT NOT NULL UNIQUE
    )
  ''');
  }

  Future<void> _createTestsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS tests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      test_type_id INTEGER,
      name TEXT NOT NULL,
      reference_range TEXT,
      unit TEXT,
      result_category TEXT,
      comment TEXT,
      FOREIGN KEY(test_type_id) REFERENCES test_types(id)
    )
  ''');
  }

  Future<void> _createSpecimensTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS specimens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      common_uses TEXT
    )
  ''');
  }

  Future<void> _createUrinalysisTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS urinalysis (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      name TEXT NOT NULL,
      reference_range TEXT,
      unit TEXT
    )
  ''');
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL
    )
  ''');
  }
Future<void> _createPatientsTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS patients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_code TEXT UNIQUE,
      first_name TEXT NOT NULL,
      second_name TEXT,
      age TEXT,
      gender TEXT,
      contact TEXT,
      address TEXT,
      email TEXT,
      requested_by TEXT,
      collected_by TEXT
    )
  ''');
}



Future<void> _createReportsTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      patient_id TEXT NOT NULL,
      created_at TEXT NOT NULL,
      pdf_data BLOB
    )
  ''');
}
Future<void> _createStockTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS stock (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item TEXT NOT NULL,
      quantity TEXT,
      price TEXT,
      test_used TEXT,
      date TEXT
    )
  ''');
}




  // ---------- Seeding helpers ----------
  Future<void> _seedLabTests(Database db) async {
    final String data = await rootBundle.loadString('assets/lab_tests.json');
    final List<dynamic> jsonData = json.decode(data);

    for (var entry in jsonData) {
      final testType = entry['testType'] ?? 'N/L';
      final testName = entry['testName'] ?? 'N/L';
      final referenceRange = entry['normalRange'] ?? 'N/L';
      final unit = entry['unit'] ?? '—';
      final resultCategory = entry['resultCategory'] ?? '';
      final comment = entry['resComment'] ?? '';

      final existing = await db.query(
        'test_types',
        where: 'test_type = ?',
        whereArgs: [testType],
      );

      int testTypeId;
      if (existing.isEmpty) {
        testTypeId = await db.insert('test_types', {'test_type': testType});
      } else {
        testTypeId = existing.first['id'] as int;
      }

      await db.insert('tests', {
        'test_type_id': testTypeId,
        'name': testName,
        'reference_range': referenceRange,
        'unit': unit,
        'result_category': resultCategory,
        'comment': comment,
      });
    }
  }

  Future<void> _seedSpecimens(Database db) async {
    final String data = await rootBundle.loadString('assets/specimens.json');
    final List<dynamic> jsonData = json.decode(data);

    for (var entry in jsonData) {
      final specimenType = entry['specimenType'] ?? 'N/L';
      final commonUses =
          (entry['commonUses'] as List<dynamic>?)?.join(', ') ?? 'N/L';

      await db.insert('specimens', {
        'name': specimenType,
        'common_uses': commonUses,
      });
    }
  }

  Future<void> _seedUrinalysis(Database db) async {
    final String data = await rootBundle.loadString('assets/urinalysis.json');
    final List<dynamic> jsonData = json.decode(data);

    for (var entry in jsonData) {
      final category = entry['category'] ?? 'N/L';
      final name = entry['name'] ?? 'N/L';
      final referenceRange = entry['reference_range'] ?? 'N/L';
      final unit = entry['unit'] ?? '—';

      await db.insert('urinalysis', {
        'category': category,
        'name': name,
        'reference_range': referenceRange,
        'unit': unit,
      });
    }
  }

  Future<void> _seedDefaultAdmin(Database db) async {
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123', // plain string for now
        'role': 'admin',
      });
    } else {
      // Ensure role is always admin
      await db.update(
        'users',
        {'role': 'admin'},
        where: 'username = ?',
        whereArgs: ['admin'],
      );
    }
  }

  // ---------- Reports helpers ----------
  Future<int> insertReport({
    required String patientId,
    required List<int> pdfBytes,
  }) async {
    final db = await database;
    return await db.insert('reports', {
      'patient_id': patientId,
      'created_at': DateTime.now().toIso8601String(),
      'pdf_data': pdfBytes,
    });
  }

  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await database;
    return await db.query('reports', orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getReportById(int id) async {
    final db = await database;
    final result = await db.query('reports', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteReport(int id) async {
    final db = await database;
    return await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }
}
