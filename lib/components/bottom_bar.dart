import 'package:flutter/material.dart';

class SharedBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const SharedBottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Content',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Users',
        ),
      ],
    );
  }
}
