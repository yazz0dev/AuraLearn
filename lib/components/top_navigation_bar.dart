import 'package:flutter/material.dart';
import 'dart:ui';

class TopNavigationBar extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback? onMenuTap;
  final VoidCallback? onGetStartedTap;
  final VoidCallback? onHomeTap;
  final VoidCallback? onCoursesTap;
  final VoidCallback? onAboutTap;
  final VoidCallback? onContactTap;

  const TopNavigationBar({
    super.key,
    this.isLoggedIn = false,
    this.onMenuTap,
    this.onGetStartedTap,
    this.onHomeTap,
    this.onCoursesTap,
    this.onAboutTap,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(64), // Replaced withOpacity(0.25)
                Colors.white.withAlpha(26), // Replaced withOpacity(0.1)
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha(51), // Replaced withOpacity(0.2)
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26), // Replaced withOpacity(0.1)
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Logo with Glass Effect
                _buildLogo(),
                Spacer(),
                // Navigation Menu
                if (!isMobile) ...[
                  _buildDesktopNavigation(),
                ] else ...[
                  _buildMobileNavigation(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(77), // Replaced withOpacity(0.3)
                    Colors.white.withAlpha(26), // Replaced withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withAlpha(51), // Replaced withOpacity(0.2)
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'AuraLearn',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigation() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildNavItem('Home', true, onHomeTap),
          _buildNavItem('Courses', false, onCoursesTap),
          _buildNavItem('About', false, onAboutTap),
          _buildNavItem('Contact', false, onContactTap),
          const SizedBox(width: 24),
          if (isLoggedIn) ...[
            _buildGlassButton('Dashboard', false, onTap: () {}),
            const SizedBox(width: 12),
            _buildUserAvatar(),
          ] else ...[
            _buildGlassButton('Login', false, onTap: () {}),
            const SizedBox(width: 12),
            _buildGlassButton('Get Started', true, onTap: onGetStartedTap),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileNavigation() {
    return Row(
      children: [
        if (isLoggedIn) ...[
          _buildUserAvatar(),
          const SizedBox(width: 12),
        ],
        // Show login and hamburger menu when logged out
        if (!isLoggedIn) ...[
          _buildGlassButton('Login', false, onTap: () {}),
          const SizedBox(width: 8),
          _buildGlassButton('Menu', false, icon: Icons.menu, onTap: onMenuTap),
        ],
      ],
    );
  }

  Widget _buildNavItem(String title, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white.withAlpha(204), // Replaced withOpacity(0.8)
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(
    String text,
    bool isPrimary, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: icon != null ? 12 : 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPrimary
                    ? [
                        Colors.white.withAlpha(77), // Replaced withOpacity(0.3)
                        Colors.white.withAlpha(26), // Replaced withOpacity(0.1)
                      ]
                    : [
                        Colors.white.withAlpha(51), // Replaced withOpacity(0.2)
                        Colors.white.withAlpha(13), // Replaced withOpacity(0.05)
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(51), // Replaced withOpacity(0.2)
                width: 1,
              ),
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 20)
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(77), // Replaced withOpacity(0.3)
                Colors.white.withAlpha(26), // Replaced withOpacity(0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha(51), // Replaced withOpacity(0.2)
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}