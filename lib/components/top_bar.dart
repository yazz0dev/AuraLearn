import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopNavigationBar extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const TopNavigationBar({super.key, this.onLoginTap, this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 350;
    final isSmall = screenWidth < 400;

    return Container(
      height: isVerySmall ? 60 : 70,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 8 : (isSmall ? 12 : 20),
        vertical: isVerySmall ? 8 : 12,
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
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  context.goNamed('home');
                },
                child: _buildLogo(isVerySmall, isSmall),
              ),
            ),
          ),
          SizedBox(width: isVerySmall ? 2 : (isSmall ? 4 : 8)),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isVerySmall, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 6 : (isSmall ? 8 : 12),
        vertical: isVerySmall ? 4 : (isSmall ? 6 : 8),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmall ? 3 : (isSmall ? 4 : 6)),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isVerySmall ? 10 : 12),
            ),
            child: Icon(
              Icons.school,
              color: const Color(0xFF3B82F6),
              size: isVerySmall ? 16 : (isSmall ? 18 : 20),
            ),
          ),
          SizedBox(width: isVerySmall ? 4 : (isSmall ? 6 : 12)),
          Flexible(
            child: Text(
              isVerySmall ? 'AL' : 'AuraLearn',
              style: TextStyle(
                fontSize: isVerySmall ? 18 : (isSmall ? 20 : 22),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: isVerySmall ? 0.3 : 0.5,
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
    final bool isSmall = screenWidth < 400;
    final bool isVerySmall = screenWidth < 350;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGlassButton(
          isVerySmall ? 'Login' : 'Login',
          false,
          onTap: onLoginTap,
          isSmall: isSmall,
          isVerySmall: isVerySmall,
        ),
        SizedBox(width: isVerySmall ? 4 : (isSmall ? 6 : 8)),
        _buildGlassButton(
          isVerySmall ? 'Register' : 'Register',
          true,
          onTap: onRegisterTap,
          isSmall: isSmall,
          isVerySmall: isVerySmall,
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
        child: Container(
          constraints: BoxConstraints(
            minWidth: isVerySmall ? 40 : (isSmall ? 50 : 70),
            maxWidth: isVerySmall ? 60 : (isSmall ? 70 : 100),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 4 : (isSmall ? 8 : 16),
            vertical: isVerySmall ? 2 : (isSmall ? 4 : 8),
          ),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isSmall ? 16 : 20)),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isVerySmall ? 10 : (isSmall ? 12 : 14),
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
