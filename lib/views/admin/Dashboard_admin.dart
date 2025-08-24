import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/services/firestore_cache_service.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../enums/user_role.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late Future<Map<String, int>> _userCountsFuture;
  final FirestoreCacheService _firestoreCache = FirestoreCacheService();

  late final AnimationController _pageController;

  @override
  void initState() {
    super.initState();
    _userCountsFuture = _fetchUserCounts();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _pageController.forward();
  }
  
  @override
  dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Map<String, int>> _fetchUserCounts() async {
    return await _firestoreCache.getUserCounts();
  }


  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    // Handle navigation based on index with smooth transitions
    _navigateWithTransition(index);
  }

  void _navigateWithTransition(int index) {
    // Show a subtle loading transition
    setState(() {
      _currentIndex = index;
    });

    // Add a small delay for smooth transition feel
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      switch (index) {
        case 0:
          // Dashboard - already here, no navigation needed
          break;
        case 1:
          // Navigate to user management screen
          context.go('/admin/users');
          break;
        case 2:
          // Navigate to subjects screen
          context.go('/admin/subjects');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: 'AuraLearn Admin',
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      showLogoutButton: true, 
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

          return PageTransitions.buildSubtlePageTransition(
            controller: _pageController,
            child: AnimationLimiter(
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
                            color: const Color.fromARGB(255, 176, 196, 97).withAlpha(25),
                            iconColor: const Color.fromARGB(255, 163, 187, 206).withAlpha(76),
                            title: 'Manage Subjects',
                            subtitle: 'View & Edit',
                            onTap: () {
                              if (!mounted) return;
                              context.go('/admin/subjects');
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
                    const SizedBox(height: 32),
                    const Text('Review Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 16),
                    _buildReviewQueue(),
                    const SizedBox(height: 32),
                  ],
                ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.text(width: 200, height: 24),
          ),
          const SizedBox(height: 20),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.card(height: 120, padding: const EdgeInsets.all(20)),
          ),
          const SizedBox(height: 24),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.text(width: double.infinity, height: 16),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.text(width: double.infinity, height: 16),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.text(width: double.infinity, height: 16),
          ),
          const SizedBox(height: 28),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.text(width: 220, height: 22),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  isLoading: true,
                  child: SkeletonShapes.card(height: 80),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SkeletonLoader(
                  isLoading: true,
                  child: SkeletonShapes.card(height: 80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
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

  Widget _buildManagementCard({required Color color, required Color iconColor, required String title, required String subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5), // Very subtle background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
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

  Widget _buildReviewQueue() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreCache.getTopicsPendingReview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEmptyStateCard('Loading review queue...');
        }

        if (snapshot.hasError) {
          debugPrint('Review queue error: ${snapshot.error}');
          return _buildEmptyStateCard('Error loading review queue');
        }

        final topics = snapshot.data ?? [];

        if (topics.isEmpty) {
          return _buildEmptyStateCard('No items in review queue');
        }

        // Group topics by subject
        final Map<String, Map<String, dynamic>> subjectsToReview = {};
        for (var topic in topics) {
          final subjectId = topic['_path']?.split('/')[1] ?? 'unknown';
          final subjectName = topic['subject_name'] ?? 'Unknown Subject';

          if (!subjectsToReview.containsKey(subjectId)) {
            subjectsToReview[subjectId] = {
              'name': subjectName,
              'topic_count': 0
            };
          }
          subjectsToReview[subjectId]!['topic_count']++;
        }

        if (subjectsToReview.isEmpty) {
          return _buildEmptyStateCard('No items in review queue');
        }

        return Column(
          children: subjectsToReview.entries.map((entry) {
            final subjectId = entry.key;
            final subjectData = entry.value;
            final subjectName = subjectData['name'];
            final topicCount = subjectData['topic_count'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.library_books,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subjectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$topicCount topic(s) to review',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/admin/review-subject/$subjectId'),
                    child: const Text(
                      'Review',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

