import 'package:auralearn/components/loading_widget.dart';
import 'package:auralearn/router.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/kp/dashboard_kp.dart';
import 'package:auralearn/views/platform_aware_landing.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // --- NEW: Import for kIsWeb ---
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // --- NEW: Import for URL Strategy ---
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- FIX: This line removes the # from the URL on the web. ---
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
          floatingLabelStyle: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFF3B82F6).withAlpha(150), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: Colors.white.withAlpha(179),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0), side: BorderSide.none),
          labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          brightness: Brightness.dark,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuraLearnLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const PlatformAwareLandingScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const AuraLearnLoadingWidget();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const PlatformAwareLandingScreen();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'];
            switch (role) {
              case 'Admin':
                return const DashboardAdmin();
              case 'KP':
                return const DashboardKP();
              case 'Student':
                return const StudentDashboard();
              default:
                return const PlatformAwareLandingScreen();
            }
          },
        );
      },
    );
  }
}