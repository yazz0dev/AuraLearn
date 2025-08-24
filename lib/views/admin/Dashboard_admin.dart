import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/services/firestore_cache_service.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin>
    with TickerProviderStateMixin {
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

  Future<void> _refreshData() async {
    setState(() {
      _userCountsFuture = _firestoreCache.getUserCounts(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // The AuthenticatedAppLayout is now handled by AdminLayout
    return FutureBuilder<Map<String, int>>(
      future: _userCountsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (isLoading) {
          return _buildLoadingSkeleton();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data found.'));
        }

        final counts = snapshot.data!;

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: PageTransitions.buildSubtlePageTransition(
            controller: _pageController,
            child: AnimationLimiter(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 200),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 15.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // --- Consistent Section Header ---
                      _AdminSectionHeader(title: 'Platform Overview'),
                      const SizedBox(height: 16),
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
                                const Text('Total Users',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70)),
                                const SizedBox(height: 8),
                                Text('${counts['total']}',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                const Text('+0%',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500)),
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
                      // --- Consistent Section Header ---
                      _AdminSectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildManagementCard(
                              icon: Icons.school_rounded,
                              color: Colors.deepPurple,
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
                              icon: Icons.people_alt_rounded,
                              color: Colors.blue,
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
                      // --- Consistent Section Header ---
                      _AdminSectionHeader(title: 'Review Queue'),
                      const SizedBox(height: 16),
                      _buildReviewQueue(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
              isLoading: true, child: _AdminSectionHeader(title: '')),
          const SizedBox(height: 16),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.card(
                height: 120, padding: const EdgeInsets.all(20)),
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
          const SizedBox(height: 28),
          SkeletonLoader(
              isLoading: true, child: _AdminSectionHeader(title: '')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  isLoading: true,
                  child: SkeletonShapes.card(height: 120),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SkeletonLoader(
                  isLoading: true,
                  child: SkeletonShapes.card(height: 120),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SkeletonLoader(
              isLoading: true, child: _AdminSectionHeader(title: '')),
          const SizedBox(height: 16),
          SkeletonLoader(
            isLoading: true,
            child: SkeletonShapes.listTile(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(value,
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildManagementCard(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5), // Very subtle background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white),
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

  // --- FIX: Updated to fetch subjects pending review and display correct counts ---
  Widget _buildReviewQueue() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreCache.getSubjectsPendingReview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEmptyStateCard('Loading review queue...');
        }

        if (snapshot.hasError) {
          debugPrint('Review queue error: ${snapshot.error}');
          return _buildEmptyStateCard('Error loading review queue');
        }

        final subjects = snapshot.data ?? [];

        if (subjects.isEmpty) {
          return _buildEmptyStateCard('No items in review queue');
        }

        return Column(
          children: subjects.map((subjectData) {
            final subjectId = subjectData['_id'] ?? 'unknown';
            final subjectName = subjectData['name'] ?? 'Unknown Subject';
            final topicCount = subjectData['total_topics'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.library_books,
                    color: Colors.blue,
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
                          '$topicCount topic(s) ready for review',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.go('/admin/review-subject/$subjectId'),
                    child: const Text(
                      'Review',
                      style: TextStyle(color: Colors.blue),
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

// Reusable header widget for consistent design
class _AdminSectionHeader extends StatelessWidget {
  final String title;
  const _AdminSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white));
  }
}