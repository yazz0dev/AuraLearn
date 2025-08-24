import 'package:auralearn/components/skeleton_loader.dart';
import 'package:auralearn/services/user_data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  // Animation controller is for content animations within this page, so it stays.
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- FIX: Removed all navigation logic and the AuthenticatedAppLayout wrapper ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserDataService().getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        return AnimationLimiter(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 200),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 15.0,
                child: FadeInAnimation(child: widget),
              ),
              children: [
                const SizedBox(height: 20),
                FutureBuilder<String>(
                  future: UserDataService().getUserName(),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'Student';
                    return Text(
                      'Welcome back, $name!',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 26),
                    );
                  },
                ),
                const SizedBox(height: 30),
                _buildSubjectCard(),
                const SizedBox(height: 30),
                _buildProgressSection(),
                const SizedBox(height: 30),
                _buildUpcomingTopicsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard() {
    return _buildEmptyStateCard(
      'No subjects assigned yet',
      'Contact your administrator to get started with your learning journey.',
      Icons.school_outlined,
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _buildEmptyStateCard(
          'No progress to show',
          'Start learning to track your progress here.',
          Icons.bar_chart_outlined,
        ),
      ],
    );
  }

  Widget _buildUpcomingTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Topics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _buildEmptyStateCard(
          'No upcoming topics',
          'Topics will appear here once you start a subject.',
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        // Welcome text skeleton
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.text(width: 250, height: 32),
        ),
        const SizedBox(height: 30),
        // Subject card skeleton
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.card(height: 120),
        ),
        const SizedBox(height: 30),
        // Progress section skeleton
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.text(width: 100, height: 20),
        ),
        const SizedBox(height: 16),
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.card(height: 120),
        ),
        const SizedBox(height: 30),
        // Upcoming topics skeleton
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.text(width: 150, height: 20),
        ),
        const SizedBox(height: 16),
        SkeletonLoader(
          isLoading: true,
          child: SkeletonShapes.card(height: 120),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyStateCard(String title, String subtitle, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}