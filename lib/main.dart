import 'package:auralearn/router.dart';
import 'package:auralearn/services/cache_service.dart';
import 'package:auralearn/services/cache_preloader.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_strategy/url_strategy.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove the # from URLs on web
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize cache service
  await CacheService().initialize();

  // Start background preloading after a short delay
  CachePreloader().preloadInBackground();

  // Disable App Check to avoid provider errors in development
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);

  // Optimize image cache for mobile performance
  // Reduce cache size to prevent memory pressure on mobile devices
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  // Clear cache periodically to prevent memory buildup
  PaintingBinding.instance.imageCache.clear();

  runApp(const AuraLearnApp());
}

class AuraLearnApp extends StatelessWidget {
  const AuraLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AuraLearn',
      routerConfig: router,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B), // Solid color instead of alpha
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(color: Color(0xFFB3B3B3)), // Solid color
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFCCCCCC), // Solid color
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF3B82F6), // Solid color
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: const Color(0xFFB3B3B3), // Solid color
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF3B82F6),
          inactiveTrackColor: Color(0xFF334155), // Solid color instead of alpha
          thumbColor: Colors.white,
          overlayColor: Color(0x403B82F6), // Reduced alpha overlay
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0),
          trackHeight: 4.0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1E293B), // Solid color instead of alpha
          disabledColor: Colors.grey.shade800,
          selectedColor: const Color(0xFF3B82F6),
          secondarySelectedColor: Colors.lightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide.none,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFFB3B3B3), // Solid color
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}


