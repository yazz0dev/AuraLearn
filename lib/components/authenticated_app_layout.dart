// lib/components/authenticated_app_layout.dart

import 'package:auralearn/utils/responsive.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../enums/user_role.dart'; // FIX: Import from the new central location
import 'bottom_bar.dart';
import 'top_bar.dart';

class AuthenticatedAppLayout extends StatefulWidget {
  final Widget child;
  final UserRole role;
  final String appBarTitle;
  final List<Widget>? appBarActions;
  final int? bottomNavIndex;
  final void Function(int)? onBottomNavTap;
  final bool showBottomBar;
  final bool showCloseButton;
  // --- FIX: Added an explicit property to control the logout button's visibility ---
  final bool showLogoutButton;

  const AuthenticatedAppLayout({
    super.key,
    required this.child,
    required this.role,
    required this.appBarTitle,
    this.appBarActions,
    this.bottomNavIndex,
    this.onBottomNavTap,
    this.showBottomBar = true,
    this.showCloseButton = false,
    this.showLogoutButton = false, // Default to false for safety
  });

  @override
  State<AuthenticatedAppLayout> createState() => _AuthenticatedAppLayoutState();
}

class _AuthenticatedAppLayoutState extends State<AuthenticatedAppLayout>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late ThemeData _cachedTheme;

  @override
  void initState() {
    super.initState();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _cachedTheme = _buildTheme();
    _pageController.forward();
  }

  @override
  void didUpdateWidget(AuthenticatedAppLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child.key != widget.child.key) {
      _pageController.reset();
      _pageController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<NavigationItem> _getNavigationItems() {
    switch (widget.role) {
      case UserRole.student:
        return [
          NavigationItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Dashboard', index: 0),
          NavigationItem(icon: Icons.library_books_outlined, activeIcon: Icons.library_books, label: 'Subjects', index: 1),
          NavigationItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Schedule', index: 2),
          NavigationItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Progress', index: 3),
        ];
      case UserRole.admin:
        return [
          NavigationItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Dashboard', index: 0),
          NavigationItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users', index: 1),
          NavigationItem(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Subjects', index: 2),
        ];
      case UserRole.kp:
        return [];
    }
  }

  Widget _buildDesktopNavigation(BuildContext context) {
    final navigationItems = _getNavigationItems();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(26), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: navigationItems.map((item) {
            final isActive = widget.bottomNavIndex != null && widget.bottomNavIndex == item.index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: TextButton.icon(
                onPressed: () => widget.onBottomNavTap?.call(item.index),
                icon: Icon(isActive ? item.activeIcon : item.icon, size: 18, color: isActive ? Colors.white : Colors.white70),
                label: Text(
                  item.label,
                  style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: isActive ? Colors.white.withAlpha(26) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- FIX: This fragile logic has been removed. ---
  // bool _shouldShowLogoutButton(BuildContext context) { ... }

  Widget _buildCloseButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/${widget.role.name}/dashboard');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1),
            ),
            child: const Icon(Icons.close, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    bool isStudent = widget.role == UserRole.student;
    bool isKp = widget.role == UserRole.kp;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: isKp ? Colors.teal : (isStudent ? const Color(0xFF4A80F0) : Colors.deepPurple),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: Colors.white24, width: 0.5),
        ),
      ),
      dividerColor: Colors.white24,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(linearTrackColor: Colors.white24),
      listTileTheme: const ListTileThemeData(textColor: Colors.white, style: ListTileStyle.drawer),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // ... (This method remains the same)
  }

  @override
  Widget build(BuildContext context) {
    bool isStudent = widget.role == UserRole.student;
    bool isDesktop = ResponsiveUtils.isDesktop(context);

    final ThemeData theme = _cachedTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.appBarTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          actions: [
            if (widget.showCloseButton) _buildCloseButton(),
            if (widget.appBarActions != null) ...widget.appBarActions!,
            if (isDesktop) ...[
              const SizedBox(width: 8),
              _buildDesktopNavigation(context),
              const SizedBox(width: 8),
            ],
            // --- FIX: Use the new robust property instead of the old method ---
            if (widget.showLogoutButton) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      debugPrint('Logout button tapped');
                      _handleLogout(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.red.withAlpha(26), Colors.red.withAlpha(13)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withAlpha(51), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.red.withAlpha(26), blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.red.shade400),
                          if (!ResponsiveUtils.isMobile(context)) ...[
                            const SizedBox(width: 6),
                            Text('Logout', style: TextStyle(color: Colors.red.shade400, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Add TopNavigationBar at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: TopNavigationBar(
                  onLoginTap: () => context.goNamed('login'),
                  onRegisterTap: () => context.goNamed('register'),
                ),
              ),
            ),
            // Main content with padding to account for the TopNavigationBar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 70), // Height of TopNavigationBar
                child: PageTransitions.buildSubtlePageTransition(
                  controller: _pageController,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.showBottomBar && !isDesktop && widget.bottomNavIndex != null && widget.onBottomNavTap != null
            ? SharedBottomBar(
                role: widget.role,
                currentIndex: widget.bottomNavIndex!,
                onTap: widget.onBottomNavTap!,
                backgroundColor: const Color(0xFF1E1E1E),
                selectedColor: isStudent ? theme.primaryColor : Colors.white,
                unselectedColor: Colors.grey[600]!,
              )
            : null,
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavigationItem({required this.icon, required this.activeIcon, required this.label, required this.index});
}