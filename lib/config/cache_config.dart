/// Cache configuration constants for the AuraLearn app
class CacheConfig {
  // Cache TTL (Time To Live) configurations
  static const Duration userDataTtl = Duration(minutes: 30);
  static const Duration userRoleTtl = Duration(minutes: 30);
  static const Duration subjectsTtl = Duration(hours: 1);
  static const Duration userCountsTtl = Duration(minutes: 5);
  static const Duration contentTtl = Duration(hours: 2);
  static const Duration aiResponseTtl = Duration(hours: 24);
  static const Duration aiPdfResponseTtl = Duration(days: 7);
  static const Duration reviewQueueTtl = Duration(minutes: 5);
  
  // Memory cache limits
  static const int maxMemoryCacheSize = 100;
  static const int maxImageCacheSize = 50 * 1024 * 1024; // 50MB
  
  // Cache keys
  static const String userDataPrefix = 'user_data_';
  static const String userRolePrefix = 'user_role_';
  static const String subjectsListKey = 'subjects_list';
  static const String userCountsKey = 'user_counts';
  static const String aiContentPrefix = 'ai_content_';
  static const String aiPdfPrefix = 'ai_pdf_';
  static const String reviewQueueKey = 'topics_pending_review';
  
  // Firestore collection cache keys
  static const String docPrefix = 'doc_';
  static const String collectionPrefix = 'collection_';
  
  // Cache cleanup intervals
  static const Duration cleanupInterval = Duration(hours: 6);
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  
  // Performance settings
  static const bool enableMemoryCache = true;
  static const bool enablePersistentCache = true;
  static const bool enableImageCache = true;
  static const bool enableAICache = true;
  
  // Debug settings
  static const bool enableCacheLogging = true;
  static const bool enableCacheStats = true;
  
  /// Get cache key for user data
  static String getUserDataKey(String userId) => '$userDataPrefix$userId';
  
  /// Get cache key for user role
  static String getUserRoleKey(String userId) => '$userRolePrefix$userId';
  
  /// Get cache key for document
  static String getDocumentKey(String collection, String documentId) => 
      '$docPrefix${collection}_$documentId';
  
  /// Get cache key for collection
  static String getCollectionKey(String collection, [String? queryHash]) => 
      '$collectionPrefix$collection${queryHash != null ? '_$queryHash' : ''}';
  
  /// Get cache key for AI content
  static String getAIContentKey(String promptHash) => '$aiContentPrefix$promptHash';
  
  /// Get cache key for AI PDF content
  static String getAIPdfKey(String promptHash, String pdfHash) => 
      '$aiPdfPrefix${promptHash}_$pdfHash';
  
  /// Get cache key for subject content
  static String getSubjectContentKey(String subjectId) => 'subject_content_$subjectId';
  
  /// Get cache key for user stats
  static String getUserStatsKey(String userId) => 'user_stats_$userId';
  
  /// Check if a cache key is for user-specific data
  static bool isUserSpecificKey(String key) {
    return key.startsWith(userDataPrefix) || 
           key.startsWith(userRolePrefix) ||
           key.startsWith('user_stats_');
  }
  
  /// Check if a cache key is for AI responses
  static bool isAIResponseKey(String key) {
    return key.startsWith(aiContentPrefix) || key.startsWith(aiPdfPrefix);
  }
  
  /// Check if a cache key is for Firestore data
  static bool isFirestoreKey(String key) {
    return key.startsWith(docPrefix) || key.startsWith(collectionPrefix);
  }
  
  /// Get appropriate TTL for a cache key
  static Duration getTtlForKey(String key) {
    if (key.startsWith(userDataPrefix) || key.startsWith(userRolePrefix)) {
      return userDataTtl;
    } else if (key == subjectsListKey || key.startsWith('subject_')) {
      return subjectsTtl;
    } else if (key == userCountsKey) {
      return userCountsTtl;
    } else if (key.startsWith(aiContentPrefix)) {
      return aiResponseTtl;
    } else if (key.startsWith(aiPdfPrefix)) {
      return aiPdfResponseTtl;
    } else if (key == reviewQueueKey) {
      return reviewQueueTtl;
    } else if (key.startsWith('content_')) {
      return contentTtl;
    }
    
    // Default TTL
    return const Duration(minutes: 15);
  }
}

/// Cache performance metrics
class CacheMetrics {
  static int _hits = 0;
  static int _misses = 0;
  static int _sets = 0;
  static int _removes = 0;
  
  static void recordHit() => _hits++;
  static void recordMiss() => _misses++;
  static void recordSet() => _sets++;
  static void recordRemove() => _removes++;
  
  static double get hitRate => _hits + _misses > 0 ? _hits / (_hits + _misses) : 0.0;
  
  static Map<String, dynamic> getMetrics() {
    return {
      'hits': _hits,
      'misses': _misses,
      'sets': _sets,
      'removes': _removes,
      'hit_rate': hitRate,
      'total_operations': _hits + _misses + _sets + _removes,
    };
  }
  
  static void reset() {
    _hits = 0;
    _misses = 0;
    _sets = 0;
    _removes = 0;
  }
}