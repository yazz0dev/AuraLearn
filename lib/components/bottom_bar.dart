import 'package:flutter/material.dart';

// Enum to define user roles for the bottom bar
enum UserRole { admin, student }

class SharedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserRole role;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const SharedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    required this.backgroundColor,
    required this.selectedColor,
    required this.unselectedColor,
  });

  // Items for the Student role
  static const List<BottomNavigationBarItem> _studentItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.library_books_outlined),
      activeIcon: Icon(Icons.library_books),
      label: 'Subjects',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      activeIcon: Icon(Icons.calendar_today),
      label: 'Schedule',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Progress',
    ),
  ];

  // Items for the Admin role
  static const List<BottomNavigationBarItem> _adminItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_outlined),
      activeIcon: Icon(Icons.menu_book),
      label: 'Content',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Users',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: backgroundColor,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      elevation: 8,
      items: role == UserRole.student ? _studentItems : _adminItems,
    );
  }
}