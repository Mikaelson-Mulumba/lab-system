import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';
import 'patients_page.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final _formKey = GlobalKey<FormState>();

  // Patient form fields
  String firstName = '';
  String secondName = '';
  String age = '';
  String gender = '';
  String contact = '';
  String address = '';
  String email = '';
  String requestedBy = '';
  String collectedBy = '';

  // Generate professional patient code
  String _generateProCode(int id) {
    return 'PAT-${id.toString().padLeft(5, '0')}'; // PAT-00001, PAT-00002…
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = await DatabaseHelper.instance.database;

      // Insert patient without id/patient_code
      final newId = await db.insert('patients', {
        'first_name': firstName,
        'second_name': secondName,
        'age': age,
        'gender': gender,
        'contact': contact,
        'address': address,
        'email': email,
        'requested_by': requestedBy,
        'collected_by': collectedBy,
      });

      // Update with professional patient code
      await db.update(
        'patients',
        {'patient_code': _generateProCode(newId)},
        where: 'id = ?',
        whereArgs: [newId],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Patient saved successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientsPage()),
      );
    }
  }

  Widget _buildTextField(
    String label,
    Function(String?) onSaved, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: onSaved,
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
        keyboardType: keyboardType,
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
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    '➕ Add New Patient',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField('First Name', (val) => firstName = val ?? ''),
                  _buildTextField('Second Name', (val) => secondName = val ?? ''),
                  _buildTextField('Age', (val) => age = val ?? '',
                      keyboardType: TextInputType.number),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: gender.isEmpty ? null : gender,
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (val) => setState(() => gender = val ?? ''),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please select gender' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField('Contact', (val) => contact = val ?? ''),
                  _buildTextField('Address', (val) => address = val ?? ''),
                  _buildTextField('Email', (val) => email = val ?? ''),
                  _buildTextField('Requested By', (val) => requestedBy = val ?? ''),
                  _buildTextField('Collected By', (val) => collectedBy = val ?? ''),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleSubmit,
                      icon: const Icon(Icons.save, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: const Text(
                        'Save Patient',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
