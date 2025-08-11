import 'package:flutter/material.dart';
import '../components/app_layout.dart';
import 'student/register.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection({
    required Widget child,
    required double intervalStart,
    double intervalEnd = 1.0,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      child: Stack(
        children: [
          _buildAnimatedGradientBackground(),
          _buildAuroraEffect(const Color(0xFF3B82F6), Alignment.topRight),
          _buildAuroraEffect(const Color(0xFF8B5CF6), Alignment.bottomLeft),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80), // Space for persistent TopBar
                _buildHeroSection(context),
                _buildSiteInfoSection(context),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGradientBackground() {
    return TweenAnimationBuilder<Alignment>(
      duration: const Duration(seconds: 20),
      tween: AlignmentTween(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
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
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 10),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value * 0.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color.withAlpha(64), color.withAlpha(0)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 80 : 120,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              _buildAnimatedSection(
                intervalStart: 0.1,
                intervalEnd: 0.8,
                child: Text(
                  'Transform Your Learning Journey with AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 38 : 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildAnimatedSection(
                intervalStart: 0.3,
                intervalEnd: 0.9,
                child: Text(
                  'Experience personalized education powered by artificial intelligence. Create, learn, and excel with adaptive content tailored just for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    color: Colors.white.withAlpha(204),
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _buildAnimatedSection(
                intervalStart: 0.5,
                intervalEnd: 1.0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                  child: _buildModernButton('Start Learning For Free', isPrimary: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton(String text, {required bool isPrimary}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF3B82F6) : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
          border: isPrimary ? null : Border.all(color: Colors.white.withAlpha(51)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSiteInfoSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return _buildAnimatedSection(
      intervalStart: 0.4,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 80),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Text('Why Choose AuraLearn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 32 : 44, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text('Discover features designed to enhance your learning experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.white.withAlpha(179)),
                ),
                const SizedBox(height: 60),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 1 : 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  // FIX: Adjusted aspect ratio to give cards more height and prevent overflow
                  childAspectRatio: isMobile ? 1.2 : 1.1,
                  children: [
                    _buildFeatureCard(Icons.psychology_rounded, 'AI-Powered Learning', 'Personalized content generation based on your learning style.', const Color(0xFF3B82F6)),
                    _buildFeatureCard(Icons.quiz_rounded, 'Interactive Quizzes', 'Dynamic quizzes that adapt to your knowledge level to reinforce learning.', const Color(0xFF8B5CF6)),
                    _buildFeatureCard(Icons.analytics_rounded, 'Progress Tracking', 'Detailed analytics and insights to monitor your learning journey.', const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: MouseRegion(
            onEnter: (event) {},
            onExit: (event) {},
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withAlpha(26)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: color.withAlpha(38),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  // FIX: Replaced Spacer with a fixed SizedBox to prevent render overflow
                  const SizedBox(height: 24),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(fontSize: 15, color: Colors.white.withAlpha(179), height: 1.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _buildAnimatedSection(
      intervalStart: 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Text(
          '© 2024 AuraLearn. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withAlpha(102)),
        ),
      ),
    );
  }
}