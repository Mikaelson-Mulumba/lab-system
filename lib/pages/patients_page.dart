import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  List<Map<String, Object?>> patients = [];
  Map<String, List<Map<String, dynamic>>> patientReports = {};
  String searchQuery = ''; // ✅ search query state
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('patients');

    final reports = await db.query('reports');
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var r in reports) {
      final pid = r['patient_id']?.toString() ?? '';
      grouped.putIfAbsent(pid, () => []).add(r);
    }

    if (!mounted) return;
    setState(() {
      patients = result;
      patientReports = grouped;
    });
  }

  void _openPdf(Map<String, dynamic> report) {
    final pdfBytes = report['pdf_data'];
    if (pdfBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF data found for this report')),
      );
      return;
    }

    final bytes = pdfBytes is Uint8List
        ? pdfBytes
        : Uint8List.fromList(List<int>.from(pdfBytes));

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 600,
          height: 800,
          child: PdfPreview(build: (format) async => bytes),
        ),
      ),
    );
  }

  Future<void> _deletePatient(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this patient?'),
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
      await db.delete('patients', where: 'id = ?', whereArgs: [id]);
      if (!mounted) return;
      await _fetchPatients();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🗑️ Patient deleted')));
    }
  }

  void _editPatient(Map<String, Object?> patient) {
    final firstNameController = TextEditingController(
      text: patient['first_name']?.toString() ?? '',
    );
    final secondNameController = TextEditingController(
      text: patient['second_name']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: patient['age']?.toString() ?? '',
    );
    final genderController = TextEditingController(
      text: patient['gender']?.toString() ?? '',
    );
    final contactController = TextEditingController(
      text: patient['contact']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Patient'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: secondNameController,
                decoration: const InputDecoration(labelText: 'Second Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: genderController,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
              ),
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
                'patients',
                {
                  'first_name': firstNameController.text.trim(),
                  'second_name': secondNameController.text.trim(),
                  'age': ageController.text.trim(),
                  'gender': genderController.text.trim(),
                  'contact': contactController.text.trim(),
                },
                where: 'id = ?',
                whereArgs: [patient['id']],
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              await _fetchPatients();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✏️ Patient updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ filter patients by search query
    final filteredPatients = patients.where((p) {
      final id = p['id']?.toString().toLowerCase() ?? '';
      final name = '${p['first_name'] ?? ''} ${p['second_name'] ?? ''}'
          .toLowerCase();
      return id.contains(searchQuery.toLowerCase()) ||
          name.contains(searchQuery.toLowerCase());
    }).toList();

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
              '👩‍⚕️ Patients List',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ✅ Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by ID or Name',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredPatients.isEmpty
                  ? const Text('No patients found.')
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Patient Code')),
                            DataColumn(label: Text('Full Name')),
                            DataColumn(label: Text('Age')),
                            DataColumn(label: Text('Gender')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Actions')),
                            DataColumn(label: Text('Reports')),
                          ],
                          rows: filteredPatients.map((p) {
                            final code = p['patient_code']?.toString() ?? '';
                            final reports =
                                patientReports[p['id']?.toString() ?? ''] ?? [];

                            return DataRow(
                              cells: [
                                DataCell(Text(code)),
                                DataCell(
                                  Text(
                                    '${p['first_name'] ?? ''} ${p['second_name'] ?? ''}',
                                  ),
                                ),
                                DataCell(Text('${p['age'] ?? ''}')),
                                DataCell(Text('${p['gender'] ?? ''}')),
                                DataCell(Text('${p['contact'] ?? ''}')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => _editPatient(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deletePatient(p['id'] as int),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  reports.isEmpty
                                      ? const Text('No reports')
                                      : Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: reports.map((r) {
                                            return IconButton(
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.red,
                                              ),
                                              onPressed: () => _openPdf(r),
                                              tooltip:
                                                  r['date']?.toString() ??
                                                  'Report',
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
