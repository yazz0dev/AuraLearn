import 'package:flutter/material.dart';
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(230),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withAlpha(26),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
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
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF3B82F6).withAlpha(180)
              : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary 
                ? const Color(0xFF3B82F6).withAlpha(100)
                : Colors.white.withAlpha(51), 
            width: 1
          ),
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
    );
  }
}