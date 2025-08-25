import 'package:auralearn/components/loading_widget.dart';
import 'package:auralearn/services/user_role_cache.dart';
import 'package:auralearn/views/admin/admin_layout.dart';
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
import 'package:auralearn/views/student/progress_screen.dart';
import 'package:auralearn/views/student/register.dart';
import 'package:auralearn/views/student/schedule_screen.dart';
import 'package:auralearn/views/student/student_layout.dart';
import 'package:auralearn/views/student/subjects_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/subject_model.dart';

/// Notifier to expose authentication state changes to GoRouter.
class GoRouterNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  GoRouterNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
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
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const PlatformAwareLandingScreen();
        }
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

    // --- ADMIN ROUTES ---
    GoRoute(
      path: '/admin/dashboard',
      name: 'admin-dashboard',
      builder: (context, state) => AdminLayout(
        page: 'dashboard',
        child: const DashboardAdmin(),
      ),
    ),
    GoRoute(
      path: '/admin/users',
      name: 'admin-users',
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/admin/dashboard');
        },
        child: AdminLayout(
          page: 'users',
          child: const UserManagementScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/admin/subjects',
      name: 'admin-subjects',
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/admin/dashboard');
        },
        child: AdminLayout(
          page: 'subjects',
          child: const SubjectListScreen(),
        ),
      ),
    ),

    // Admin routes that are NOT part of the shell
    GoRoute(
      path: '/admin/create-subject',
      name: 'admin-create-subject',
      builder: (context, state) => const CreateSubjectPage(),
    ),
    GoRoute(
      path: '/admin/edit-subject/:subjectId',
      name: 'admin-edit-subject',
      builder: (context, state) {
        final subject = state.extra as Subject;
        return EditSubjectPage(subject: subject);
      },
    ),
    GoRoute(
      path: '/admin/review-subject/:subjectId',
      name: 'admin-review-subject',
      builder: (context, state) {
        final subjectId = state.pathParameters['subjectId']!;
        return ReviewSubjectPage(subjectId: subjectId);
      },
    ),

    // --- STUDENT SHELL ROUTE ---
    ShellRoute(
      builder: (context, state, child) {
        final page = state.uri.pathSegments.last;
        return StudentLayout(page: page, key: const ValueKey('StudentShell'));
      },
      routes: [
        GoRoute(
          path: '/student/dashboard',
          name: 'student-dashboard',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/student/subjects',
          name: 'student-subjects',
          builder: (context, state) => const SubjectsScreen(),
        ),
        GoRoute(
          path: '/student/schedule',
          name: 'student-schedule',
          builder: (context, state) => const ScheduleScreen(),
        ),
        GoRoute(
          path: '/student/progress',
          name: 'student-progress',
          builder: (context, state) => const ProgressScreen(),
        ),
      ],
    ),
    
    // Student routes that are NOT part of the shell
    GoRoute(
      path: '/student/profile',
      name: 'student-profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // KP Routes
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
    final String location = state.uri.path;

    final bool isAuthenticating = location == '/login' ||
        location == '/register' ||
        location == '/forgot-password';

    final bool isPublicRoute = location == '/';

    if (!isLoggedIn && !isAuthenticating && !isPublicRoute) {
      return '/login';
    }

    if (isLoggedIn && (isAuthenticating || location == '/')) {
      final role = await UserRoleCache().getUserRole();
      switch (role) {
        case 'SuperAdmin':
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

    return null;
  },
);