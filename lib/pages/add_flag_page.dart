import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AddFlagPage extends StatefulWidget {
  final int conditionId;
  const AddFlagPage({super.key, required this.conditionId});

  @override
  State<AddFlagPage> createState() => _AddFlagPageState();
}

class _AddFlagPageState extends State<AddFlagPage> {
  final _flagController = TextEditingController();
  final _commentController = TextEditingController();

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('flags', {
      'condition_id': widget.conditionId,
      'flag': _flagController.text.trim().isEmpty ? 'N/L' : _flagController.text.trim(),
      'comment': _commentController.text.trim().isEmpty ? 'N/L' : _commentController.text.trim(),
    });
    if (!mounted) return;
    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flag')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _flagController, decoration: const InputDecoration(labelText: 'Flag')),
            const SizedBox(height: 8),
            TextField(controller: _commentController, decoration: const InputDecoration(labelText: 'Comment')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
