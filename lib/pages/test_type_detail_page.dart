import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class TestTypeDetailPage extends StatefulWidget {
  final Map<String, dynamic> testType;

  const TestTypeDetailPage({super.key, required this.testType});

  @override
  State<TestTypeDetailPage> createState() => _TestTypeDetailPageState();
}

class _TestTypeDetailPageState extends State<TestTypeDetailPage> {
  List<Map<String, dynamic>> tests = [];
  List<Map<String, dynamic>> filteredTests = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTests();
    _searchController.addListener(_applySearch);
  }

  Future<void> _fetchTests() async {
    final db = await DatabaseHelper.instance.database;

    final testRows = await db.query(
      'tests',
      where: 'test_type_id = ?',
      whereArgs: [widget.testType['id']],
    );

    if (!mounted) return;
    setState(() {
      tests = testRows;
      filteredTests = testRows;
    });
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTests = tests.where((t) {
        final name = (t['name'] ?? '').toString().toLowerCase();
        final refRange = (t['reference_range'] ?? '').toString().toLowerCase();
        final unit = (t['unit'] ?? '').toString().toLowerCase();
        final category = (t['result_category'] ?? '').toString().toLowerCase();
        final comment = (t['comment'] ?? '').toString().toLowerCase();

        return name.contains(query) ||
               refRange.contains(query) ||
               unit.contains(query) ||
               category.contains(query) ||
               comment.contains(query);
      }).toList();
    });
  }

  Future<void> _editTest(Map<String, dynamic> test) async {
    final nameController = TextEditingController(text: test['name'] ?? '');
    final refRangeController = TextEditingController(text: test['reference_range'] ?? '');
    final unitController = TextEditingController(text: test['unit'] ?? '');
    final categoryController = TextEditingController(text: test['result_category'] ?? '');
    final commentController = TextEditingController(text: test['comment'] ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Test'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Test Name')),
              TextField(controller: refRangeController, decoration: const InputDecoration(labelText: 'Reference Range')),
              TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Result Category')),
              TextField(controller: commentController, decoration: const InputDecoration(labelText: 'Comment')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.update(
                'tests',
                {
                  'name': nameController.text.trim(),
                  'reference_range': refRangeController.text.trim(),
                  'unit': unitController.text.trim(),
                  'result_category': categoryController.text.trim(),
                  'comment': commentController.text.trim(),
                },
                where: 'id = ?',
                whereArgs: [test['id']],
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _fetchTests();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Test updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testType['test_type']),
      ),
      body: Column(
        children: [
          // ✅ Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Tests',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: filteredTests.isEmpty
                ? const Center(child: Text('No tests found'))
                : ListView.builder(
                    itemCount: filteredTests.length,
                    itemBuilder: (context, index) {
                      final t = filteredTests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t['name'] ?? 'Unnamed Test',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editTest(t),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Reference Range: ${t['reference_range'] ?? 'N/A'}"),
                              Text("Unit: ${t['unit'] ?? 'N/A'}"),
                              Text("Result Category: ${t['result_category'] ?? 'N/A'}"),
                              Text("Comment: ${t['comment'] ?? 'N/A'}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
