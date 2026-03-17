import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Seeds the lab tests from assets/lab_tests.json into the database.
/// Runs only once — skips if tests table already has data.
Future<void> seedLabTests(Database db) async {
  // Check if tests table already has data
  final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM tests');
  final count = Sqflite.firstIntValue(countResult);

  if (count != null && count > 0) {
    // Already seeded, skip
    return;
  }

  // Load JSON file from assets
  final String data = await rootBundle.loadString('assets/lab_tests.json');
  final List<dynamic> jsonData = json.decode(data);

  for (var entry in jsonData) {
    final testType = entry['testType'] ?? 'N/L';
    final testName = entry['testName'] ?? 'N/L';
    final referenceRange = entry['normalRange'] ?? 'N/L';
    final unit = entry['unit'] ?? '—';
    final resultCategory = entry['resultCategory'] ?? 'N/L';
    final comment = entry['resComment'] ?? 'N/L';

    // Insert or get test type
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

    // Insert test aligned with schema
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

/// Optional: manual reseed if you update lab_tests.json.
/// Clears tests + test_types and reloads JSON.
Future<void> reseedLabTests(Database db) async {
  await db.delete('tests');
  await db.delete('test_types');
  await seedLabTests(db);
}
