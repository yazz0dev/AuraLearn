import 'package:flutter/material.dart';

/// Shared animation utilities for consistent page transitions across the app
class PageTransitions {
  // Standard animation durations
  static const Duration standardDuration = Duration(milliseconds: 800);
  static const Duration fastDuration = Duration(milliseconds: 400);
  
  // Standard animation curves
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve fastCurve = Curves.easeOut;
  
  // Standard slide offset for subtle entrance
  static const Offset subtleSlideOffset = Offset(0, 0.03);
  
  /// Creates a subtle fade and slide animation for page content
  static Widget buildSubtlePageTransition({
    required AnimationController controller,
    required Widget child,
    double delay = 0.0,
    Duration? duration,
    Curve? curve,
    Offset? slideOffset,
  }) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay,
        1.0,
        curve: curve ?? standardCurve,
      ),
    );
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: slideOffset ?? subtleSlideOffset,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
  
  /// Creates a staggered animation for multiple elements
  static Widget buildStaggeredTransition({
    required AnimationController controller,
    required Widget child,
    required int index,
    int totalItems = 1,
    Duration? duration,
    Curve? curve,
  }) {
    final staggerDelay = (index * 0.1).clamp(0.0, 0.8);
    
    return buildSubtlePageTransition(
      controller: controller,
      child: child,
      delay: staggerDelay,
      duration: duration,
      curve: curve,
    );
  }
  
  /// Creates animation controller with standard settings
  static AnimationController createStandardController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: duration ?? standardDuration,
    );
  }
}