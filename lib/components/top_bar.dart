import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopNavigationBar extends StatefulWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterTap;

  const TopNavigationBar({super.key, this.onLoginTap, this.onRegisterTap});

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _handleLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          context.goNamed('home');
        }
      } catch (e) {
        debugPrint('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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

    if (_currentUser != null) {
      // User is logged in - show logout button
      return _buildGlassButton(
        isVerySmall ? 'Logout' : 'Logout',
        false,
        onTap: _handleLogout,
        isSmall: isSmall,
        isVerySmall: isVerySmall,
        isLogout: true,
      );
    } else {
      // User is not logged in - show login/register buttons
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGlassButton(
            isVerySmall ? 'Login' : 'Login',
            false,
            onTap: widget.onLoginTap,
            isSmall: isSmall,
            isVerySmall: isVerySmall,
          ),
          SizedBox(width: isVerySmall ? 4 : (isSmall ? 6 : 8)),
          _buildGlassButton(
            isVerySmall ? 'Register' : 'Register',
            true,
            onTap: widget.onRegisterTap,
            isSmall: isSmall,
            isVerySmall: isVerySmall,
          ),
        ],
      );
    }
  }

  Widget _buildGlassButton(
    String text,
    bool isPrimary, {
    VoidCallback? onTap,
    bool isSmall = false,
    bool isVerySmall = false,
    bool isLogout = false,
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
            gradient: isLogout
                ? LinearGradient(
                    colors: [Colors.red.withValues(alpha: 0.8), Colors.red.shade700],
                  )
                : isPrimary
                    ? LinearGradient(
                        colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
            borderRadius: BorderRadius.circular(
              isVerySmall ? 12 : (isSmall ? 16 : 20),
            ),
            border: Border.all(
              color: isLogout
                  ? Colors.red.withValues(alpha: 0.5)
                  : isPrimary
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: isLogout
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : isPrimary
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
