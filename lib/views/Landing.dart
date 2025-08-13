import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Note: Add url_launcher to your pubspec.yaml
import '../components/app_layout.dart';
import 'student/register.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late ScrollController _scrollController1;
  late ScrollController _scrollController2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _scrollController1 = ScrollController();
    _scrollController2 = ScrollController();

    _controller.forward();

    // Start the marquee animations after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMarquee(_scrollController1, 30);
      _startMarquee(_scrollController2, 35, reverse: true);
    });
  }

  void _startMarquee(ScrollController controller, int seconds, {bool reverse = false}) {
    if (!controller.hasClients || !mounted) return;

    final double maxExtent = controller.position.maxScrollExtent;
    final double minExtent = controller.position.minScrollExtent;

    // Calculate a dynamic duration based on content width to ensure consistent speed
    final duration = Duration(seconds: (maxExtent / 100).ceil());

    // Animate to the end or beginning
    controller
        .animateTo(
      reverse ? minExtent : maxExtent,
      duration: duration,
      curve: Curves.linear,
    )
        .then((_) {
      // When animation completes, jump back and restart if the widget is still mounted
      if (mounted && controller.hasClients) {
        controller.jumpTo(reverse ? maxExtent : minExtent);
        _startMarquee(controller, seconds, reverse: reverse);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController1.dispose();
    _scrollController2.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildAnimatedSection({
    required Widget child,
    required double intervalStart,
    double intervalEnd = 1.0,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      // --- FIX: Smoother and slightly faster animation curve ---
      curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
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
                const SizedBox(height: 80), // Space for persistent TopBar + status bar
                _buildHeroSection(context),
                _buildSiteInfoSection(context),
                _buildCoursesSection(context),
                _buildAboutUsSection(context),
                _buildSocialSection(context),
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
    final isSmallMobile = screenWidth < 400;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 16 : (isMobile ? 20 : 40),
        vertical: isSmallMobile ? 60 : (isMobile ? 80 : 120),
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
                    fontSize: isSmallMobile ? 28 : (isMobile ? 34 : 60),
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: isSmallMobile ? -0.5 : -1.5,
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
                    fontSize: isSmallMobile ? 16 : (isMobile ? 18 : 20),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = MediaQuery.of(context).size.width < 400;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 24 : 32, 
              vertical: isSmall ? 12 : 16
            ),
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF3B82F6) : Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(isSmall ? 24 : 30),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withAlpha(102),
                        blurRadius: isSmall ? 15 : 20,
                        offset: Offset(0, isSmall ? 4 : 5),
                      )
                    ]
                  : [],
              border: isPrimary ? null : Border.all(color: Colors.white.withAlpha(51)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSiteInfoSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 400;

    return _buildAnimatedSection(
      intervalStart: 0.4,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 16 : (isMobile ? 20 : 40), 
          vertical: isSmallMobile ? 60 : 80
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                Text('Why Choose AuraLearn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 24 : (isMobile ? 28 : 44), 
                    fontWeight: FontWeight.w800, 
                    color: Colors.white
                  ),
                ),
                const SizedBox(height: 16),
                Text('Discover features designed to enhance your learning experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18), 
                    color: Colors.white.withAlpha(179)
                  ),
                ),
                const SizedBox(height: 60),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 1 : 3,
                  crossAxisSpacing: isSmallMobile ? 16 : 24,
                  mainAxisSpacing: isSmallMobile ? 16 : 24,
                  childAspectRatio: isSmallMobile ? 2.0 : (isMobile ? 1.8 : 1.5),
                  children: [
                    _FeatureCard(icon: Icons.psychology_rounded, title: 'AI-Powered Learning', description: 'Personalized content generation based on your learning style.', color: const Color(0xFF3B82F6)),
                    _FeatureCard(icon: Icons.quiz_rounded, title: 'Interactive Quizzes', description: 'Dynamic quizzes that adapt to your knowledge level to reinforce learning.', color: const Color(0xFF8B5CF6)),
                    _FeatureCard(icon: Icons.analytics_rounded, title: 'Progress Tracking', description: 'Detailed analytics and insights to monitor your learning journey.', color: const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 400;

    return _buildAnimatedSection(
      intervalStart: 0.5,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 60 : 80),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 16 : (isMobile ? 20 : 40)),
              child: Column(
                children: [
                  Text(
                    'Popular Tech Courses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 24 : (isMobile ? 28 : 44),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Explore our curated selection of technology courses designed for modern learners.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallMobile ? 40 : 60),
            // --- FIX: Replaced with a seamless infinite marquee ---
            _buildMarqueeRow(_scrollController1, _techCourses.take(3).toList(), isSmallMobile),
            SizedBox(height: isSmallMobile ? 16 : 20),
            _buildMarqueeRow(_scrollController2, _techCourses.skip(3).toList(), isSmallMobile, reverse: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMarqueeRow(ScrollController controller, List<Map<String, dynamic>> courses, bool isSmallMobile, {bool reverse = false}) {
    // Duplicate the list to ensure there's enough content to scroll smoothly
    final duplicatedCourses = [...courses, ...courses, ...courses];

    return SizedBox(
      height: isSmallMobile ? 100 : 120,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: duplicatedCourses.length,
        itemBuilder: (context, index) {
          final course = duplicatedCourses[index];
          return _buildModernCourseCard(course, isSmallMobile);
        },
      ),
    );
  }

  Widget _buildModernCourseCard(Map<String, dynamic> course, [bool isSmallMobile = false]) {
    return Container(
      width: isSmallMobile ? 240 : 280,
      height: isSmallMobile ? 80 : 100,
      margin: EdgeInsets.only(right: isSmallMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: course['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: (course['gradient'] as List<Color>)[0].withAlpha(51),
            blurRadius: isSmallMobile ? 15 : 20,
            offset: Offset(0, isSmallMobile ? 6 : 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              width: isSmallMobile ? 40 : 50,
              height: isSmallMobile ? 40 : 50,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
              ),
              child: Icon(
                course['icon'] as IconData,
                size: isSmallMobile ? 22 : 28,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isSmallMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course['title'] as String,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallMobile ? 2 : 4),
                  Text(
                    '${course['duration']} • ${course['level']}',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 11 : 14,
                      color: Colors.white.withAlpha(204),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutUsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 400;

    return _buildAnimatedSection(
      intervalStart: 0.6,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 16 : (isMobile ? 20 : 40), 
          vertical: isSmallMobile ? 60 : 80
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Text(
                  'About AuraLearn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 24 : (isMobile ? 28 : 44),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AuraLearn is revolutionizing education through the power of artificial intelligence. Our platform creates personalized learning experiences that adapt to each student\'s unique needs, learning style, and pace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                    color: Colors.white.withAlpha(204),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: isSmallMobile ? 24 : 32),
                Text(
                  'Founded by passionate educators and technologists, we believe that learning should be engaging, accessible, and tailored to individual strengths. Our AI-driven approach ensures that every student can reach their full potential.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                    color: Colors.white.withAlpha(204),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('10K+', 'Students'),
                    _buildStatCard('500+', 'Courses'),
                    _buildStatCard('95%', 'Success Rate'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;
        return Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: isSmall ? 24 : 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: isSmall ? 4 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 14 : 16,
                color: Colors.white.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 400;

    return _buildAnimatedSection(
      intervalStart: 0.7,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 16 : (isMobile ? 20 : 40), 
          vertical: isSmallMobile ? 60 : 80
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Text(
                  'Join Our Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 24 : (isMobile ? 28 : 44),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect with fellow learners, share your progress, and stay updated with the latest in AI-powered education.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 18),
                    color: Colors.white.withAlpha(179),
                  ),
                ),
                const SizedBox(height: 48),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: isSmallMobile ? 12 : 16,
                  runSpacing: isSmallMobile ? 12 : 16,
                  children: [
                    // --- FIX: Replaced social links ---
                    _SocialButton(icon: Icons.code, color: const Color(0xFF90A4AE), isSmall: isSmallMobile, onTap: () => _launchURL('https://github.com')),
                    _SocialButton(icon: Icons.camera_alt_outlined, color: const Color(0xFFE4405F), isSmall: isSmallMobile, onTap: () => _launchURL('https://instagram.com')),
                    _SocialButton(icon: Icons.email_outlined, color: const Color(0xFF3B82F6), isSmall: isSmallMobile, onTap: () => _launchURL('mailto:contact@auralearn.com')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return _buildAnimatedSection(
      intervalStart: 0.8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Text(
          // --- FIX: Dynamic year ---
          '© ${DateTime.now().year} AuraLearn. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withAlpha(102)),
        ),
      ),
    );
  }

  // Tech courses data
  static final List<Map<String, dynamic>> _techCourses = [
    {
      'title': 'Web Development',
      'description': 'Master modern web technologies including HTML, CSS, JavaScript, and popular frameworks like React and Vue.',
      'duration': '12 weeks',
      'level': 'Beginner',
      'icon': Icons.web,
      'gradient': [Color(0xFF3B82F6), Color(0xFF1E40AF)],
    },
    {
      'title': 'Mobile App Development',
      'description': 'Build native and cross-platform mobile applications using Flutter, React Native, and native iOS/Android.',
      'duration': '16 weeks',
      'level': 'Intermediate',
      'icon': Icons.phone_android,
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'title': 'Data Science & AI',
      'description': 'Dive into machine learning, data analysis, and artificial intelligence using Python and popular libraries.',
      'duration': '20 weeks',
      'level': 'Advanced',
      'icon': Icons.analytics,
      'gradient': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    },
    {
      'title': 'Cloud Computing',
      'description': 'Learn cloud platforms like AWS, Azure, and Google Cloud. Master DevOps and infrastructure management.',
      'duration': '14 weeks',
      'level': 'Intermediate',
      'icon': Icons.cloud,
      'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
    },
    {
      'title': 'Cybersecurity',
      'description': 'Understand security principles, ethical hacking, and how to protect systems from cyber threats.',
      'duration': '18 weeks',
      'level': 'Advanced',
      'icon': Icons.security,
      'gradient': [Color(0xFFEF4444), Color(0xFFDC2626)],
    },
    {
      'title': 'Blockchain Development',
      'description': 'Explore blockchain technology, smart contracts, and decentralized application development.',
      'duration': '15 weeks',
      'level': 'Advanced',
      'icon': Icons.link,
      'gradient': [Color(0xFF06B6D4), Color(0xFF0891B2)],
    },
  ];
}

// --- NEW: Private StatefulWidget for hover effect on feature cards ---
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({required this.icon, required this.title, required this.description, required this.color});

  @override
  __FeatureCardState createState() => __FeatureCardState();
}

class __FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSmallCard = MediaQuery.of(context).size.width < 400;
    return MouseRegion(
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.all(isSmallCard ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(isSmallCard ? 16 : 24),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSmallCard ? 40 : 48,
                height: isSmallCard ? 40 : 48,
                decoration: BoxDecoration(
                  color: widget.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(isSmallCard ? 12 : 16),
                ),
                child: Icon(widget.icon, size: isSmallCard ? 20 : 24, color: widget.color),
              ),
              SizedBox(height: isSmallCard ? 12 : 16),
              Text(
                widget.title,
                style: TextStyle(fontSize: isSmallCard ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallCard ? 6 : 8),
              Expanded(
                child: Text(
                  widget.description,
                  style: TextStyle(fontSize: isSmallCard ? 12 : 13, color: Colors.white.withAlpha(179), height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW: Private StatefulWidget for hover effect on social buttons ---
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool isSmall;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.color, required this.isSmall, required this.onTap});

  @override
  __SocialButtonState createState() => __SocialButtonState();
}

class __SocialButtonState extends State<_SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: widget.isSmall ? 50 : 60,
            height: widget.isSmall ? 50 : 60,
            decoration: BoxDecoration(
              color: widget.color.withAlpha(26),
              borderRadius: BorderRadius.circular(widget.isSmall ? 12 : 16),
              border: Border.all(color: widget.color.withAlpha(51)),
            ),
            child: Icon(
              widget.icon,
              size: widget.isSmall ? 24 : 28,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}