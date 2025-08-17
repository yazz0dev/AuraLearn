import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
                children: [
                  const Spacer(flex: 1),
                  _buildHeader(),
                  const Spacer(flex: 1),
                  _buildFeatureCards(),
                  const Spacer(flex: 1),
                  _buildActions(),
                  const SizedBox(height: 32),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(51)),
              ),
              child: const Icon(Icons.psychology_rounded, color: Color(0xFF3B82F6), size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'AuraLearn',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI-Powered Learning\nTailored Just for You',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withAlpha(204),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            Expanded(child: _buildFeatureCard(Icons.quiz_rounded, 'Smart\nQuizzes', const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCard(Icons.analytics_rounded, 'Progress\nTracking', const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _buildFeatureCard(Icons.schedule, 'Flexible\nSchedule', const Color(0xFF10B981))),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
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
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  context.goNamed('register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Start Learning Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.goNamed('login');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withAlpha(179),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Already have an account? Sign in',
                style: TextStyle(fontWeight: FontWeight.w500),
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