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
    // The screen is now wrapped by AuthenticatedAppLayout, which handles the theme and structure.
    return AuthenticatedAppLayout(
      role: UserRole.student,
      appBarTitle: 'Dashboard',
      appBarActions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Placeholder image
              ),
              const SizedBox(height: 2),
              Text('profile', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
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
        const Text(
          'Welcome back, Name!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
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
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subject Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text('description', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('X lessons', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80F0),
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
        const Text('Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Topics Mastered', style: TextStyle(color: Colors.black54)),
            const Text('5 / 12', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 5 / 12,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
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
        const Text('Upcoming Topics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(topics[index], style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
              contentPadding: EdgeInsets.zero,
            );
          },
          separatorBuilder: (context, index) => const Divider(height: 1),
        ),
      ],
    );
  }
}