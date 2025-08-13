import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';

class TopNavigationBar extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const TopNavigationBar({
    super.key,
    this.onLoginTap,
    this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(64),
                Colors.white.withAlpha(26),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withAlpha(51),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // --- FIX: Removed Flexible wrapper to prioritize showing the full logo ---
 // --- FIX: Updated logo tap to use go_router ---
  MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        context.goNamed('home');
      },
      child: _buildLogo(),
    ),
  ),
              const Spacer(),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min, // Ensure the Row doesn't expand unnecessarily
      children: [
        const Icon(Icons.school, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Text(
          'AuraLearn',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 390;

    return Row(
      children: [
        _buildGlassButton('Login', false, onTap: onLoginTap, isSmall: isSmallScreen),
        SizedBox(width: isSmallScreen ? 8 : 12),
        _buildGlassButton('Register', true, onTap: onRegisterTap, isSmall: isSmallScreen),
      ],
    );
  }

  Widget _buildGlassButton(
    String text,
    bool isPrimary, {
    VoidCallback? onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            // --- FIX: Reduced padding to make buttons smaller ---
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 12 : 16,
              vertical: isSmall ? 6 : 8,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPrimary
                    ? [Colors.white.withAlpha(77), Colors.white.withAlpha(26)]
                    : [Colors.white.withAlpha(51), Colors.white.withAlpha(13)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 14 : 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}