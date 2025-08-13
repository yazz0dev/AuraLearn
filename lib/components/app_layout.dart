import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import 'top_bar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // --- FIX: Navigation handlers now use go_router ---
    void handleLogin() {
      context.goNamed('login');
    }

    void handleRegister() {
      context.goNamed('register');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned(top: 100, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF3B82F6).withAlpha(50), Colors.transparent])))),
          Positioned(bottom: 200, left: -50, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withAlpha(40), Colors.transparent])))),
          SafeArea(child: child),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: TopNavigationBar(
                onLoginTap: handleLogin,
                onRegisterTap: handleRegister,
              ),
            ),
          ),
        ],
      ),
    );
  }
}