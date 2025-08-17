import 'package:auralearn/components/loading_widget.dart';
import 'package:auralearn/views/admin/create_subject.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/admin/edit_subject.dart';
import 'package:auralearn/views/admin/review_content.dart';
import 'package:auralearn/views/admin/subject_list.dart';
import 'package:auralearn/views/admin/user_management.dart';
import 'package:auralearn/views/forgot_password.dart';
import 'package:auralearn/views/kp/dashboard_kp.dart';
import 'package:auralearn/views/login.dart';
import 'package:auralearn/views/platform_aware_landing.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:auralearn/views/student/profile.dart';
import 'package:auralearn/views/student/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Notifier to expose authentication state changes to GoRouter.
/// This is the standard way to implement authentication-based redirects.
class GoRouterNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  GoRouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
      notifyListeners();
    });
  }

  bool get isLoggedIn => _isLoggedIn;
}

// Router configuration
final GoRouter router = GoRouter(
  refreshListenable: GoRouterNotifier(),
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) {
        // This builder acts as the new "AuthWrapper". It determines which
        // screen to show at the root level based on auth state and role.
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const PlatformAwareLandingScreen();
        }

        // If logged in, fetch role and show the correct dashboard.
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const AuraLearnLoadingWidget();
            }
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Edge case: user exists in auth but not in Firestore DB.
              return const PlatformAwareLandingScreen();
            }
            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'];
            debugPrint('User role detected: $role');
            switch (role) {
              case 'Admin':
                debugPrint('Navigating to Admin Dashboard');
                return const DashboardAdmin();
              case 'KP':
                debugPrint('Navigating to KP Dashboard');
                return const DashboardKP();
              case 'Student':
                debugPrint('Navigating to Student Dashboard');
                return const StudentDashboard();
              default:
                debugPrint('Unknown role: $role, showing landing screen');
                return const PlatformAwareLandingScreen();
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // Authenticated Routes
    GoRoute(
      path: '/student/dashboard',
      name: 'student-dashboard',
      builder: (context, state) => const StudentDashboard(),
    ),
    GoRoute(
      path: '/student/profile',
      name: 'student-profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/student/subjects',
      name: 'student-subjects',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text(
            'Subjects - Coming Soon',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/student/schedule',
      name: 'student-schedule',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text(
            'Schedule - Coming Soon',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/student/progress',
      name: 'student-progress',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text(
            'Progress - Coming Soon',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      builder: (context, state) => const DashboardAdmin(),
    ),
    GoRoute(
      path: '/admin/users',
      name: 'admin-users',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/admin/subjects',
      name: 'admin-subjects',
      builder: (context, state) => const SubjectListScreen(),
    ),
    GoRoute(
      path: '/admin/create-subject',
      name: 'admin-create-subject',
      builder: (context, state) => const CreateSubjectPage(),
    ),
    GoRoute(
      path: '/admin/edit-subject/:subjectId',
      name: 'admin-edit-subject',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        final subjectData = state.extra as Map<String, dynamic>;
        return EditSubjectPage(subjectId: subjectId, subjectData: subjectData);
      },
    ),
    GoRoute(
      path: '/admin/review-content',
      name: 'admin-review-content',
      builder: (context, state) => const ReviewContentPage(),
    ),
    GoRoute(
      path: '/kp/dashboard',
      name: 'kp-dashboard',
      builder: (context, state) => const DashboardKP(),
    ),
  ],
  redirect: (context, state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final String location = state.uri.toString();

    // Define routes that are part of the authentication flow.
    final bool isAuthenticating =
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password';

    // Define public routes that can be accessed without logging in.
    final bool isPublicRoute = location == '/';

    // If the user is not logged in and not on a public/auth route, redirect to login.
    if (!isLoggedIn && !isAuthenticating && !isPublicRoute) {
      return '/login';
    }

    // If the user is logged in but trying to access an auth page, redirect to home.
    // The home route's builder will then handle routing them to the correct dashboard.
    if (isLoggedIn && isAuthenticating) {
      return '/';
    }

    // No redirection needed.
    return null;
  },
);
