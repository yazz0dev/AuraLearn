import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/enums/user_role.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/admin/subject_list.dart';
import 'package:auralearn/views/admin/user_management.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final String page;
  const AdminLayout({super.key, required this.page});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late int _currentIndex;

  final Map<String, int> _pageMap = {
    'dashboard': 0,
    'users': 1,
    'subjects': 2,
  };

  @override
  void initState() {
    super.initState();
    _updateIndex(widget.page);
  }

  @override
  void didUpdateWidget(AdminLayout oldWidget) {
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
    context.go('/admin/$pageName');
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Subject Management';
      default:
        return 'AuraLearn Admin';
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 2: // Subject List
        return [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/create-subject'),
            tooltip: 'Create Subject',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIX: Logic to conditionally show the logout button ---
    // The logout button should only appear on the main dashboard (index 0).
    final bool isDashboardPage = _currentIndex == 0;

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: _getAppBarTitle(),
      // --- FIX: Use the new boolean to control visibility ---
      showLogoutButton: isDashboardPage,
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      appBarActions: _getAppBarActions(),
      key: const ValueKey('AdminLayoutShell'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: const [
            DashboardAdmin(),
            UserManagementScreen(),
            SubjectListScreen(),
          ],
        ),
      ),
    );
  }
}