import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
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

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Handle navigation based on index
    switch (index) {
      case 0:
        // Dashboard - already here
        if (mounted) context.go('/student/dashboard');
        break;
      case 1:
        // Subjects - navigate to subjects screen
        if (mounted) context.go('/student/subjects');
        break;
      case 2:
        // Schedule - navigate to schedule screen
        if (mounted) context.go('/student/schedule');
        break;
      case 3:
        // Progress - navigate to progress screen
        if (mounted) context.go('/student/progress');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.student,
      appBarTitle: 'Dashboard',
      appBarActions: [
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            context.push('/student/profile');
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey,
              backgroundImage: NetworkImage('https://picsum.photos/seed/student_avatar/150/150'),
            ),
          ),
        ),
      ],
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onBottomNavTap,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              future: _getUserName(),
              builder: (context, snapshot) {
                final name = snapshot.data ?? 'Student';
                return Text(
                  'Welcome back, $name!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
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
        Text('Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
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
        Text('Upcoming Topics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        _buildEmptyStateCard(
          'No upcoming topics',
          'Topics will appear here once you start a subject.',
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Future<String> _getUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Student';
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'Student';
      }
      return 'Student';
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Student';
    }
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
