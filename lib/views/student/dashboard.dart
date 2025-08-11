import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:flutter/material.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // --- FIX: This screen now inherits its theme from AuthenticatedAppLayout. ---
    return AuthenticatedAppLayout(
      role: UserRole.student,
      appBarTitle: 'Dashboard',
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Placeholder image
              ),
              const SizedBox(height: 2),
              Text(
                'profile',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
      bottomNavIndex: _currentIndex,
      onBottomNavTap: (index) => setState(() => _currentIndex = index),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        Text(
          'Welcome back, Name!',
          // --- FIX: Removed hardcoded color to inherit from theme ---
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 30),
        _buildSubjectCard(),
        const SizedBox(height: 30),
        _buildProgressSection(),
        const SizedBox(height: 30),
        _buildUpcomingTopicsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSubjectCard() {
    return Card(
      // --- FIX: color is now handled by the layout's theme ---
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject Name', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('description', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('X lessons', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              // --- FIX: Style is inherited from theme, but can be customized ---
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Start Learning'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Topics Mastered', style: Theme.of(context).textTheme.bodyMedium),
            Text('5 / 12', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 5 / 12,
          // --- FIX: Colors now adapt to the current theme ---
          backgroundColor: Theme.of(context).progressIndicatorTheme.linearTrackColor,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildUpcomingTopicsSection() {
    final topics = ['Topic 1', 'Topic 2', 'Topic 3'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Topics', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            return ListTile(
              // --- FIX: Text color now inherited from theme ---
              title: Text(topics[index], style: const TextStyle(fontWeight: FontWeight.w500)),
              contentPadding: EdgeInsets.zero,
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 1),
        ),
      ],
    );
  }
}