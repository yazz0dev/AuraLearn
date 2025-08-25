import 'dart:async';
import 'package:auralearn/components/authenticated_app_layout.dart';
import 'package:auralearn/components/toast.dart';
import 'package:auralearn/enums/user_role.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminLayout extends StatefulWidget {
  final String page;
  final Widget child;
  const AdminLayout({super.key, required this.page, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late int _currentIndex;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isLoggingOut = false;

  final Map<String, int> _pageMap = {
    'dashboard': 0,
    'users': 1,
    'subjects': 2,
  };

  @override
  void initState() {
    super.initState();
    _updateIndex(widget.page);
    _listenToUserChanges();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserChanges() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists && mounted) {
          _handleUserDeleted();
        }
      });
    }
  }

  void _handleUserDeleted() async {
    if (_isLoggingOut || !mounted) return;
    setState(() {
      _isLoggingOut = true;
    });

    Toast.show(
      context,
      'Your account is no longer active. You will be logged out.',
      type: ToastType.error,
    );

    await FirebaseAuth.instance.signOut();

    if (mounted) {
      context.go('/');
    }
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

    // Update index immediately for smooth UI feedback
    setState(() {
      _currentIndex = index;
    });

    final pageName =
        _pageMap.entries.firstWhere((entry) => entry.value == index).key;
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
    if (_isLoggingOut) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    // --- FIX: Logic to conditionally show the logout button ---
    // The logout button should only appear on the main dashboard (index 0).
    final bool isDashboardPage = _currentIndex == 0;
    final bool isMainPage = _pageMap.containsKey(widget.page);

    return AuthenticatedAppLayout(
      role: UserRole.admin,
      appBarTitle: _getAppBarTitle(),
      showCloseButton: !isMainPage,

      // --- FIX: Use the new boolean to control visibility ---
      showLogoutButton: isDashboardPage,
      bottomNavIndex: _currentIndex,
      onBottomNavTap: _onNavigate,
      appBarActions: _getAppBarActions(),
      key: const ValueKey('AdminLayoutShell'),
      child: widget.child,
    );
  }
}