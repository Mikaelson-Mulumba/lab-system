import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopNav extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;

  const TopNav({super.key, required this.onLogout});

  @override
  State<TopNav> createState() => _TopNavState();

  @override
  Size get preferredSize => const Size.fromHeight(65);
}

class _TopNavState extends State<TopNav> {
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'User'; // fallback
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blueAccent,
      elevation: 4,
      titleSpacing: 0,
      toolbarHeight: 65,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo + Brand
          Row(
            children: [
              Image.asset(
                'assets/images/lab-logo.png',
                height: 42,
              ),
              const SizedBox(width: 12),
              const Text(
                'Powers Laboratories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Right: User profile + Logout
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings'); // link to settings
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        role ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: widget.onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
