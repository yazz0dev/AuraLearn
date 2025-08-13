import 'package:auralearn/views/login.dart';
import 'package:auralearn/views/student/register.dart';
import 'package:flutter/material.dart';

class MobileLandingScreen extends StatefulWidget {
  const MobileLandingScreen({super.key});

  @override
  State<MobileLandingScreen> createState() => _MobileLandingScreenState();
}

class _MobileLandingScreenState extends State<MobileLandingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This screen defines its own Scaffold for a unique, simple mobile layout.
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedGradientBackground(),
          _buildAuroraEffect(const Color(0xFF3B82F6), Alignment.topRight),
          _buildAuroraEffect(const Color(0xFF8B5CF6), Alignment.bottomLeft),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  _buildHeader(),
                  const Spacer(flex: 3),
                  _buildActions(),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.school, color: Colors.white, size: 36),
                SizedBox(width: 12),
                Text(
                  'AuraLearn',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Transform Your Learning Journey with AI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withAlpha(204),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('Get Started'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I already have an account',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() {
    return TweenAnimationBuilder<Alignment>(
      duration: const Duration(seconds: 20),
      tween: AlignmentTween(begin: Alignment.topLeft, end: Alignment.bottomRight),
      builder: (context, alignment, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignment,
              end: -alignment,
              colors: const [Color(0xFF0F172A), Color(0xFF131c31), Color(0xFF1E293B)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuroraEffect(Color color, Alignment alignment) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withAlpha(64), color.withAlpha(0)]),
            ),
          ),
        ),
      ),
    );
  }
}