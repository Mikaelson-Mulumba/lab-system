import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';

class PatientDetailPage extends StatelessWidget {
  final String patientId;

  const PatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    // 🚀 Temporary mock data (replace with SQLite or API later)
    final patient = {
      'id': patientId,
      'firstName': 'John',
      'secondName': 'Doe',
      'age': '35',
      'gender': 'Male',
      'dateOfBirth': '1990-01-01',
      'contact': '+256700000000',
      'address': 'Kampala, Uganda',
      'email': 'john.doe@example.com',
      'requestedBy': 'Dr. Smith',
      'collectedBy': 'Nurse Jane',
    };

    final reports = [
      {
        'reportId': 'R001',
        'specimens': 'Blood, Urine',
        'investigations': 'CBC, ESR',
        'results': 'Normal ranges',
        'comments': 'No abnormalities detected',
      },
      {
        'reportId': 'R002',
        'specimens': 'Stool',
        'investigations': 'Stool analysis',
        'results': 'Parasites detected',
        'comments': 'Treatment recommended',
      },
    ];

    return Scaffold(
      // Top navigation bar
      appBar: TopNav(
        onLogout: () {
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),

      // Sidebar navigation
      drawer: const Sidebar(),

      // Main content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 Patient Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Patient card
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${patient['id']}'),
                    Text('Name: ${patient['firstName']} ${patient['secondName']}'),
                    Text('Age: ${patient['age']}'),
                    Text('Gender: ${patient['gender']}'),
                    Text('Date of Birth: ${patient['dateOfBirth']}'),
                    Text('Contact: ${patient['contact']}'),
                    Text('Address: ${patient['address']}'),
                    Text('Email: ${patient['email']}'),
                    Text('Requested By: ${patient['requestedBy']}'),
                    Text('Collected By: ${patient['collectedBy']}'),
                  ],
                ),
              ),
            ),

            const Text(
              '🧪 Lab Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            reports.isEmpty
                ? const Text('No reports found for this patient.')
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Report ID')),
                      DataColumn(label: Text('Specimens')),
                      DataColumn(label: Text('Investigations')),
                      DataColumn(label: Text('Results')),
                      DataColumn(label: Text('Comments')),
                    ],
                    rows: reports
                        .map(
                          (r) => DataRow(cells: [
                            DataCell(Text(r['reportId']!)),
                            DataCell(Text(r['specimens']!)),
                            DataCell(Text(r['investigations']!)),
                            DataCell(Text(r['results']!)),
                            DataCell(Text(r['comments']!)),
                          ]),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
