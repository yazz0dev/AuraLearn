import 'package:flutter/material.dart';
import 'package:auralearn/utils/responsive.dart';

// --- FIX: Added 'kp' to the enum to support the new role ---
enum UserRole { admin, student, kp }

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

  // Helper method to determine if bottom bar should be shown
  static bool shouldShowBottomBar(BuildContext context) {
    return !ResponsiveUtils.isDesktop(context);
  }

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
      icon: Icon(Icons.people_outline),
      activeIcon: Icon(Icons.people),
      label: 'Users',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined),
      activeIcon: Icon(Icons.school),
      label: 'Subjects',
    ),
  ];
  
  // --- FIX: Removed the 'Profile' item as it is not needed for the KP role. ---
  // Items for the KP role
  static const List<BottomNavigationBarItem> _kpItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined),
      activeIcon: Icon(Icons.school),
      label: 'My Subjects',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine which items to show based on the role
    List<BottomNavigationBarItem> getItemsForRole() {
      switch (role) {
        case UserRole.student:
          return _studentItems;
        case UserRole.admin:
          return _adminItems;
        case UserRole.kp:
          return _kpItems;
      }
    }

    final items = getItemsForRole();
    final safeCurrentIndex = currentIndex >= items.length ? 0 : currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: safeCurrentIndex,
          onTap: (index) {
            debugPrint('Bottom nav tapped: index=$index, role=$role');
            onTap(index);
          },
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 12,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: items.map((item) {
            final isSelected = items.indexOf(item) == safeCurrentIndex;
            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                    ? selectedColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.1 : 1.0,
                  child: item.icon,
                ),
              ),
              activeIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: 1.1,
                  child: item.activeIcon,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}