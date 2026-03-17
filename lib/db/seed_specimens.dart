import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

/// Seeds the specimens from assets/specimens.json into the database.
/// Runs only once — skips if specimens table already has data.
Future<void> seedSpecimens(Database db) async {
  // Check if specimens table already has data
  final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM specimens');
  final count = Sqflite.firstIntValue(countResult);

  if (count != null && count > 0) {
    // Already seeded, skip
    return;
  }

  // Load JSON file from assets
  final String data = await rootBundle.loadString('assets/specimens.json');
  final List<dynamic> jsonData = json.decode(data);

  for (var entry in jsonData) {
    final specimenType = entry['specimenType'] ?? 'N/L';
    final commonUses = (entry['commonUses'] as List<dynamic>?)
            ?.join(', ') ??
        'N/L';

    await db.insert('specimens', {
      'name': specimenType,
      'common_uses': commonUses,
    });
  }
}

/// Optional: manual reseed if you update specimens.json.
/// Clears specimens and reloads JSON.
Future<void> reseedSpecimens(Database db) async {
  await db.delete('specimens');
  await seedSpecimens(db);
}
