import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import 'test_type_detail_page.dart';

class TestTypeListPage extends StatefulWidget {
  const TestTypeListPage({super.key});

  @override
  State<TestTypeListPage> createState() => _TestTypeListPageState();
}

class _TestTypeListPageState extends State<TestTypeListPage> {
  List<Map<String, dynamic>> testTypes = [];
  List<Map<String, dynamic>> filteredTestTypes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTestTypes();
    _searchController.addListener(_applySearch);
  }

  Future<void> _fetchTestTypes() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('test_types');
    if (!mounted) return;
    setState(() {
      testTypes = rows;
      filteredTestTypes = rows;
    });
  }

  void _applySearch() async {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredTestTypes = testTypes);
      return;
    }

    final db = await DatabaseHelper.instance.database;

    final testMatches = await db.query(
      'tests',
      where: 'name LIKE ? OR reference_range LIKE ? OR unit LIKE ? OR result_category LIKE ? OR comment LIKE ?',
      whereArgs: List.filled(5, '%$query%'),
    );

    if (testMatches.isEmpty) {
      setState(() {
        filteredTestTypes = testTypes.where((type) {
          final testTypeName = (type['test_type'] ?? '').toString().toLowerCase();
          return testTypeName.contains(query);
        }).toList();
      });
    } else {
      final typeIds = testMatches.map((t) => t['test_type_id']).toSet();
      setState(() {
        filteredTestTypes = testTypes.where((type) => typeIds.contains(type['id'])).toList();
      });
    }
  }

  Future<void> _deleteTestType(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('test_types', where: 'id = ?', whereArgs: [id]);
    if (!mounted) return;
    await _fetchTestTypes();
  }

  Future<void> _editTestType(Map<String, dynamic> type) async {
    final controller = TextEditingController(text: type['test_type'] ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Test Type'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Test Type Name'),
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
                'test_types',
                {'test_type': controller.text.trim()},
                where: 'id = ?',
                whereArgs: [type['id']],
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _fetchTestTypes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Test type updated successfully')),
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
      appBar: TopNav(
        onLogout: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Test Type List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Test Type or Test',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredTestTypes.isEmpty
                  ? const Center(child: Text('No matching test types or tests found.'))
                  : ListView.builder(
                      itemCount: filteredTestTypes.length,
                      itemBuilder: (context, index) {
                        final type = filteredTestTypes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(type['test_type']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editTestType(type),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTestType(type['id']),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TestTypeDetailPage(testType: type),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
