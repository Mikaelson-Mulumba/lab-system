import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = '';
  int patientCount = 0;
  int reportCount = 0;
  int stockCount = 0;

  List<Map<String, dynamic>> recentPatients = [];
  List<Map<String, dynamic>> recentReports = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
    _loadRecentActivity();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('loggedInUser') ?? 'User';
    });
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;

    final patients = await db.query('patients');
    final reports = await db.query('reports');
    final stock = await db.query('stock');

    setState(() {
      patientCount = patients.length;
      reportCount = reports.length;
      stockCount = stock.length;
    });
  }

  Future<void> _loadRecentActivity() async {
    final db = await DatabaseHelper.instance.database;

    // Get first 5 patients
    final patients = await db.query(
      'patients',
      limit: 5,
    );

    // Get first 5 reports
    final reports = await db.query(
      'reports',
      limit: 5,
    );

    // For each report, fetch patient info
    List<Map<String, dynamic>> enrichedReports = [];
    for (var report in reports) {
      final patientId = report['patient_id'];
      String patientName = '';

      if (patientId != null) {
        final patientResult = await db.query(
          'patients',
          where: 'id = ?',
          whereArgs: [patientId],
          limit: 1,
        );
        if (patientResult.isNotEmpty) {
          final patient = patientResult.first;
          patientName =
              '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}';
        }
      }

      enrichedReports.add({
        ...report,
        'patient_display': 'ID: $patientId - $patientName',
      });
    }

    setState(() {
      recentPatients = patients;
      recentReports = enrichedReports;
    });
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text('$count',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList(
      String title,
      List<Map<String, dynamic>> items,
      IconData icon,
      Color color,
      String displayField,
      String route) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(icon, color: color),
              title: Text(item[displayField]?.toString() ?? 'Unknown'),
              subtitle: Text('ID: ${item['id'] ?? ''}'),
              onTap: () {
                Navigator.pushNamed(context, route, arguments: item);
              },
            ),
          );
        }),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Card(
              color: Colors.blueAccent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.dashboard, color: Colors.white, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back, $username!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        Text(
                          'Today: ${DateTime.now().toLocal().toString().split(" ")[0]}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick stats
            Row(
              children: [
                _buildStatCard('Patients', patientCount, Icons.people,
                    Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Reports', reportCount, Icons.assignment,
                    Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Stock Items', stockCount, Icons.inventory,
                    Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add-patient'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Patient'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/lab-report'),
                  icon: const Icon(Icons.science),
                  label: const Text('Generate Report'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/stock-addition'),
                  icon: const Icon(Icons.add_box),
                  label: const Text('Add Stock'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent activity
            _buildRecentList('Recent Patients', recentPatients, Icons.person,
                Colors.blueAccent, 'first_name', '/patients'),
            const SizedBox(height: 20),
            _buildRecentList('Recent Reports', recentReports, Icons.assignment,
                Colors.orange, 'patient_display', '/reports'),
          ],
        ),
      ),
    );
  }
}
