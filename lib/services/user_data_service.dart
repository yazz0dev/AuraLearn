import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage user data with caching
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  Map<String, dynamic>? _cachedUserData;
  String? _cachedUserId;
  DateTime? _lastFetchTime;
  Stream<DocumentSnapshot>? _userStream;

  /// Get user data with caching
  Future<Map<String, dynamic>?> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _clearCache();
      return null;
    }

    // If we have cached data for the same user and it's less than 5 minutes old, use it
    if (_cachedUserId == user.uid &&
        _cachedUserData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5)) {
      return _cachedUserData;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        _cachedUserData = userDoc.data()!;
        _cachedUserId = user.uid;
        _lastFetchTime = DateTime.now();
        return _cachedUserData;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    _clearCache();
    return null;
  }

  /// Get user name from cached data or fetch if needed
  Future<String> getUserName() async {
    final userData = await getUserData();
    return userData?['name'] ?? 'Student';
  }

  /// Get user role from cached data or fetch if needed
  Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'];
  }

  /// Get a stream of user data for real-time updates
  Stream<DocumentSnapshot> getUserDataStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    if (_userStream == null || _cachedUserId != user.uid) {
      _cachedUserId = user.uid;
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    }

    return _userStream!;
  }

  /// Clear the cached user data
  void _clearCache() {
    _cachedUserData = null;
    _cachedUserId = null;
    _lastFetchTime = null;
    _userStream = null;
  }

  /// Invalidate cache when user logs out
  void invalidateCache() {
    _clearCache();
  }
}
