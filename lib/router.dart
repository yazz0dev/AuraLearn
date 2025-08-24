import 'package:auralearn/components/loading_widget.dart';
import 'package:auralearn/services/user_role_cache.dart';
import 'package:auralearn/views/admin/create_subject.dart';
import 'package:auralearn/views/admin/dashboard_admin.dart';
import 'package:auralearn/views/admin/edit_subject.dart';
import 'package:auralearn/views/admin/review_subject.dart';
import 'package:auralearn/views/admin/subject_list.dart';
import 'package:auralearn/views/admin/user_management.dart';
import 'package:auralearn/views/forgot_password.dart';
import 'package:auralearn/views/kp/dashboard_kp.dart';
import 'package:auralearn/views/kp/upload_content.dart';
import 'package:auralearn/views/kp/review_content_kp.dart';
import 'package:auralearn/views/login.dart';
import 'package:auralearn/views/platform_aware_landing.dart';
import 'package:auralearn/views/student/dashboard.dart';
import 'package:auralearn/views/student/profile.dart';
import 'package:auralearn/views/student/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/subject_model.dart';

/// Notifier to expose authentication state changes to GoRouter.
/// This is the standard way to implement authentication-based redirects.
class GoRouterNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  GoRouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
      // Invalidate cache when user logs out
      if (user == null) {
        UserRoleCache().invalidateCache();
      }
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
        // This route should primarily show the landing page for non-authenticated users
        // Authenticated users will be redirected by the redirect logic above
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const PlatformAwareLandingScreen();
        }

        // Fallback: If somehow an authenticated user reaches here, show loading
        // while redirect logic handles them
        return const AuraLearnLoadingWidget();
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
        // Now 'extra' is a strongly-typed Subject object.
        final subject = state.extra as Subject;
        return EditSubjectPage(subject: subject);
      },
    ),
 // FIX: Removed the redundant '/admin/review-content' route
    GoRoute(
      path: '/admin/review-subject/:subjectId',
      name: 'admin-review-subject',
      builder: (context, state) {
        // FIX: Use the correctly renamed class and pass the parameter
        final subjectId = state.pathParameters['subjectId']!;
        return ReviewSubjectPage(subjectId: subjectId);
      },
    ),
    GoRoute(
      path: '/kp/dashboard',
      name: 'kp-dashboard',
      builder: (context, state) => const DashboardKP(),
    ),
    GoRoute(
      path: '/kp/upload-content/:subjectId',
      name: 'kp-upload-content',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        final type = state.uri.queryParameters['type'];
        return UploadContentPage(
          subjectId: subjectId,
          uploadType: type,
        );
      },
    ),
    GoRoute(
      path: '/kp/review-content/:subjectId',
      name: 'kp-review-content',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        return ReviewContentKPPage(subjectId: subjectId);
      },
    ),
  ],
  redirect: (context, state) async {
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

    // If the user is logged in but trying to access an auth page or home page,
    // redirect them to their role-specific dashboard.
    if (isLoggedIn && (isAuthenticating || location == '/')) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Use cached role to avoid repeated Firestore calls
          final role = await UserRoleCache().getUserRole();

          if (role != null) {
            switch (role) {
              case 'Admin':
                return '/admin/dashboard';
              case 'KP':
                return '/kp/dashboard';
              case 'Student':
                return '/student/dashboard';
              default:
                return '/';
            }
          }
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          return '/';
        }
      }
      return '/';
    }

    // No redirection needed.
    return null;
  },
);
