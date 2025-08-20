import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to cache user role and avoid repeated Firestore calls
class UserRoleCache {
  static final UserRoleCache _instance = UserRoleCache._internal();
  factory UserRoleCache() => _instance;
  UserRoleCache._internal();

  String? _cachedRole;
  String? _cachedUserId;
  DateTime? _lastFetchTime;

  /// Get user role with caching to avoid repeated Firestore calls
  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _clearCache();
      return null;
    }

    // If we have cached data for the same user and it's less than 5 minutes old, use it
    if (_cachedUserId == user.uid &&
        _cachedRole != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      return _cachedRole;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _cachedRole = data['role'];
        _cachedUserId = user.uid;
        _lastFetchTime = DateTime.now();
        return _cachedRole;
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }

    _clearCache();
    return null;
  }

  /// Clear the cached role data
  void _clearCache() {
    _cachedRole = null;
    _cachedUserId = null;
    _lastFetchTime = null;
  }

  /// Invalidate cache when user logs out
  void invalidateCache() {
    _clearCache();
  }
}
