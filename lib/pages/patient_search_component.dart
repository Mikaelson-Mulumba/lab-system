import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class PatientSearchComponent extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientSelected;
  const PatientSearchComponent({super.key, required this.onPatientSelected});

  @override
  State<PatientSearchComponent> createState() => _PatientSearchComponentState();
}

class _PatientSearchComponentState extends State<PatientSearchComponent> {
  List<Map<String, dynamic>> patients = [];
  Map<String, dynamic>? selectedPatient;

  void _searchPatients(String query) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'patients',
      where: 'patient_code LIKE ? OR first_name LIKE ? OR second_name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    setState(() => patients = results);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Search Patient (Code or Name)',
            border: OutlineInputBorder(),
          ),
          onChanged: _searchPatients,
        ),
        if (patients.isNotEmpty)
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final p = patients[index];
                return ListTile(
                  title: Text('${p['first_name']} ${p['second_name']}'),
                  subtitle: Text('Code: ${p['patient_code'] ?? 'N/A'}'),
                  onTap: () {
                    setState(() => selectedPatient = p);
                    widget.onPatientSelected(p);
                  },
                  selected: selectedPatient?['patient_code'] == p['patient_code'],
                );
              },
            ),
          ),
        if (selectedPatient != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Selected: ${selectedPatient!['first_name']} ${selectedPatient!['second_name']} '
              '(Code: ${selectedPatient!['patient_code'] ?? 'N/A'})',
            ),
          ),
      ],
    );
  }
}
