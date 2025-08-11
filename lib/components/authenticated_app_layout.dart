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

    final ThemeData theme = isStudent
        ? ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF4A80F0),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          )
        : ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              elevation: 1,
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
          backgroundColor: isStudent ? Colors.white : const Color(0xFF1E1E1E),
          selectedColor: isStudent ? Colors.black : Colors.white,
          unselectedColor: isStudent ? Colors.grey[500]! : Colors.grey[600]!,
        ),
      ),
    );
  }
}