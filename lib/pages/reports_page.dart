import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> reports = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    final data = await DatabaseHelper.instance.getAllReports();
    if (!mounted) return;
    setState(() {
      reports = data;
    });
  }

  Future<void> _deleteReport(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('reports', where: 'id = ?', whereArgs: [id]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report deleted')),
    );

    _fetchReports(); // refresh list
  }

  void _openPdf(Map<String, dynamic> report) {
    final pdfBytes = report['pdf_data'];
    if (pdfBytes == null) {
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
          child: PdfPreview(
            build: (format) async => bytes,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = reports.where((r) {
      final query = search.toLowerCase();
      return (r['patient_id'] ?? '').toString().toLowerCase().contains(query) ||
          (r['created_at'] ?? '').toString().toLowerCase().contains(query);
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
              '🧪 All Lab Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by patient ID or date...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                setState(() {
                  search = val;
                });
              },
            ),
            const SizedBox(height: 20),

            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(child: Text('No reports found.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Report ID')),
                          DataColumn(label: Text('Patient ID')),
                          DataColumn(label: Text('Created At')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filteredReports.map((r) {
                          return DataRow(cells: [
                            DataCell(Text(r['id'].toString())),
                            DataCell(Text(r['patient_id'] ?? '')),
                            DataCell(Text(r['created_at'] ?? '')),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: Colors.red),
                                  onPressed: () => _openPdf(r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.grey),
                                  onPressed: () => _deleteReport(r['id']),
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
