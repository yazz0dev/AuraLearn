import 'package:flutter/material.dart';
import '../../components/bottom_bar.dart';
import '../../components/top_navigation_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _currentIndex = 2;
  String _search = '';
  String _selectedRole = 'All';
  final List<String> _roles = ['All', 'KP', 'Student', 'Admin'];
  final List<Map<String, String>> _users = [
    {'name': 'User 1 (KP)', 'email': 'user1@email.com', 'role': 'KP'},
    {'name': 'User 2', 'email': 'user2@email.com', 'role': 'Student'},
    {'name': 'User 3', 'email': 'user3@email.com', 'role': 'Student'},
    {'name': 'User 4 (KP)', 'email': 'user4@email.com', 'role': 'KP'},
    {'name': 'User 5', 'email': 'user5@email.com', 'role': 'Student'},
  ];

  List<Map<String, String>> get _filteredUsers {
    return _users.where((user) {
      final matchesRole = _selectedRole == 'All' || user['role'] == _selectedRole;
      final matchesSearch = user['name']!.toLowerCase().contains(_search.toLowerCase()) ||
          user['email']!.toLowerCase().contains(_search.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts[0].length <= 2) return '*****@${parts[1]}';
    return '*****@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavigationBar(),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'User Management',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    hintText: 'Search  by name or email...'
                  ),
                  onChanged: (val) => setState(() => _search = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: _roles.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6D6F7),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, idx) {
                  final user = _filteredUsers[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(_maskEmail(user['email']!), style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomBar(
        currentIndex: _currentIndex,
        onTap: (idx) {
          setState(() { _currentIndex = idx; });
          // Navigation logic can be added here
        },
      ),
    );
  }
}
