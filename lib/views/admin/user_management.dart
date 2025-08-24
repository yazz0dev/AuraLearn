import 'package:auralearn/components/skeleton_loader.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:async';
import 'components/add_user_dialog.dart';
import 'components/delete_confirmation_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<String> _roles = ['All', 'Admin', 'KP', 'Student'];
  String _selectedRole = 'All';
  String _debouncedSearch = '';
  Timer? _searchDebounceTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => const AddUserDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return _buildLoadingSkeleton();
                }
                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final allUsers = snapshot.data?.docs ?? [];
                final searchTerm = _debouncedSearch.toLowerCase().trim();
                final filteredUsers = allUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedRole != 'All' && data['role'] != _selectedRole) return false;
                  if (searchTerm.isEmpty) return true;
                  final name = data['name']?.toLowerCase() ?? '';
                  final email = data['email']?.toLowerCase() ?? '';
                  return name.contains(searchTerm) || email.contains(searchTerm);
                }).toList();

                if (filteredUsers.isEmpty && allUsers.isNotEmpty) {
                  return _buildEmptyState(message: 'No users match your filters.');
                }
                if (allUsers.isEmpty) {
                  return _buildEmptyState(message: 'No users found. Add one to get started!');
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final userDoc = filteredUsers[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _UserCard(
                                key: ValueKey(userDoc.id),
                                userData: userDoc.data() as Map<String, dynamic>,
                                userId: userDoc.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  _searchDebounceTimer?.cancel();
                  _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _debouncedSearch = value);
                  });
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _debouncedSearch = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ToggleButtons(
                        isSelected: _roles.map((role) => role == _selectedRole).toList(),
                        onPressed: (index) {
                          setState(() => _selectedRole = _roles[index]);
                        },
                        borderRadius: BorderRadius.circular(8),
                        borderColor: Colors.white30,
                        selectedBorderColor: Colors.deepPurple,
                        selectedColor: Colors.white,
                        fillColor: Colors.deepPurple.withAlpha(100),
                        color: Colors.white70,
                        // --- FIX: Removed unsupported 'visualDensity' and used padding for compact design ---
                        children: _roles.map((role) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjusted padding
                          child: Text(role),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _showAddUserDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SkeletonLoader(isLoading: true, child: SkeletonShapes.card(height: 120)),
        const SizedBox(height: 16),
        ...List.generate(5, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SkeletonLoader(isLoading: true, child: SkeletonShapes.card(height: 70)),
        )),
      ],
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, color: Colors.red, size: 48),
        SizedBox(height: 16),
        Text('Failed to load users', style: TextStyle(color: Colors.white70)),
      ]),
    );
  }

  Widget _buildEmptyState({required String message}) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.people_outline, size: 48, color: Colors.white38),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _UserCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const _UserCard({super.key, required this.userData, required this.userId});

  @override
  State<_UserCard> createState() => __UserCardState();
}

class __UserCardState extends State<_UserCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      // --- FIX: Add curly braces to satisfy linter ---
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(userName: widget.userData['name'], userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.userData['role'] ?? 'Unknown';
    final roleColor = _getRoleColor(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _toggleExpansion,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_getRoleIcon(role), color: roleColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userData['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(widget.userData['email'] ?? 'No Email', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  AnimatedRotation(turns: _isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 250), child: const Icon(Icons.expand_more, color: Colors.white70)),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 12),
                    _buildDetailRow('Created:', widget.userData['createdAt'] != null ? _formatDate((widget.userData['createdAt'] as Timestamp).toDate()) : 'N/A'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (role != 'Student')
                          OutlinedButton.icon(
                            onPressed: _showDeleteDialog,
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade300),
                            label: Text('Delete', style: TextStyle(color: Colors.red.shade300)),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade300, side: BorderSide(color: Colors.red.shade300.withAlpha(100))),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ],
  );

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin': return Icons.admin_panel_settings_rounded;
      case 'KP': return Icons.school_rounded;
      case 'Student': return Icons.person_rounded;
      default: return Icons.account_circle_rounded;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin': return Colors.red.shade400;
      case 'KP': return Colors.green.shade400;
      case 'Student': return Colors.blue.shade400;
      default: return Colors.grey.shade400;
    }
  }
}