/**
 * Cache Repository Interface for FieldReady
 * Defines the contract for persistent caching operations used by harvest intelligence
 * Supports both user-specific and system-wide caching with expiry and access tracking
 */

import 'dart:async';
import '../models/cache_models.dart';

/// Abstract repository for cache operations
abstract class CacheRepository {
  /// Store data in cache with optional expiry
  Future<void> cacheData(
    String userId,
    String key,
    dynamic data,
    String collection, {
    String? documentId,
    Duration? expiry,
  });

  /// Retrieve cached data by key
  Future<OfflineCache?> getCachedData(String userId, String key);

  /// Update cache access timestamp and count
  Future<void> updateCacheAccess(String cacheId);

  /// Clear expired cache entries for a user
  Future<void> clearExpiredCache(String userId);

  /// Clear all cache for a user
  Future<void> clearUserCache(String userId);

  /// Get cache statistics for monitoring
  Future<CacheStatistics> getCacheStatistics(String userId);

  /// Get cache size information
  Future<CacheSizeInfo> getCacheSize(String userId);

  /// Perform cache maintenance (cleanup, optimization)
  Future<void> performMaintenance();
}

/// Firebase implementation of cache repository
class FirebaseCacheRepository implements CacheRepository {
  // This would typically use Firestore for persistence
  // For now, we'll implement a simple in-memory version for testing
  
  final Map<String, Map<String, OfflineCache>> _cache = {};
  final Map<String, CacheStatistics> _stats = {};

  @override
  Future<void> cacheData(
    String userId,
    String key,
    dynamic data,
    String collection, {
    String? documentId,
    Duration? expiry,
  }) async {
    final userCache = _cache[userId] ??= {};
    final now = DateTime.now();
    
    final cacheEntry = OfflineCache(
      id: '${userId}_${key}_${now.millisecondsSinceEpoch}',
      userId: userId,
      key: key,
      data: data,
      collection: collection,
      documentId: documentId,
      createdAt: now,
      lastAccessed: now,
      expiresAt: expiry != null ? now.add(expiry) : null,
      accessCount: 1,
      dataSize: _calculateDataSize(data),
    );

    userCache[key] = cacheEntry;
    
    // Update statistics
    final stats = _stats[userId] ??= CacheStatistics();
    stats.totalEntries++;
    stats.totalWrites++;
    stats.totalSize += cacheEntry.dataSize;
  }

  @override
  Future<OfflineCache?> getCachedData(String userId, String key) async {
    final userCache = _cache[userId];
    if (userCache == null) return null;

    final cacheEntry = userCache[key];
    if (cacheEntry == null) return null;

    // Check if expired
    if (cacheEntry.expiresAt != null && 
        DateTime.now().isAfter(cacheEntry.expiresAt!)) {
      userCache.remove(key);
      
      // Update statistics
      final stats = _stats[userId];
      if (stats != null) {
        stats.totalEntries--;
        stats.expiredEntries++;
        stats.totalSize -= cacheEntry.dataSize;
      }
      
      return null;
    }

    // Update statistics
    final stats = _stats[userId];
    if (stats != null) {
      stats.totalReads++;
      stats.cacheHits++;
    }

    return cacheEntry;
  }

  @override
  Future<void> updateCacheAccess(String cacheId) async {
    // Find and update the cache entry
    for (final userCache in _cache.values) {
      for (final entry in userCache.values) {
        if (entry.id == cacheId) {
          entry.accessCount++;
          entry.lastAccessed = DateTime.now();
          return;
        }
      }
    }
  }

  @override
  Future<void> clearExpiredCache(String userId) async {
    final userCache = _cache[userId];
    if (userCache == null) return;

    final now = DateTime.now();
    final expiredKeys = <String>[];
    var expiredSize = 0;

    for (final entry in userCache.entries) {
      final cache = entry.value;
      if (cache.expiresAt != null && now.isAfter(cache.expiresAt!)) {
        expiredKeys.add(entry.key);
        expiredSize += cache.dataSize;
      }
    }

    // Remove expired entries
    for (final key in expiredKeys) {
      userCache.remove(key);
    }

    // Update statistics
    final stats = _stats[userId];
    if (stats != null) {
      stats.totalEntries -= expiredKeys.length;
      stats.expiredEntries += expiredKeys.length;
      stats.totalSize -= expiredSize;
    }
  }

