import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role'); // ✅ store this at login
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Text(
              'Powers Laboratories',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(context, '🏠 Dashboard', '/dashboard'),
          _buildNavItem(context, '➕ Add Stock', '/stock-addition'),
          _buildNavItem(context, '📦 Stock', '/stock-list'),
          _buildNavItem(context, '➕ Add Patient', '/add-patient'),
          _buildNavItem(context, '👩‍⚕️ Patients', '/patients'),
          _buildNavItem(context, '🧪 Lab Report', '/lab-report'),
          _buildNavItem(context, '🧪 Urine Lab Report', '/urine-lab-report'),
          _buildNavItem(context, '📊 Reports', '/reports'),

          // ✅ Only show if role == 'Admin'
          if (role?.toLowerCase() == 'admin') _buildNavItem(context, '👥 Users', '/users'),

          _buildNavItem(context, '⚙️ Settings', '/settings'),
          
          _buildNavItem(context, '➕ Specimen', '/specimen'),
          _buildNavItem(context, '📑 Test List', '/test-type-list'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}
