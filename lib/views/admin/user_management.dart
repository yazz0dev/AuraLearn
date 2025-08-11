import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../components/bottom_bar.dart';

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
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'User Management',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: (idx) {
        setState(() {
          _currentIndex = idx;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24)
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Colors.white54)
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
                Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF2C2C2C)),
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    underline: Container(),
                    items: _roles.map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha(51),
                    foregroundColor: Colors.blue.shade200,
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
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, idx) {
                  final user = _filteredUsers[idx];
                  return AnimationConfiguration.staggeredList(
                    position: idx,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                                    Text(_maskEmail(user['email']!), style: const TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C2C2C),
                                  foregroundColor: Colors.white70,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}