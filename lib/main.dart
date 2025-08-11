// main.dart

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
          // Add content padding to contain the floating label correctly
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
        // User is not signed in
        if (!snapshot.hasData || snapshot.data == null) {
          return const LandingScreen();
        }

        // User is signed in, check role and redirect
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
          builder: (context, userSnapshot) {
            // While fetching user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user data doesn't exist (edge case) or there's an error, send to landing
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // This can happen if a user is in Auth but not Firestore.
              // Sending them to the landing page is a safe fallback.
              return const LandingScreen();
            }

            // User data exists, redirect based on role
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
                // Unknown role, redirect to landing as a fallback
                return const LandingScreen();
            }
          },
        );
      },
    );
  }
}