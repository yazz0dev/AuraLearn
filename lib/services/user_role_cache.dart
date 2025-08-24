import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_data_service.dart';

/// Enhanced service to cache user role using the unified caching system
class UserRoleCache {
  static final UserRoleCache _instance = UserRoleCache._internal();
  factory UserRoleCache() => _instance;
  UserRoleCache._internal();

  final UserDataService _userDataService = UserDataService();

  /// Get user role with enhanced caching
  Future<String?> getUserRole({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      return await _userDataService.getUserRole(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  /// Check if user has specific role
  Future<bool> hasRole(String role, {bool forceRefresh = false}) async {
    final userRole = await getUserRole(forceRefresh: forceRefresh);
    return userRole?.toLowerCase() == role.toLowerCase();
  }

  /// Check if user is admin
  Future<bool> isAdmin({bool forceRefresh = false}) async {
    return await hasRole('Admin', forceRefresh: forceRefresh);
  }

  /// Check if user is student
  Future<bool> isStudent({bool forceRefresh = false}) async {
    return await hasRole('Student', forceRefresh: forceRefresh);
  }

  /// Check if user is KP (Knowledge Provider)
  Future<bool> isKP({bool forceRefresh = false}) async {
    return await hasRole('KP', forceRefresh: forceRefresh);
  }

  /// Get user role with fallback options
  Future<String> getUserRoleWithFallback({
    String fallback = 'Student',
    bool forceRefresh = false,
  }) async {
    final role = await getUserRole(forceRefresh: forceRefresh);
    return role ?? fallback;
  }

  /// Invalidate cache when user logs out
  Future<void> invalidateCache() async {
    await _userDataService.invalidateCache();
  }

  /// Refresh role cache
  Future<void> refreshCache() async {
    await getUserRole(forceRefresh: true);
  }

  /// Preload user role for better performance
  Future<void> preloadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Preload in background without waiting
      getUserRole().then((role) {
        debugPrint('User role preloaded: $role');
      }).catchError((e) {
        debugPrint('Error preloading user role: $e');
      });
    }
  }
}
