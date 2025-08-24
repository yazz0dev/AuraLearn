// lib/services/cache_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/cache_config.dart'; // FIX: Import the cache configuration

/// Comprehensive caching service for the AuraLearn app
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cleanExpiredEntries();
  }

  /// Get cached data with automatic expiration handling
  Future<T?> get<T>(String key, {Duration? ttl}) async {
    await _ensureInitialized();

    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      debugPrint('Cache HIT (memory): $key');
      return memoryEntry.data as T?;
    }

    final persistentData = await _getPersistent(key);
    if (persistentData != null) {
      _memoryCache[key] = CacheEntry(
        data: persistentData,
        // FIX: Use default TTL from CacheConfig
        expiry: DateTime.now().add(ttl ?? CacheConfig.getTtlForKey(key)),
      );
      _limitMemoryCacheSize();
      debugPrint('Cache HIT (persistent): $key');
      return persistentData as T?;
    }

    debugPrint('Cache MISS: $key');
    return null;
  }

  /// Set cached data with TTL
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    await _ensureInitialized();

    // FIX: Use default TTL from CacheConfig
    final expiry = DateTime.now().add(ttl ?? CacheConfig.getTtlForKey(key));

    _memoryCache[key] = CacheEntry(data: data, expiry: expiry);
    _limitMemoryCacheSize();

    await _setPersistent(key, data, expiry);

    debugPrint('Cache SET: $key (expires: ${expiry.toIso8601String()})');
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    await _ensureInitialized();
    _memoryCache.remove(key);
    await _prefs!.remove('cache_data_$key');
    await _prefs!.remove('cache_expiry_$key');
    debugPrint('Cache REMOVE: $key');
  }

  /// Clear all cache entries
  Future<void> clear() async {
    await _ensureInitialized();
    _memoryCache.clear();
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith('cache_data_') || key.startsWith('cache_expiry_'));
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    debugPrint('Cache CLEAR: All entries removed');
  }

  Future<void> _cleanExpiredEntries() async {
    await _ensureInitialized();
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    final allKeys = _prefs!.getKeys();
    final expiryKeys = allKeys.where((key) => key.startsWith('cache_expiry_'));
    for (final expiryKey in expiryKeys) {
      final expiryString = _prefs!.getString(expiryKey);
      if (expiryString != null) {
        final expiry = DateTime.parse(expiryString);
        if (expiry.isBefore(DateTime.now())) {
          final dataKey = expiryKey.replaceFirst('cache_expiry_', 'cache_data_');
          await _prefs!.remove(dataKey);
          await _prefs!.remove(expiryKey);
        }
      }
    }
    debugPrint('Cache CLEANUP: Removed ${expiredKeys.length} expired entries');
  }

  Future<dynamic> _getPersistent(String key) async {
    final expiryString = _prefs!.getString('cache_expiry_$key');
    if (expiryString == null) return null;
    final expiry = DateTime.parse(expiryString);
    if (expiry.isBefore(DateTime.now())) {
      await _prefs!.remove('cache_data_$key');
      await _prefs!.remove('cache_expiry_$key');
      return null;
    }
    final dataString = _prefs!.getString('cache_data_$key');
    if (dataString == null) return null;
    try {
      return json.decode(dataString);
    } catch (e) {
      debugPrint('Cache decode error for $key: $e');
      return null;
    }
  }

  Future<void> _setPersistent(String key, dynamic data, DateTime expiry) async {
    try {
      final dataString = json.encode(data);
      await _prefs!.setString('cache_data_$key', dataString);
      await _prefs!.setString('cache_expiry_$key', expiry.toIso8601String());
    } catch (e) {
      debugPrint('Cache encode error for $key: $e');
    }
  }

  void _limitMemoryCacheSize() {
    // FIX: Use max size from CacheConfig
    if (_memoryCache.length > CacheConfig.maxMemoryCacheSize) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.expiry.compareTo(b.value.expiry));
      // FIX: Ensure the calculation is correct
      final toRemove = sortedEntries.take(_memoryCache.length - CacheConfig.maxMemoryCacheSize);
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  Future<void> cacheUserData(String userId, Map<String, dynamic> userData) async {
    // FIX: Use TTL from CacheConfig
    await set('user_data_$userId', userData, ttl: CacheConfig.userDataTtl);
  }

  Future<Map<String, dynamic>?> getCachedUserData(String userId) async {
    // FIX: Use TTL from CacheConfig
    return await get<Map<String, dynamic>>('user_data_$userId', ttl: CacheConfig.userDataTtl);
  }

  Future<void> cacheSubjects(List<Map<String, dynamic>> subjects) async {
    // FIX: Use TTL from CacheConfig
    await set('subjects_list', subjects, ttl: CacheConfig.subjectsTtl);
  }

  Future<List<Map<String, dynamic>>?> getCachedSubjects() async {
    // FIX: Use TTL from CacheConfig
    final cached = await get<List<dynamic>>('subjects_list', ttl: CacheConfig.subjectsTtl);
    return cached?.cast<Map<String, dynamic>>();
  }

  Future<void> cacheSubjectContent(String subjectId, Map<String, dynamic> content) async {
    // FIX: Use TTL from CacheConfig
    await set('subject_content_$subjectId', content, ttl: CacheConfig.contentTtl);
  }

  Future<Map<String, dynamic>?> getCachedSubjectContent(String subjectId) async {
    // FIX: Use TTL from CacheConfig
    return await get<Map<String, dynamic>>('subject_content_$subjectId', ttl: CacheConfig.contentTtl);
  }

  Future<void> cacheUserCounts(Map<String, int> counts) async {
    // FIX: Use TTL from CacheConfig
    await set('user_counts', counts, ttl: CacheConfig.userCountsTtl);
  }

  Future<Map<String, int>?> getCachedUserCounts() async {
    final cached = await get<Map<String, dynamic>>('user_counts');
    return cached?.map((key, value) => MapEntry(key, value as int));
  }

  Future<void> invalidateUserCache(String userId) async {
    await remove('user_data_$userId');
    await remove('user_role_$userId');
    debugPrint('Cache INVALIDATE: User cache cleared for $userId');
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'memory_cache_size': _memoryCache.length,
      'memory_cache_keys': _memoryCache.keys.toList(),
      'initialized': _prefs != null,
    };
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiry;

  CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}