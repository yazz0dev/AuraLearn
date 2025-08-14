import 'package:auralearn/components/toast.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class AuthenticatedAppLayout extends StatelessWidget {
  final Widget child;
  final UserRole role;
  final String appBarTitle;
  final List<Widget>? appBarActions;
  final int bottomNavIndex;
  final void Function(int) onBottomNavTap;
  final bool showBottomBar; // --- FIX: Ensures this parameter is defined ---

  const AuthenticatedAppLayout({
    super.key,
    required this.child,
    required this.role,
    required this.appBarTitle,
    this.appBarActions,
    required this.bottomNavIndex,
    required this.onBottomNavTap,
    this.showBottomBar = true, // FIX: Defines the parameter in the constructor
  });

  Future<void> _handleLogout(BuildContext context) async {
    debugPrint('Logout button pressed');
    
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
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
        Toast.show(context, 'Failed to log out. Please try again.', type: ToastType.error);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    bool isStudent = role == UserRole.student;
    bool isKp = role == UserRole.kp;

    final ThemeData theme = ThemeData.dark().copyWith(
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
            side: BorderSide(color: Colors.white24, width: 0.5)),
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
          title: Text(appBarTitle),
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
        body: SafeArea(
          child: child,
        ),
        bottomNavigationBar: showBottomBar
            ? SharedBottomBar(
                role: role,
                currentIndex: bottomNavIndex,
                onTap: onBottomNavTap,
                backgroundColor: const Color(0xFF1E1E1E),
                selectedColor: isStudent ? theme.primaryColor : Colors.white,
                unselectedColor: Colors.grey[600]!,
              )
            : null,
      ),
    );
  }
}