import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_data_service.dart';
import 'user_role_cache.dart';
import 'firestore_cache_service.dart';

/// Service to preload commonly used data for better performance
class CachePreloader {
  static final CachePreloader _instance = CachePreloader._internal();
  factory CachePreloader() => _instance;
  CachePreloader._internal();

  final UserDataService _userDataService = UserDataService();
  final UserRoleCache _userRoleCache = UserRoleCache();
  final FirestoreCacheService _firestoreCache = FirestoreCacheService();

  bool _isPreloading = false;
  bool _hasPreloaded = false;

  /// Preload essential data based on user role
  Future<void> preloadEssentialData() async {
    if (_isPreloading || _hasPreloaded) return;
    
    _isPreloading = true;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('CachePreloader: No authenticated user, skipping preload');
        return;
      }

      debugPrint('CachePreloader: Starting essential data preload for ${user.uid}');
      
      // Preload user data and role in parallel
      final futures = <Future>[
        _userDataService.preloadUserData(),
        _userRoleCache.preloadUserRole(),
      ];

      await Future.wait(futures);

      // Get user role to determine what else to preload
      final userRole = await _userRoleCache.getUserRole();
      debugPrint('CachePreloader: User role detected: $userRole');

      // Role-specific preloading
      switch (userRole?.toLowerCase()) {
        case 'superadmin':
        case 'admin':
          await _preloadAdminData();
          break;
        case 'kp':
          await _preloadKPData(user.uid);
          break;
        case 'student':
          await _preloadStudentData(user.uid);
          break;
        default:
          debugPrint('CachePreloader: Unknown role, skipping role-specific preload');
      }

      _hasPreloaded = true;
      debugPrint('CachePreloader: Essential data preload completed');
      
    } catch (e) {
      debugPrint('CachePreloader: Error during preload: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload data specific to admin users
  Future<void> _preloadAdminData() async {
    debugPrint('CachePreloader: Preloading admin data');
    
    try {
      // Preload user counts and subjects in parallel
      final futures = <Future>[
        _firestoreCache.getUserCounts(),
        _firestoreCache.getAllSubjects(),
        _firestoreCache.getTopicsPendingReview(limit: 5),
      ];

      await Future.wait(futures);
      debugPrint('CachePreloader: Admin data preloaded successfully');
    } catch (e) {
      debugPrint('CachePreloader: Error preloading admin data: $e');
    }
  }

  /// Preload data specific to KP users
  Future<void> _preloadKPData(String kpId) async {
    debugPrint('CachePreloader: Preloading KP data for $kpId');
    
    try {
      // Preload assigned subjects
      await _firestoreCache.getKPSubjects(kpId);
      debugPrint('CachePreloader: KP data preloaded successfully');
    } catch (e) {
      debugPrint('CachePreloader: Error preloading KP data: $e');
    }
  }

  /// Preload data specific to student users
  Future<void> _preloadStudentData(String studentId) async {
    debugPrint('CachePreloader: Preloading student data for $studentId');
    
    try {
      // For now, just ensure user profile is cached
      // In the future, you might preload enrolled subjects, progress, etc.
      await _userDataService.getUserProfile();
      debugPrint('CachePreloader: Student data preloaded successfully');
    } catch (e) {
      debugPrint('CachePreloader: Error preloading student data: $e');
    }
  }

  /// Preload data in background after app startup
  Future<void> preloadInBackground() async {
    // Run preloading in background without blocking UI
    Future.delayed(const Duration(milliseconds: 500), () {
      preloadEssentialData().catchError((e) {
        debugPrint('CachePreloader: Background preload failed: $e');
      });
    });
  }

  /// Clear preload state (useful for testing or user logout)
  void resetPreloadState() {
    _hasPreloaded = false;
    _isPreloading = false;
    debugPrint('CachePreloader: Preload state reset');
  }

  /// Check if preloading is in progress
  bool get isPreloading => _isPreloading;

  /// Check if essential data has been preloaded
  bool get hasPreloaded => _hasPreloaded;

  /// Force refresh all preloaded data
  Future<void> refreshPreloadedData() async {
    debugPrint('CachePreloader: Refreshing preloaded data');
    
    _hasPreloaded = false;
    await preloadEssentialData();
  }

  /// Preload specific data types on demand
  Future<void> preloadUserCounts() async {
    try {
      await _firestoreCache.getUserCounts(forceRefresh: true);
      debugPrint('CachePreloader: User counts refreshed');
    } catch (e) {
      debugPrint('CachePreloader: Error refreshing user counts: $e');
    }
  }

  /// Preload subjects for current user
  Future<void> preloadSubjects() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRole = await _userRoleCache.getUserRole();
      
      switch (userRole?.toLowerCase()) {
        case 'admin':
          await _firestoreCache.getAllSubjects(forceRefresh: true);
          break;
        case 'kp':
          await _firestoreCache.getKPSubjects(user.uid, forceRefresh: true);
          break;
        default:
          debugPrint('CachePreloader: No subject preloading for role: $userRole');
      }
      
      debugPrint('CachePreloader: Subjects refreshed for role: $userRole');
    } catch (e) {
      debugPrint('CachePreloader: Error refreshing subjects: $e');
    }
  }
}