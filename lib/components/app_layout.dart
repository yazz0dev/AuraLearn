import 'package:flutter/material.dart';
import 'package:auralearn/views/login.dart'; // FIX: Adjust path to reflect file rename.
import 'package:auralearn/views/student/register.dart'; // Adjust path if necessary
import 'top_bar.dart';

class AppLayout extends StatelessWidget {
  final Widget child;

  const AppLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Navigation handlers can be defined here once
    void handleLogin() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }

    void handleRegister() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    }

    return Scaffold(
      // The background is now part of the persistent layout
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // You can even include persistent background elements here
          Positioned(top: 100, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF3B82F6).withAlpha(50), Colors.transparent])))),
          Positioned(bottom: 200, left: -50, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withAlpha(40), Colors.transparent])))),

          // The unique content of each page will be placed here
          // We wrap it in SafeArea to avoid system UI (like notches)
          SafeArea(child: child),

          // The TopNavigationBar is now truly persistent
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