  @override
  Future<void> clearUserCache(String userId) async {
    final userCache = _cache[userId];
    if (userCache == null) return;

    final entriesCleared = userCache.length;
    var sizeCleared = 0;

    for (final entry in userCache.values) {
      sizeCleared += entry.dataSize;
    }

    userCache.clear();

    // Update statistics
    final stats = _stats[userId];
    if (stats != null) {
      stats.totalEntries -= entriesCleared;
      stats.totalSize -= sizeCleared;
      stats.clearedEntries += entriesCleared;
    }
  }

  @override
  Future<CacheStatistics> getCacheStatistics(String userId) async {
    return _stats[userId] ?? CacheStatistics();
  }

  @override
  Future<CacheSizeInfo> getCacheSize(String userId) async {
    final userCache = _cache[userId];
    if (userCache == null) {
      return CacheSizeInfo(
        totalEntries: 0,
        totalSizeBytes: 0,
        averageEntrySize: 0,
        oldestEntry: null,
        newestEntry: null,
      );
    }

    var totalSize = 0;
    DateTime? oldest;
    DateTime? newest;

    for (final entry in userCache.values) {
      totalSize += entry.dataSize;
      
      if (oldest == null || entry.createdAt.isBefore(oldest)) {
        oldest = entry.createdAt;
      }
      
      if (newest == null || entry.createdAt.isAfter(newest)) {
        newest = entry.createdAt;
      }
    }

    return CacheSizeInfo(
      totalEntries: userCache.length,
      totalSizeBytes: totalSize,
      averageEntrySize: userCache.isNotEmpty ? totalSize / userCache.length : 0,
      oldestEntry: oldest,
      newestEntry: newest,
    );
  }

  @override
  Future<void> performMaintenance() async {
    // Clean up expired entries for all users
    for (final userId in _cache.keys) {
      await clearExpiredCache(userId);
    }

    // Additional maintenance tasks could include:
    // - Compacting data
    // - Analyzing access patterns
    // - Optimizing storage
  }

  /// Calculate approximate data size in bytes
  int _calculateDataSize(dynamic data) {
    if (data == null) return 0;
    
    // Simple approximation - in real implementation would be more sophisticated
    final jsonString = data.toString();
    return jsonString.length * 2; // Approximate UTF-16 encoding
  }
}

/// Mock implementation for testing
class MockCacheRepository implements CacheRepository {
  final Map<String, Map<String, OfflineCache>> _mockCache = {};
  final Map<String, CacheStatistics> _mockStats = {};

  @override
  Future<void> cacheData(
    String userId,
    String key,
    dynamic data,
    String collection, {
    String? documentId,
    Duration? expiry,
  }) async {
    final userCache = _mockCache[userId] ??= {};
    final now = DateTime.now();
    
    userCache[key] = OfflineCache(
      id: '${userId}_${key}_mock',
      userId: userId,
      key: key,
      data: data,
      collection: collection,
      documentId: documentId,
      createdAt: now,
      lastAccessed: now,
      expiresAt: expiry != null ? now.add(expiry) : null,
      accessCount: 1,
      dataSize: data.toString().length,
    );
  }

  @override
  Future<OfflineCache?> getCachedData(String userId, String key) async {
    return _mockCache[userId]?[key];
  }

  @override
  Future<void> updateCacheAccess(String cacheId) async {
    // Mock implementation - just update timestamp
    await Future.delayed(const Duration(milliseconds: 1));
  }

  @override
  Future<void> clearExpiredCache(String userId) async {
    final userCache = _mockCache[userId];
    if (userCache == null) return;

    final now = DateTime.now();
    userCache.removeWhere((key, cache) => 
      cache.expiresAt != null && now.isAfter(cache.expiresAt!));
  }

  @override
  Future<void> clearUserCache(String userId) async {
    _mockCache[userId]?.clear();
  }

  @override
  Future<CacheStatistics> getCacheStatistics(String userId) async {
    return _mockStats[userId] ?? CacheStatistics();
  }

  @override
  Future<CacheSizeInfo> getCacheSize(String userId) async {
    final userCache = _mockCache[userId];
    final entryCount = userCache?.length ?? 0;
    
    return CacheSizeInfo(
      totalEntries: entryCount,
      totalSizeBytes: entryCount * 100, // Mock size
      averageEntrySize: entryCount > 0 ? 100.0 : 0.0,
      oldestEntry: DateTime.now().subtract(const Duration(hours: 1)),
      newestEntry: DateTime.now(),
    );
  }

  @override
  Future<void> performMaintenance() async {
    // Mock maintenance
    for (final userId in _mockCache.keys) {
      await clearExpiredCache(userId);
    }
  }
}