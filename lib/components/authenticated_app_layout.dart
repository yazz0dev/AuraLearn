import 'package:auralearn/components/toast.dart';
import 'package:auralearn/utils/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class AuthenticatedAppLayout extends StatelessWidget {
  final Widget child;
  final UserRole role;
  final String appBarTitle;
  final List<Widget>? appBarActions;
  final int? bottomNavIndex;
  final void Function(int)? onBottomNavTap;
  final bool showBottomBar; // --- FIX: Ensures this parameter is defined ---

  const AuthenticatedAppLayout({
    super.key,
    required this.child,
    required this.role,
    required this.appBarTitle,
    this.appBarActions,
    this.bottomNavIndex,
    this.onBottomNavTap,
    this.showBottomBar = true, // FIX: Defines the parameter in the constructor
  });

  // Get navigation items based on role
  List<NavigationItem> _getNavigationItems() {
    switch (role) {
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
        return [
          NavigationItem(
            icon: Icons.school_outlined,
            activeIcon: Icons.school,
            label: 'My Subjects',
            index: 0,
          ),
        ];
    }
  }

  // Build desktop navigation menu
  Widget _buildDesktopNavigation(BuildContext context) {
    final navigationItems = _getNavigationItems();

    return Row(
      children: navigationItems.map((item) {
        final isActive = bottomNavIndex != null && bottomNavIndex == item.index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextButton.icon(
            onPressed: () => onBottomNavTap?.call(item.index),
            icon: Icon(
              isActive ? item.activeIcon : item.icon,
              size: 20,
              color: isActive ? Colors.white : Colors.white70,
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: isActive
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }).toList(),
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
    bool isStudent = role == UserRole.student;
    bool isKp = role == UserRole.kp;
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
          title: Row(
            children: [
              Text(appBarTitle),
              if (isDesktop) ...[
                const SizedBox(width: 32),
                Expanded(child: _buildDesktopNavigation(context)),
              ],
            ],
          ),
          actions: [
            if (appBarActions != null) ...appBarActions!,
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                debugPrint('Logout icon button tapped');
                _handleLogout(context);
              },
              tooltip: 'Logout',
            ),
            const SizedBox(width: 8),
          ],
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(child: child),
        bottomNavigationBar: showBottomBar && !isDesktop && bottomNavIndex != null && onBottomNavTap != null
            ? SharedBottomBar(
                role: role,
                currentIndex: bottomNavIndex!,
                onTap: onBottomNavTap!,
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
