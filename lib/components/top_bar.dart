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
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 350;
    
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 12 : 20, 
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.95),
            const Color(0xFF1E293B).withValues(alpha: 0.9),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  context.goNamed('home');
                },
                child: _buildLogo(isVerySmall),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 1,
            child: _buildActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isVerySmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 8 : 12, 
        vertical: isVerySmall ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmall ? 4 : 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.school, 
              color: const Color(0xFF3B82F6), 
              size: isVerySmall ? 16 : 20,
            ),
          ),
          SizedBox(width: isVerySmall ? 8 : 12),
          Flexible(
            child: Text(
              'AuraLearn',
              style: TextStyle(
                fontSize: isVerySmall ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 390;
    final bool isVerySmall = screenWidth < 350;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _buildGlassButton(
            'Login', 
            false, 
            onTap: onLoginTap, 
            isSmall: isSmallScreen,
            isVerySmall: isVerySmall,
          ),
        ),
        SizedBox(width: isVerySmall ? 4 : (isSmallScreen ? 8 : 12)),
        Flexible(
          child: _buildGlassButton(
            'Register', 
            true, 
            onTap: onRegisterTap, 
            isSmall: isSmallScreen,
            isVerySmall: isVerySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton(
    String text,
    bool isPrimary, {
    VoidCallback? onTap,
    bool isSmall = false,
    bool isVerySmall = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 10 : (isSmall ? 16 : 20),
            vertical: isVerySmall ? 8 : (isSmall ? 10 : 12),
          ),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6),
                      const Color(0xFF2563EB),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary 
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2), 
              width: 1
            ),
            boxShadow: isPrimary ? [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isVerySmall ? 12 : (isSmall ? 14 : 15),
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}