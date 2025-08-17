import 'package:flutter/foundation.dart';

class PlatformDetector {
  // Check if running on desktop platform
  static bool get isDesktopPlatform {
    return !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux
    );
  }

  // Check if running on mobile platform
  static bool get isMobilePlatform {
    return !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS
    );
  }

  // Check if running on web
  static bool get isWebPlatform {
    return kIsWeb;
  }

  // Get platform name for debugging
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }
}