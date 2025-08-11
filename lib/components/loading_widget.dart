import 'package:flutter/material.dart';

class AuraLearnLoadingWidget extends StatefulWidget {
  const AuraLearnLoadingWidget({super.key});

  @override
  State<AuraLearnLoadingWidget> createState() => _AuraLearnLoadingWidgetState();
}

class _AuraLearnLoadingWidgetState extends State<AuraLearnLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A full-screen widget that only shows the loading animation.
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.school, color: Colors.white, size: 36),
              SizedBox(width: 16),
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
        ),
      ),
    );
  }
}