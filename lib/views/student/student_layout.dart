import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/enums/user_role.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:auralearn/views/student/progress_screen.dart';
import 'package:auralearn/views/student/schedule_screen.dart';
import 'package:auralearn/views/student/subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentLayout extends StatefulWidget {
  final String page;
  const StudentLayout({super.key, required this.page});

  @override
  State<StudentLayout> createState() => _StudentLayoutState();
}

class _StudentLayoutState extends State<StudentLayout> {
  late int _currentIndex;

  final Map<String, int> _pageMap = {
    'dashboard': 0,
    'subjects': 1,
    'schedule': 2,
    'progress': 3,
  };

  @override
  void initState() {
    super.initState();
    _updateIndex(widget.page);
  }

  @override
  void didUpdateWidget(StudentLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _updateIndex(widget.page);
    }
  }

  void _updateIndex(String pageName) {
    setState(() {
      _currentIndex = _pageMap[pageName] ?? 0;
    });
  }

  void _onNavigate(int index) {
    if (index == _currentIndex) return;

    final pageName = _pageMap.entries.firstWhere((entry) => entry.value == index).key;
    context.go('/student/$pageName');
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Subjects';
      case 2:
        return 'My Schedule';
      case 3:
        return 'My Progress';
      default:
        return 'AuraLearn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthenticatedAppLayout(
      role: UserRole.student,
      appBarTitle: _getAppBarTitle(),
      // --- FIX: Set to false for Student layout. Logout is in the profile page. ---
      showLogoutButton: false,
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
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
      key: const ValueKey('StudentLayoutShell'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: const [
            StudentDashboard(),
            SubjectsScreen(),
            ScheduleScreen(),
            ProgressScreen(),
          ],
        ),
      ),
    );
  }
}