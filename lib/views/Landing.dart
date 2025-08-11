import 'package:flutter/material.dart';
import 'dart:ui';
import '../components/top_navigation_bar.dart';
import 'login.dart';
import 'student/register.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _cardsController;
  late AnimationController _aboutController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _heroScaleAnimation;
  late Animation<double> _cardsAnimation;
  late Animation<double> _aboutAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with smoother durations
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _aboutController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize hero animations with smoother curves
    _heroFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
    ));

    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _heroScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    ));

    _cardsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOutQuart,
    ));

    _aboutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _aboutController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations with staggered timing
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _heroController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _cardsController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _aboutController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardsController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced background gradient with smoother colors
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF1E293B), // slate-800
                  Color(0xFF334155), // slate-700
                  Color(0xFF475569), // slate-600
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // Subtle animated background elements
          _buildBackgroundElements(),
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 80),
                _buildHeroSection(context),
                _buildSiteInfoSection(context),
                _buildAboutUsSection(context),
                _buildFooter(context),
              ],
            ),
          ),
          // Fixed Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopNavigationBar(
              isLoggedIn: false,
              onMenuTap: () => _showMobileMenu(context),
              onGetStartedTap: () => _handleGetStarted(context),
              onHomeTap: () {},
              onCoursesTap: () {},
              onAboutTap: () {},
              onContactTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Floating orbs with subtle animation
          Positioned(
            top: 100,
            right: 100,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 8),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50 * (value - 0.5), 30 * (value - 0.5)),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3B82F6).withAlpha(26),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Another floating orb
          Positioned(
            bottom: 200,
            left: 80,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 10),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(-40 * (value - 0.5), 20 * (value - 0.5)),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withAlpha(20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mobile menu with subtle blur
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(38),
                  Colors.white.withAlpha(20),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: Colors.white.withAlpha(26),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 30),
                _buildMobileMenuItem(
                    context, 'Home', Icons.home_rounded, () {}),
                _buildMobileMenuItem(
                    context, 'Courses', Icons.book_rounded, () {}),
                _buildMobileMenuItem(
                    context, 'About', Icons.info_rounded, () {}),
                _buildMobileMenuItem(
                    context, 'Contact', Icons.contact_mail_rounded, () {}),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Close the bottom sheet first
                        _handleGetStarted(context);
                      },
                      child: _buildMobileGetStartedButton(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildMobileGetStartedButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(51),
                Colors.white.withAlpha(26),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(38),
              width: 1,
            ),
          ),
          child: const Text(
            'Get Started',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _handleGetStarted(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  void _handleLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AnimatedBuilder(
      animation: _heroController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _heroFadeAnimation,
          child: SlideTransition(
            position: _heroSlideAnimation,
            child: ScaleTransition(
              scale: _heroScaleAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: isMobile ? 80 : 120,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 32 : 48),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withAlpha(31),
                                Colors.white.withAlpha(20),
                                Colors.white.withAlpha(10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withAlpha(38),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Transform Your Learning Journey with AI',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 32 : 56,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Experience personalized education powered by artificial intelligence. Create, learn, and excel with adaptive content tailored just for you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 22,
                                  color: Colors.white.withAlpha(230),
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () => _handleGetStarted(context),
                                    child: _buildModernButton(
                                        'Start Learning', true, isMobile),
                                  ),
                                  GestureDetector(
                                    onTap: () => _handleLogin(context),
                                    child:
                                        _buildModernButton('Login', false, isMobile),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernButton(String text, bool isPrimary, bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 16 : 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [
                      const Color(0xFF3B82F6).withAlpha(204),
                      const Color(0xFF1D4ED8).withAlpha(153),
                    ]
                  : [
                      Colors.white.withAlpha(38),
                      Colors.white.withAlpha(20),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF3B82F6).withAlpha(77)
                  : Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiteInfoSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1024;

    return AnimatedBuilder(
      animation: _cardsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardsAnimation.value)),
          child: Opacity(
            opacity: _cardsAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 60 : 80,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      // Section header
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 32,
                              vertical: isMobile ? 20 : 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withAlpha(26),
                                  Colors.white.withAlpha(13),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(26),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Why Choose AuraLearn?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 28 : 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Discover the power of AI-driven education with features designed to enhance your learning experience.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    color: Colors.white.withAlpha(204),
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Feature cards grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio:
                            isMobile ? 1.4 : (isTablet ? 1.1 : 1.0),
                        children: [
                          _buildFeatureCard(
                            Icons.psychology_rounded,
                            'AI-Powered Learning',
                            'Personalized content generation based on your learning style and progress.',
                            const Color(0xFF3B82F6),
                            0,
                          ),
                          _buildFeatureCard(
                            Icons.quiz_rounded,
                            'Interactive Quizzes',
                            'Dynamic quizzes that adapt to your knowledge level and help reinforce learning.',
                            const Color(0xFF8B5CF6),
                            1,
                          ),
                          _buildFeatureCard(
                            Icons.schedule_rounded,
                            'Smart Scheduling',
                            'AI-optimized study schedules that fit your lifestyle and maximize retention.',
                            const Color(0xFFEC4899),
                            2,
                          ),
                          _buildFeatureCard(
                            Icons.analytics_rounded,
                            'Progress Tracking',
                            'Detailed analytics and insights to monitor your learning journey.',
                            const Color(0xFF10B981),
                            3,
                          ),
                          _buildFeatureCard(
                            Icons.devices_rounded,
                            'Cross-Platform',
                            'Access your learning materials anywhere, anytime, on any device.',
                            const Color(0xFFF59E0B),
                            4,
                          ),
                          // FIX: Added a 6th feature card to make the grid even
                          _buildFeatureCard(
                            Icons.group_work_rounded,
                            'Collaborative Tools',
                            'Work with peers on projects in a shared, AI-assisted workspace.',
                            const Color(0xFF2DD4BF), // teal-400
                            5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(
              opacity: value,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(31),
                          Colors.white.withAlpha(15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(38),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withAlpha(204),
                                color.withAlpha(153),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(77),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withAlpha(204),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutUsSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AnimatedBuilder(
      animation: _aboutAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _aboutAnimation.value)),
          child: Opacity(
            opacity: _aboutAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 40,
                vertical: isMobile ? 60 : 80,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 32 : 48),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withAlpha(31),
                              Colors.white.withAlpha(20),
                              Colors.white.withAlpha(10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withAlpha(38),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'About AuraLearn',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 32 : 44,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Revolutionizing Education Through Technology',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'At AuraLearn, we believe that education should be accessible, personalized, and engaging for everyone. Our platform leverages cutting-edge artificial intelligence to create learning experiences that adapt to each individual\'s unique needs, preferences, and goals.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.white.withAlpha(230),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Stats row
                            Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildStatCard('10K+', 'Active Learners'),
                                _buildStatCard('500+', 'Courses Available'),
                                _buildStatCard('95%', 'Success Rate'),
                                _buildStatCard('24/7', 'AI Support'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String number, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(38),
                Colors.white.withAlpha(20),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(204),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(51),
                        Colors.black.withAlpha(102),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withAlpha(26),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40,
                      vertical: isMobile ? 32 : 48,
                    ),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'AuraLearn',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Empowering learners worldwide with AI-driven education.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.white.withAlpha(204),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withAlpha(51),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '© 2024 AuraLearn. All rights reserved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.white.withAlpha(153),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}