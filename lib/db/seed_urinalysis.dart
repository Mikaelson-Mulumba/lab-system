import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Seeds the urinalysis parameters from assets/urinalysis.json into the database.
/// Runs only once — skips if urinalysis table already has data.
Future<void> seedUrinalysis(Database db) async {
  // Check if urinalysis table already has data
  final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM urinalysis');
  final count = Sqflite.firstIntValue(countResult);

  if (count != null && count > 0) {
    // Already seeded, skip
    return;
  }

  // Load JSON file from assets
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
