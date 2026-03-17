import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';
import 'stock_list_page.dart';

class StockAdditionPage extends StatefulWidget {
  const StockAdditionPage({super.key});

  @override
  State<StockAdditionPage> createState() => _StockAdditionPageState();
}

class _StockAdditionPageState extends State<StockAdditionPage> {
  final _formKey = GlobalKey<FormState>();

  String item = '';
  String quantity = '';
  String price = '';
  String testUsed = '';
  String date = '';

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // ✅ Save stock permanently in DB
      final db = await DatabaseHelper.instance.database;
      await db.insert('stock', {
        'item': item,
        'quantity': quantity,
        'price': price,
        'test_used': testUsed,
        'date': date,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Stock item added successfully!')),
      );

      // ✅ Navigate to StockListPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StockListPage()),
      );
    }
  }

  Widget _buildTextField(String label, String initialValue,
      Function(String?) onSaved,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: onSaved,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
        keyboardType: type,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                '📦 Add Stock Item',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildTextField('Item', item, (val) => item = val ?? ''),
              _buildTextField('Quantity', quantity, (val) => quantity = val ?? '',
                  type: TextInputType.number),
              _buildTextField('Price', price, (val) => price = val ?? '',
                  type: TextInputType.number),
              _buildTextField('Test Used', testUsed, (val) => testUsed = val ?? ''),
              _buildTextField('Date', date, (val) => date = val ?? '',
                  type: TextInputType.datetime),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save Stock',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
