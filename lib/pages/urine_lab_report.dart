import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import 'patient_search_component.dart';
import 'specimens_component.dart';
import 'urinalysis_result_component.dart'; 
import 'urinalysis_pdf_preview_page.dart'; 
import '../utils/session_manager.dart';

class UrineLabReportPage extends StatefulWidget {
  const UrineLabReportPage({super.key});

  @override
  State<UrineLabReportPage> createState() => _UrineLabReportPageState();
}

class _UrineLabReportPageState extends State<UrineLabReportPage> {
  Map<String, dynamic>? selectedPatient;
  List<String> selectedSpecimens = [];
  List<Map<String, dynamic>> results = [];

  // ✅ Payment controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paidByController = TextEditingController();

  void _handlePatientSelected(Map<String, dynamic> patient) {
    setState(() => selectedPatient = patient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNav(
        onLogout: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
      drawer: const Sidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatientSearchComponent(onPatientSelected: _handlePatientSelected),
            const SizedBox(height: 20),

            if (selectedPatient != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Selected Patient: ${selectedPatient!['first_name']} '
                    '${selectedPatient!['second_name']} '
                    '(ID: ${selectedPatient!['id']})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            SpecimensComponent(
              onChanged: (specimens) {
                setState(() => selectedSpecimens = specimens);
              },
            ),
            const SizedBox(height: 30),

            const Text(
              'Urinalysis Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            UrinalysisResultsComponent(
              onResultsChanged: (res) {
                setState(() => results = res);
              },
            ),

            const SizedBox(height: 30),

            // ✅ Payment Section
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (UGX)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _paidByController,
              decoration: const InputDecoration(
                labelText: 'Paid By',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    if (selectedPatient == null || results.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a patient and enter urinalysis results before generating the PDF.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_amountController.text.isEmpty ||
                        _paidByController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter payment details before generating the PDF.',
                          ),
                        ),
                      );
                      return;
                    }

                    // ✅ Fetch current user from SharedPreferences
                    final currentUser = await SessionManager.getLoggedInUser();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UrinalysisPdfPreviewPage(
                          patient: selectedPatient,
                          specimens: selectedSpecimens,
                          results: results,
                          payment: {
                            'amount': _amountController.text,
                            'paid_by': _paidByController.text,
                          },
                          currentUser: currentUser ?? "Unknown User",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
