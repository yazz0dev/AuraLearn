import 'package:auralearn/views/landing.dart';
import 'package:auralearn/views/m_landing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A widget that displays the appropriate landing screen based on the platform.
///
/// It shows the detailed `LandingScreen` for web and the simpler
/// `MobileLandingScreen` for mobile platforms (iOS, Android).
class PlatformAwareLandingScreen extends StatelessWidget {
  const PlatformAwareLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Use the original, feature-rich landing page for web
      return const LandingScreen();
    } else {
      // Use the new, streamlined landing page for mobile
      return const MobileLandingScreen();
    }
  }
}