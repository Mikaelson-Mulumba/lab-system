import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  List<Map<String, Object?>> stocks = [];

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  Future<void> _fetchStock() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('stock');
    if (!mounted) return;
    setState(() {
      stocks = result;
    });
  }

  Future<void> _deleteStock(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this stock item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('stock', where: 'id = ?', whereArgs: [id]);

      if (!mounted) return;
      await _fetchStock();

      // ✅ Safe: only use context after mounted check
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Stock item deleted')),
        );
      }
    }
  }

  void _editStock(Map<String, Object?> stock) {
    final itemController = TextEditingController(text: stock['item']?.toString() ?? '');
    final quantityController = TextEditingController(text: stock['quantity']?.toString() ?? '');
    final priceController = TextEditingController(text: stock['price']?.toString() ?? '');
    final testUsedController = TextEditingController(text: stock['test_used']?.toString() ?? '');
    final dateController = TextEditingController(text: stock['date']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Stock Item'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item')),
              const SizedBox(height: 8),
              TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity')),
              const SizedBox(height: 8),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price')),
              const SizedBox(height: 8),
              TextField(controller: testUsedController, decoration: const InputDecoration(labelText: 'Test Used')),
              const SizedBox(height: 8),
              TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
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
                'stock',
                {
                  'item': itemController.text.trim(),
                  'quantity': quantityController.text.trim(),
                  'price': priceController.text.trim(),
                  'test_used': testUsedController.text.trim(),
                  'date': dateController.text.trim(),
                },
                where: 'id = ?',
                whereArgs: [stock['id']],
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _fetchStock();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✏️ Stock item updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
              '📦 Stock Inventory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            stocks.isEmpty
                ? const Text('No stock items found.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Test Used')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: stocks.map((s) {
                        return DataRow(cells: [
                          DataCell(Text('${s['item'] ?? ''}')),
                          DataCell(Text('${s['quantity'] ?? ''}')),
                          DataCell(Text('${s['price'] ?? ''}')),
                          DataCell(Text('${s['test_used'] ?? ''}')),
                          DataCell(Text('${s['date'] ?? ''}')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editStock(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteStock(s['id'] as int),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
