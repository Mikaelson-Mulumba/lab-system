import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class SpecimenPage extends StatefulWidget {
  const SpecimenPage({super.key});

  @override
  State<SpecimenPage> createState() => _SpecimenPageState();
}

class _SpecimenPageState extends State<SpecimenPage> {
  final TextEditingController _specimenController = TextEditingController();
  final TextEditingController _usesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> specimens = [];
  List<Map<String, dynamic>> filteredSpecimens = [];

  @override
  void initState() {
    super.initState();
    _loadSpecimens();
  }

  Future<void> _loadSpecimens() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('specimens');
    if (!mounted) return;
    setState(() {
      specimens = data;
      filteredSpecimens = specimens;
    });
  }

  Future<void> _addSpecimen() async {
    final specimenName = _specimenController.text.trim();
    final commonUses = _usesController.text.trim();
    if (specimenName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a specimen name')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('specimens', {
      'name': specimenName,
      'common_uses': commonUses,
    });

    _specimenController.clear();
    _usesController.clear();
    await _loadSpecimens();
  }

  Future<void> _editSpecimen(Map<String, dynamic> specimen) async {
    _specimenController.text = specimen['name'] ?? '';
    _usesController.text = specimen['common_uses'] ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Specimen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _specimenController,
              decoration: const InputDecoration(
                labelText: 'Specimen Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usesController,
              decoration: const InputDecoration(
                labelText: 'Common Uses',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _specimenController.clear();
              _usesController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.update(
                'specimens',
                {
                  'name': _specimenController.text.trim(),
                  'common_uses': _usesController.text.trim(),
                },
                where: 'id = ?',
                whereArgs: [specimen['id']],
              );
              _specimenController.clear();
              _usesController.clear();
              if (!mounted) return;
              Navigator.pop(context);
              await _loadSpecimens();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSpecimen(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this specimen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('specimens', where: 'id = ?', whereArgs: [id]);
      await _loadSpecimens();
    }
  }

  void _searchSpecimens(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSpecimens = specimens;
      } else {
        filteredSpecimens = specimens
            .where((s) => s['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
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
      body: SingleChildScrollView( // ✅ makes whole page scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add specimen form
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _specimenController,
                    decoration: const InputDecoration(
                      labelText: 'Specimen Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _usesController,
                    decoration: const InputDecoration(
                      labelText: 'Common Uses',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addSpecimen,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Specimens',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchSpecimens,
            ),
            const SizedBox(height: 24),

            // Specimen table
            filteredSpecimens.isEmpty
                ? const Center(child: Text('No specimens found'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Specimen')),
                        DataColumn(label: Text('Common Uses')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredSpecimens.map((s) {
                        return DataRow(
                          cells: [
                            DataCell(Text(s['name'] ?? '')),
                            DataCell(Text(s['common_uses'] ?? '')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editSpecimen(s),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteSpecimen(s['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
