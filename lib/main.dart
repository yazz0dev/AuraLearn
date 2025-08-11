// main.dart

import 'package:auralearn/components/loading_widget.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/kp/dashboard_kp.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'views/landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AuraLearnApp());
}

class AuraLearnApp extends StatelessWidget {
  const AuraLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraLearn',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withAlpha(26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
          prefixIconColor: Colors.white.withAlpha(179),
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        ),
         elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
          ),
        ),
      ),
      home: const AuthWrapper(),
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

        // --- THIS IS THE KEY LOGIC ---
        // If the snapshot has no data (i.e., user is null/logged out),
        // it returns the LandingScreen.
        if (!snapshot.hasData || snapshot.data == null) {
          return const LandingScreen();
        }

        // If the user is logged in, it proceeds to check their role.
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const AuraLearnLoadingWidget();
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Fallback for edge cases (e.g., user deleted from DB but not auth)
              return const LandingScreen();
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
                return const LandingScreen();
            }
          },
        );
      },
    );
  }
}