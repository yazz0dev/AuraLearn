import 'package:auralearn/components/authenticated_app_layout.dart';
// import 'package:auralearn/views/admin/user_management.dart'; // No longer needed for navigation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import '../../components/bottom_bar.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late Future<Map<String, int>> _userCountsFuture;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _userCountsFuture = _fetchUserCounts();
    _shimmerController = AnimationController.unbounded(vsync: this)..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));
  }
  
  @override
  dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<Map<String, int>> _fetchUserCounts() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    
    final totalUsersQuery = await usersCollection.count().get();
    final studentUsersQuery = await usersCollection.where('role', isEqualTo: 'Student').count().get();
    final kpUsersQuery = await usersCollection.where('role', isEqualTo: 'KP').count().get();

    return {
      'total': totalUsersQuery.count ?? 0,
      'students': studentUsersQuery.count ?? 0,
      'kps': kpUsersQuery.count ?? 0,
    };
  }


  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Dashboard - already here, no navigation needed
        break;
      case 1:
        // Navigate to user management screen
        context.go('/admin/users');
        break;
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
            return _buildLoadingSkeleton();
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
                  duration: const Duration(milliseconds: 200),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 15.0,
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
                              const Text('+0%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatRow('Students', '${counts['students']}'),
                    const SizedBox(height: 8),
                    _buildStatRow('KPs', '${counts['kps']}'),
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
                            subtitle: 'Coming Soon',
                            onTap: () {
                              if (!mounted) return;
                              context.go('/admin/create-subject');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildManagementCard(
                            color: Colors.green.withAlpha(25),
                            iconColor: Colors.green.withAlpha(76),
                            title: 'Manage Users',
                            subtitle: '${counts['total']} Users',
                            onTap: () {
                              if (!mounted) return;
                              context.go('/admin/users');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Review Content card (full width)
                    GestureDetector(
                      onTap: () {
                        if (!mounted) return;
                        context.go('/admin/review-content');
                      },
                      child: Container(
                        height: 72,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.pink.withAlpha(60), borderRadius: BorderRadius.circular(12))),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Review Content', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Review Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildEmptyStateCard('No items in review queue'),
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

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // --- FIX: Corrected variable declaration from `final-gradient` to `final gradient` ---
          final gradient = LinearGradient(
            colors: const [Color(0xFF1E1E1E), Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
            stops: const [0.4, 0.5, 0.6],
            begin: const Alignment(-1.0, -0.3),
            end: const Alignment(1.0, 0.3),
            transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
          );
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            // --- FIX: Correctly reference the `gradient` variable ---
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildSkeletonBox(height: 24, width: 200, isCentered: true),
            const SizedBox(height: 20),
            _buildSkeletonBox(height: 120, width: 340, isCentered: true),
            const SizedBox(height: 24),
            _buildSkeletonBox(height: 16, width: double.infinity),
            const SizedBox(height: 8),
            _buildSkeletonBox(height: 16, width: double.infinity),
            const SizedBox(height: 8),
            _buildSkeletonBox(height: 16, width: double.infinity),
            const SizedBox(height: 28),
            _buildSkeletonBox(height: 22, width: 220),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSkeletonBox(height: 80)),
                const SizedBox(width: 16),
                Expanded(child: _buildSkeletonBox(height: 80)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({required double height, double? width, bool isCentered = false}) {
    Widget box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white, // This will be masked by the shader
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return isCentered ? Center(child: box) : box;
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

  Widget _buildManagementCard({required Color color, required Color iconColor, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
             child: FittedBox(
               fit: BoxFit.scaleDown,
               alignment: Alignment.centerLeft,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     title,
                     style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     subtitle,
                     style: const TextStyle(fontSize: 12, color: Colors.white70),
                   ),
                 ],
               ),
             ),
           ),
         ],
       ),
     )
    );
   }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Colors.white.withAlpha(128),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}