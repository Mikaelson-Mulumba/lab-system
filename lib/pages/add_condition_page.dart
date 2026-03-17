import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AddConditionPage extends StatefulWidget {
  final int unitMeasureId;
  const AddConditionPage({super.key, required this.unitMeasureId});

  @override
  State<AddConditionPage> createState() => _AddConditionPageState();
}

class _AddConditionPageState extends State<AddConditionPage> {
  final _conditionController = TextEditingController();
  final _rangeController = TextEditingController();

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('conditions', {
      'unit_measure_id': widget.unitMeasureId,
      'condition': _conditionController.text.trim().isEmpty ? 'N/L' : _conditionController.text.trim(),
      'range': _rangeController.text.trim().isEmpty ? 'N/L' : _rangeController.text.trim(),
    });
    if (!mounted) return;
    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Condition')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _conditionController, decoration: const InputDecoration(labelText: 'Condition')),
            const SizedBox(height: 8),
            TextField(controller: _rangeController, decoration: const InputDecoration(labelText: 'Range')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
