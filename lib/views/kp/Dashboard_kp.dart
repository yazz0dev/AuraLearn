import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class DashboardKP extends StatefulWidget {
  const DashboardKP({super.key});

  @override
  State<DashboardKP> createState() => _DashboardKPState();
}

class _DashboardKPState extends State<DashboardKP>
    with SingleTickerProviderStateMixin {
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
    // Since we only have one navigation item (My Subjects), 
    // we don't need to handle navigation changes
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Only one case now - My Subjects (index 0)
    if (index == 0 && mounted) {
      context.go('/kp/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.kp,
      appBarTitle: 'My Subjects',
      appBarActions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'test_logout':
                // Test logout functionality
                debugPrint('Test logout from KP dashboard');
                final BuildContext currentContext = context;
                try {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  if (!currentContext.mounted) return;
                  ScaffoldMessenger.of(currentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Logout successful from KP dashboard'),
                    ),
                  );
                } catch (e) {
                  debugPrint('Test logout error: $e');
                }
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'test_logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Test Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          color: const Color(0xFF2C2C2C),
          icon: const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal,
            child: Icon(Icons.school, color: Colors.white, size: 16),
          ),
        ),
      ],
      showBottomBar: true,
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onBottomNavTap,
      child: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 200),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 15.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              _buildSubjectCard(
                status: 'Syllabus Pending',
                title: 'Subject 1',
                description: 'Upload the syllabus to proceed.',
                buttonText: 'Upload Syllabus',
                imageColor: const Color(0xFFD6C6C2),
                onButtonPressed: () {},
              ),
              const SizedBox(height: 24),
              _buildSubjectCard(
                status: 'Ready for Material',
                title: 'Subject 2',
                description: 'Study material can now be uploaded.',
                buttonText: 'Upload Study Material',
                imageColor: const Color(0xFFF2CACA),
                onButtonPressed: () {},
              ),
              const SizedBox(height: 24),
              _buildSubjectCard(
                status: 'Awaiting Review',
                title: 'Subject 3',
                description: 'Review Uploaded content.',
                buttonText: 'Review',
                imageColor: const Color(0xFFC7A8A3),
                onButtonPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard({
    required String status,
    required String title,
    required String description,
    required String buttonText,
    required Color imageColor,
    required VoidCallback onButtonPressed,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  // --- FIX: Replaced deprecated `withOpacity` with `withAlpha` ---
                  backgroundColor: Colors.white.withAlpha(
                    230,
                  ), // 255 * 0.9 = 229.5 -> 230
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: imageColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
