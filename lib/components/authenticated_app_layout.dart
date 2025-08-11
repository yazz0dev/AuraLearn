import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class AuthenticatedAppLayout extends StatelessWidget {
  final Widget child;
  final UserRole role;
  final String appBarTitle;
  final List<Widget>? appBarActions;
  final int bottomNavIndex;
  final void Function(int) onBottomNavTap;

  const AuthenticatedAppLayout({
    super.key,
    required this.child,
    required this.role,
    required this.appBarTitle,
    this.appBarActions,
    required this.bottomNavIndex,
    required this.onBottomNavTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isStudent = role == UserRole.student;

    // --- FIX: Unified dark theme for all authenticated users ---
    final ThemeData theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: isStudent ? const Color(0xFF4A80F0) : Colors.deepPurple, // Differentiate primary colors
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      // --- FIX: argument_type_not_assignable ---
      // Changed CardTheme to const CardThemeData to match the expected type.
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Color(0xFF1E1E1E), // Darker card color
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Colors.white24, width: 0.5)),
      ),
      dividerColor: Colors.white24,
      textTheme: const TextTheme(
        // Ensure text is white on the dark background
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        titleSmall: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      // --- FIX: deprecated_member_use ---
      // Set linearTrackColor directly instead of using withOpacity.
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
          actions: appBarActions,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: child,
        ),
        bottomNavigationBar: SharedBottomBar(
          role: role,
          currentIndex: bottomNavIndex,
          onTap: onBottomNavTap,
          // --- FIX: Unified dark bottom bar styling ---
          backgroundColor: const Color(0xFF1E1E1E),
          selectedColor: isStudent ? theme.primaryColor : Colors.white,
          unselectedColor: Colors.grey[600]!,
        ),
      ),
    );
  }
}