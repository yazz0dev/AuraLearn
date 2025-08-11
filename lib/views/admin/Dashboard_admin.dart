import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/views/admin/user_management.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../components/bottom_bar.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  int _currentIndex = 0;
  late Future<Map<String, int>> _userCountsFuture;

  @override
  void initState() {
    super.initState();
    _userCountsFuture = _fetchUserCounts();
  }

  // --- Fetches user counts from Firestore ---
  Future<Map<String, int>> _fetchUserCounts() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    
    // Perform queries to get counts
    final totalUsersQuery = await usersCollection.count().get();
    final studentUsersQuery = await usersCollection.where('role', isEqualTo: 'Student').count().get();
    final kpUsersQuery = await usersCollection.where('role', isEqualTo: 'KP').count().get();

    // --- FIX: Handle nullable int? from .count by providing a default of 0 ---
    return {
      'total': totalUsersQuery.count ?? 0,
      'students': studentUsersQuery.count ?? 0,
      'kps': kpUsersQuery.count ?? 0,
    };
  }


  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const UserManagementScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'AuraLearn Admin',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      child: FutureBuilder<Map<String, int>>(
        future: _userCountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          final counts = snapshot.data!;

          return AnimationLimiter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Admin Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text('${counts['total']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              // Placeholder for growth
                              const Text('+0%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatRow('Active Students This Week', '**'),
                    const SizedBox(height: 8),
                    _buildStatRow('Students', '${counts['students']}'),
                    const SizedBox(height: 8),
                    _buildStatRow('KPs', '${counts['kps']}'),
                    const SizedBox(height: 8),
                    _buildStatRow('Subjects', '*'),
                    const SizedBox(height: 28),
                    const Text('Platform Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildManagementCard(
                            color: const Color(0xFF2C2C2C),
                            iconColor: Colors.grey.shade800,
                            title: 'Manage Subjects',
                            subtitle: '* Subjects',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildManagementCard(
                            color: Colors.green.withAlpha(25),
                            iconColor: Colors.green.withAlpha(76),
                            title: 'Manage Users',
                            subtitle: '${counts['total']} Users',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('Review Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildReviewQueueCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildManagementCard({required Color color, required Color iconColor, required String title, required String subtitle}) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueueCard() {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(76),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Subject', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                Text('X Chunks Awaiting Approval', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}