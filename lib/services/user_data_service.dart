import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_cache_service.dart';
import 'cache_service.dart';

/// Enhanced service to manage user data with comprehensive caching
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  final FirestoreCacheService _firestoreCache = FirestoreCacheService();
  final CacheService _cache = CacheService();
  Stream<DocumentSnapshot>? _userStream;
  String? _currentUserId;

  /// Get user data with enhanced caching
  Future<Map<String, dynamic>?> getUserData({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _clearCache();
      return null;
    }

    _currentUserId = user.uid;

    try {
      return await _firestoreCache.getUserData(user.uid, forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Get user name from cached data or fetch if needed
  Future<String> getUserName({bool forceRefresh = false}) async {
    final userData = await getUserData(forceRefresh: forceRefresh);
    return userData?['name'] ?? 'User';
  }

  /// Get user role from cached data or fetch if needed
  Future<String?> getUserRole({bool forceRefresh = false}) async {
    final userData = await getUserData(forceRefresh: forceRefresh);
    return userData?['role'];
  }

  /// Get user email from cached data or fetch if needed
  Future<String?> getUserEmail({bool forceRefresh = false}) async {
    final userData = await getUserData(forceRefresh: forceRefresh);
    return userData?['email'];
  }

  /// Get user profile data for profile page
  Future<Map<String, dynamic>?> getUserProfile({bool forceRefresh = false}) async {
    final userData = await getUserData(forceRefresh: forceRefresh);
    if (userData == null) return null;

    return {
      'name': userData['name'] ?? 'User',
      'email': userData['email'] ?? '',
      'role': userData['role'] ?? '',
      'createdAt': userData['createdAt'],
      'lastLogin': userData['lastLogin'],
      'profilePicture': userData['profilePicture'],
    };
  }

  /// Update user data and refresh cache
  Future<bool> updateUserData(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Invalidate cache to force refresh on next access
      await _cache.invalidateUserCache(user.uid);
      
      return true;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      return false;
    }
  }

  /// Get a stream of user data for real-time updates
  Stream<DocumentSnapshot> getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    if (_userStream == null || _currentUserId != user.uid) {
      _currentUserId = user.uid;
      _userStream = _firestoreCache.getDocumentStream('users', user.uid);
    }

    return _userStream!;
  }

  /// Check if user has completed profile setup
  Future<bool> isProfileComplete({bool forceRefresh = false}) async {
    final userData = await getUserData(forceRefresh: forceRefresh);
    if (userData == null) return false;

    final requiredFields = ['name', 'email', 'role'];
    return requiredFields.every((field) => 
      userData.containsKey(field) && 
      userData[field] != null && 
      userData[field].toString().isNotEmpty
    );
  }

  /// Get user statistics (for admin dashboard)
  Future<Map<String, dynamic>?> getUserStats(String userId, {bool forceRefresh = false}) async {
    final cacheKey = 'user_stats_$userId';
    
    if (!forceRefresh) {
      final cached = await _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final userData = await getUserData(forceRefresh: forceRefresh);
      if (userData == null) return null;

      final stats = {
        'totalLogins': userData['totalLogins'] ?? 0,
        'lastLogin': userData['lastLogin'],
        'accountCreated': userData['createdAt'],
        'role': userData['role'],
        'isActive': userData['isActive'] ?? true,
      };

      await _cache.set(cacheKey, stats, ttl: const Duration(hours: 1));
      return stats;
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return null;
    }
  }

  /// Clear the cached user data
  Future<void> _clearCache() async {
    if (_currentUserId != null) {
      await _cache.invalidateUserCache(_currentUserId!);
    }
    _userStream = null;
    _currentUserId = null;
  }

  /// Invalidate cache when user logs out
  Future<void> invalidateCache() async {
    await _clearCache();
  }

  /// Refresh user data cache
  Future<void> refreshCache() async {
    if (_currentUserId != null) {
      await getUserData(forceRefresh: true);
    }
  }

  /// Preload user data for better performance
  Future<void> preloadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Preload in background without waiting
      getUserData().then((_) {
        debugPrint('User data preloaded for ${user.uid}');
      }).catchError((e) {
        debugPrint('Error preloading user data: $e');
      });
    }
  }
}
