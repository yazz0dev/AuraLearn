import 'package:auralearn/router.dart';
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
          fillColor: Colors.white.withAlpha(26),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
          floatingLabelStyle: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF3B82F6).withAlpha(150),
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.white.withAlpha(179),
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
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF3B82F6),
          inactiveTrackColor: Colors.white.withAlpha(51),
          thumbColor: Colors.white,
          overlayColor: const Color(0xFF3B82F6).withAlpha(50),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          trackHeight: 4.0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withAlpha(26),
          disabledColor: Colors.grey.shade800,
          selectedColor: const Color(0xFF3B82F6),
          secondarySelectedColor: Colors.lightBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide.none,
          ),
          labelStyle: const TextStyle(
            color: Colors.white70,
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


