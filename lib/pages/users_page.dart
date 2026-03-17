import 'package:flutter/material.dart';
import '../widgets/top_nav.dart';
import '../widgets/sidebar.dart';
import '../db/database_helper.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String password = '';
  String role = '';

  List<Map<String, Object?>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('users');
    if (!mounted) return;
    setState(() {
      users = result;
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = await DatabaseHelper.instance.database;
      await db.insert('users', {
        'username': username,
        'password': password,
        'role': role,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ User added successfully!')),
      );

      _formKey.currentState!.reset();
      setState(() {
        username = '';
        password = '';
        role = '';
      });

      _fetchUsers();
    }
  }

  Future<void> _deleteUser(String username) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users', where: 'username = ?', whereArgs: [username]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ User $username deleted')),
    );

    _fetchUsers();
  }

  void _editUser(Map<String, Object?> user) {
    showDialog(
      context: context,
      builder: (_) {
        String newPassword = user['password']?.toString() ?? '';
        String newRole = user['role']?.toString() ?? '';

        return AlertDialog(
          title: Text('Edit User: ${user['username']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: newPassword,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => newPassword = val,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: newRole.isEmpty ? null : newRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Lab Technician', child: Text('Lab Technician')),
                ],
                onChanged: (val) => newRole = val ?? '',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'users',
                  {'password': newPassword, 'role': newRole},
                  where: 'username = ?',
                  whereArgs: [user['username']],
                );

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✏️ User ${user['username']} updated')),
                );
                _fetchUsers();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
            const Text(
              '👥 Manage Users',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // User form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    onSaved: (val) => username = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please enter username' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onSaved: (val) => password = val ?? '',
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please enter password' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: role.isEmpty ? null : role,
                    items: const [
                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'Lab Technician', child: Text('Lab Technician')),
                    ],
                    onChanged: (val) => setState(() => role = val ?? ''),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please select a role' : null,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add User',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              '📋 User List',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            users.isEmpty
                ? const Text('No users found.')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Password')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: users.map((u) {
                        return DataRow(cells: [
                          DataCell(Text('${u['username'] ?? ''}')),
                          DataCell(Text('${u['password'] ?? ''}')),
                          DataCell(Text('${u['role'] ?? ''}')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editUser(u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(u['username'] as String),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
