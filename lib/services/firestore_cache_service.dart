// lib/services/firestore_cache_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';
import 'cache_service.dart';

/// Enhanced Firestore service with intelligent caching
class FirestoreCacheService {
  static final FirestoreCacheService _instance = FirestoreCacheService._internal();
  factory FirestoreCacheService() => _instance;
  FirestoreCacheService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cache = CacheService();

  /// Get document with caching
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId, {
    Duration? cacheTtl,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'doc_${collection}_$documentId';
    
    if (!forceRefresh) {
      final cached = await _cache.get<Map<String, dynamic>>(cacheKey, ttl: cacheTtl);
      if (cached != null) {
        return cached;
      }
    }

    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['_id'] = doc.id;
        
        await _cache.set(cacheKey, data, ttl: cacheTtl);
        return data;
      }
    } catch (e) {
      debugPrint('Firestore error getting document $collection/$documentId: $e');
      
      final cached = await _cache.get<Map<String, dynamic>>(cacheKey, ttl: cacheTtl);
      if (cached != null) {
        debugPrint('Returning cached data due to Firestore error');
        return cached;
      }
    }

    return null;
  }

  /// Get collection with caching
  Future<List<Map<String, dynamic>>> getCollection(
    String collection, {
    Query Function(CollectionReference)? queryBuilder,
    Duration? cacheTtl,
    bool forceRefresh = false,
    int? limit,
  }) async {
    final queryHash = queryBuilder?.hashCode ?? 0;
    final cacheKey = 'collection_${collection}_${queryHash}_${limit ?? 'all'}';
    
    if (!forceRefresh) {
      final cached = await _cache.get<List<dynamic>>(cacheKey, ttl: cacheTtl);
      if (cached != null) {
        return cached.cast<Map<String, dynamic>>();
      }
    }

    try {
      Query query = _firestore.collection(collection);
      
      if (queryBuilder != null) {
        query = queryBuilder(_firestore.collection(collection));
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final documents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['_id'] = doc.id;
        return data;
      }).toList();

      await _cache.set(cacheKey, documents, ttl: cacheTtl);
      return documents;
    } catch (e) {
      debugPrint('Firestore error getting collection $collection: $e');
      
      final cached = await _cache.get<List<dynamic>>(cacheKey, ttl: cacheTtl);
      if (cached != null) {
        debugPrint('Returning cached collection data due to Firestore error');
        return cached.cast<Map<String, dynamic>>();
      }
    }

    return [];
  }

  /// Get user data with caching
  Future<Map<String, dynamic>?> getUserData(String userId, {bool forceRefresh = false}) async {
    return await getDocument(
      'users',
      userId,
      cacheTtl: const Duration(minutes: 30),
      forceRefresh: forceRefresh,
    );
  }

  /// Get subjects assigned to KP with caching
  Future<List<Map<String, dynamic>>> getKPSubjects(String kpId, {bool forceRefresh = false}) async {
    return await getCollection(
      'subjects',
      queryBuilder: (ref) => ref.where('assignedKpId', isEqualTo: kpId),
      cacheTtl: const Duration(hours: 1),
      forceRefresh: forceRefresh,
    );
  }

  /// Get all subjects with caching (for admin)
  Future<List<Map<String, dynamic>>> getAllSubjects({bool forceRefresh = false}) async {
    return await getCollection(
      'subjects',
      cacheTtl: const Duration(hours: 1),
      forceRefresh: forceRefresh,
    );
  }

  /// Get all KP (Knowledge Provider) users with caching
  Future<List<AppUser>> getKPUsers({bool forceRefresh = false}) async {
    final cacheKey = 'kp_users';

    if (!forceRefresh) {
      final cached = await _cache.get<List<dynamic>>(cacheKey, ttl: const Duration(minutes: 30));
      if (cached != null) {
        return cached.map((data) => AppUser.fromMap(data as Map<String, dynamic>)).toList();
      }
    }

    try {
      final users = await getCollection(
        'users',
        queryBuilder: (ref) => ref.where('role', isEqualTo: 'KP'),
        cacheTtl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );

      final kpUsers = users.map((userData) => AppUser.fromMap(userData)).toList();
      await _cache.set(cacheKey, users, ttl: const Duration(minutes: 30));
      return kpUsers;
    } catch (e) {
      debugPrint('Firestore error getting KP users: $e');

      final cached = await _cache.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        debugPrint('Returning cached KP users due to Firestore error');
        return cached.map((data) => AppUser.fromMap(data as Map<String, dynamic>)).toList();
      }
    }

    return [];
  }

  /// Get user counts with caching
  Future<Map<String, int>> getUserCounts({bool forceRefresh = false}) async {
    
    if (!forceRefresh) {
      final cached = await _cache.getCachedUserCounts();
      if (cached != null) {
        return cached;
      }
    }

    try {
      final usersCollection = _firestore.collection('users');
      
      final futures = await Future.wait([
        usersCollection.count().get(),
        usersCollection.where('role', isEqualTo: 'Student').count().get(),
        usersCollection.where('role', isEqualTo: 'KP').count().get(),
      ]);

      final counts = {
        'total': futures[0].count ?? 0,
        'students': futures[1].count ?? 0,
        'kps': futures[2].count ?? 0,
      };

      await _cache.cacheUserCounts(counts);
      return counts;
    } catch (e) {
      debugPrint('Firestore error getting user counts: $e');
      
      final cached = await _cache.getCachedUserCounts();
      if (cached != null) {
        debugPrint('Returning cached user counts due to Firestore error');
        return cached;
      }
    }

    return {'total': 0, 'students': 0, 'kps': 0};
  }

  /// Get topics pending review with caching
  Future<List<Map<String, dynamic>>> getTopicsPendingReview({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'topics_pending_review';
    
    if (!forceRefresh) {
      // --- FIX: Using the 'cacheKey' variable now ---
      final cached = await _cache.get<List<dynamic>>(cacheKey, ttl: const Duration(minutes: 5));
      if (cached != null) {
        return cached.cast<Map<String, dynamic>>();
      }
    }

    try {
      final snapshot = await _firestore
          .collectionGroup('topics')
          .where('status', isEqualTo: 'pending_review')
          .limit(limit)
          .get();

      final topics = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id;
        data['_path'] = doc.reference.path;
        return data;
      }).toList();

      // --- FIX: Using the 'cacheKey' variable now ---
      await _cache.set(cacheKey, topics, ttl: const Duration(minutes: 5));
      return topics;
    } catch (e) {
      debugPrint('Firestore error getting pending review topics: $e');
      
      // --- FIX: Using the 'cacheKey' variable now ---
      final cached = await _cache.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        debugPrint('Returning cached pending review topics due to Firestore error');
        return cached.cast<Map<String, dynamic>>();
      }
    }

    return [];
  }

  // --- FIX: Added new method to fetch subjects ready for admin review ---
  /// Get subjects pending admin review with caching
  Future<List<Map<String, dynamic>>> getSubjectsPendingReview({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'subjects_pending_review';
    
    if (!forceRefresh) {
      final cached = await _cache.get<List<dynamic>>(cacheKey, ttl: const Duration(minutes: 5));
      if (cached != null) {
        return cached.cast<Map<String, dynamic>>();
      }
    }

    try {
      final subjects = await getCollection(
        'subjects',
        queryBuilder: (ref) => ref.where('status', isEqualTo: 'admin_review').limit(limit),
        cacheTtl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
      );

      await _cache.set(cacheKey, subjects, ttl: const Duration(minutes: 5));
      return subjects;
    } catch (e) {
      debugPrint('Firestore error getting pending review subjects: $e');
      
      final cached = await _cache.get<List<dynamic>>(cacheKey);
      if (cached != null) {
        debugPrint('Returning cached pending review subjects due to Firestore error');
        return cached.cast<Map<String, dynamic>>();
      }
    }

    return [];
  }

  /// Update document and invalidate related cache
  Future<bool> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
      await _invalidateDocumentCache(collection, documentId);
      return true;
    } catch (e) {
      debugPrint('Firestore error updating document $collection/$documentId: $e');
      return false;
    }
  }

  /// Create document and invalidate related cache
  Future<String?> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      await _invalidateCollectionCache(collection);
      return docRef.id;
    } catch (e) {
      debugPrint('Firestore error creating document in $collection: $e');
      return null;
    }
  }

  /// Delete document and invalidate related cache
  Future<bool> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
      await _invalidateDocumentCache(collection, documentId);
      await _invalidateCollectionCache(collection);
      return true;
    } catch (e) {
      debugPrint('Firestore error deleting document $collection/$documentId: $e');
      return false;
    }
  }

  /// Invalidate cache for a specific document
  Future<void> _invalidateDocumentCache(String collection, String documentId) async {
    final cacheKey = 'doc_${collection}_$documentId';
    await _cache.remove(cacheKey);
    await _invalidateCollectionCache(collection);
  }

  /// Invalidate cache for a collection
  Future<void> _invalidateCollectionCache(String collection) async {
    final stats = _cache.getCacheStats();
    final keys = stats['memory_cache_keys'] as List<String>;
    
    for (final key in keys) {
      if (key.startsWith('collection_$collection')) {
        await _cache.remove(key);
      }
    }
    
    if (collection == 'users') {
      await _cache.remove('user_counts');
    }
    if (collection == 'subjects') {
      await _cache.remove('subjects_list');
    }
  }

  /// Clear all Firestore-related cache
  Future<void> clearCache() async {
    await _cache.clear();
  }

  /// Get real-time stream (no caching for real-time data)
  Stream<QuerySnapshot> getCollectionStream(
    String collection, {
    Query Function(CollectionReference)? queryBuilder,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);
    
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  /// Get subjects stream for real-time updates
  Stream<List<Subject>> getSubjectsStream() {
    return getCollectionStream('subjects').map((snapshot) {
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    });
  }

  /// Get real-time document stream (no caching for real-time data)
  Stream<DocumentSnapshot> getDocumentStream(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }
}