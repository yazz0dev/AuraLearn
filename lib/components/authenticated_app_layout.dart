import 'package:auralearn/components/toast.dart';
import 'package:auralearn/utils/responsive.dart';
import 'package:auralearn/utils/page_transitions.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class AuthenticatedAppLayout extends StatefulWidget {
  final Widget child;
  final UserRole role;
  final String appBarTitle;
  final List<Widget>? appBarActions;
  final int? bottomNavIndex;
  final void Function(int)? onBottomNavTap;
  final bool showBottomBar;
  final bool showCloseButton;

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
  });

  @override
  State<AuthenticatedAppLayout> createState() => _AuthenticatedAppLayoutState();
}

class _AuthenticatedAppLayoutState extends State<AuthenticatedAppLayout>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pageController = PageTransitions.createStandardController(vsync: this);
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));

    _pageController.forward();
  }

  @override
  void didUpdateWidget(AuthenticatedAppLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle child changes with smooth transitions
    if (oldWidget.child.key != widget.child.key) {
      _pageController.reset();
      _pageController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // Get navigation items based on role
  List<NavigationItem> _getNavigationItems() {
    switch (widget.role) {
      case UserRole.student:
        return [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Dashboard',
            index: 0,
          ),
          NavigationItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books,
            label: 'Subjects',
            index: 1,
          ),
          NavigationItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Schedule',
            index: 2,
          ),
          NavigationItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart,
            label: 'Progress',
            index: 3,
          ),
        ];
      case UserRole.admin:
        return [
          NavigationItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Dashboard',
            index: 0,
          ),
          NavigationItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Users',
            index: 1,
          ),
          NavigationItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'Subjects',
            index: 2,
          ),
        ];
      case UserRole.kp:
        return [];
    }
  }

  // Build desktop navigation menu
  Widget _buildDesktopNavigation(BuildContext context) {
    final navigationItems = _getNavigationItems();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
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
                icon: Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive ? Colors.white : Colors.white70,
                ),
                label: Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: isActive
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _shouldShowLogoutButton(BuildContext context) {
    // Only show logout button for dashboard views
    final isDashboardView = widget.appBarTitle == 'Dashboard' ||
                           widget.appBarTitle == 'AuraLearn Admin' ||
                           widget.appBarTitle == 'My Subjects';

    return isDashboardView && (widget.role == UserRole.admin || widget.role == UserRole.kp);
  }

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
              // If can't pop, navigate to a safe route like dashboard
              context.go('/${widget.role.name}/dashboard');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    debugPrint('Logout button pressed');

    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Confirm Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Content
                  const Text(
                    'Are you sure you want to log out of your account? You\'ll need to sign in again to access your dashboard.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldLogout != true) {
      debugPrint('Logout cancelled by user');
      return;
    }

    debugPrint('Attempting to sign out...');
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('Firebase sign out successful');
      if (context.mounted) {
        Toast.show(context, 'Logged out successfully', type: ToastType.success);
        debugPrint('Navigating to landing screen...');

        // Wait a brief moment for the auth state to update, then navigate
        await Future.delayed(const Duration(milliseconds: 100));

        if (context.mounted) {
          // Use go instead of goNamed to ensure we hit the root route
          context.go('/');
          debugPrint('Navigation to "/" completed');
        }
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        Toast.show(
          context,
          'Failed to log out. Please try again.',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isStudent = widget.role == UserRole.student;
    bool isKp = widget.role == UserRole.kp;
    bool isDesktop = ResponsiveUtils.isDesktop(context);

    final ThemeData theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: isKp
          ? Colors.teal
          : (isStudent ? const Color(0xFF4A80F0) : Colors.deepPurple),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
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
        titleMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: Colors.white24,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        style: ListTileStyle.drawer,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.appBarTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
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
            if (_shouldShowLogoutButton(context)) ...[
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
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.1),
                            Colors.red.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          if (!ResponsiveUtils.isMobile(context)) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
        body: SafeArea(
          child: PageTransitions.buildSubtlePageTransition(
            controller: _pageController,
            child: widget.child,
          ),
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

// Helper class for navigation items
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}
