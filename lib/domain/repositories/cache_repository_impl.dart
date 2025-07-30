/**
 * Mock implementation of Cache Repository
 * Provides basic in-memory caching for development
 */

import '../models/cache_models.dart';
import 'base_repositories.dart';

/// Simple in-memory cache repository implementation
class CacheRepositoryImpl extends CacheRepository {
  final Map<String, OfflineCache> _cache = {};

  @override
  Future<OfflineCache?> getById(String id) async {
    return _cache[id];
  }

  @override
  Future<List<OfflineCache>> getAll() async {
    return _cache.values.toList();
  }

  @override
  Future<String> create(OfflineCache item) async {
    _cache[item.id] = item;
    return item.id;
  }

  @override
  Future<void> update(String id, OfflineCache item) async {
    _cache[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
  }

  @override
  Future<OfflineCache?> getCacheEntry(String key, String userId) async {
    return _cache.values
        .where((entry) => entry.key == key && entry.userId == userId)
        .firstOrNull;
  }

  @override
  Future<void> setCacheEntry(String key, String userId, OfflineCache entry) async {
    _cache[entry.id] = entry;
  }

  @override
  Future<void> clearCache(String userId) async {
    _cache.removeWhere((_, entry) => entry.userId == userId);
  }

  @override
  Future<void> clearExpiredEntries() async {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  @override
  Future<CacheStatistics> getCacheStatistics(String userId) async {
    final userEntries = _cache.values.where((entry) => entry.userId == userId);
    final totalSize = userEntries.fold<int>(0, (sum, entry) => sum + entry.dataSize);
    final totalAccess = userEntries.fold<int>(0, (sum, entry) => sum + entry.accessCount);
    
    return CacheStatistics(
      totalEntries: userEntries.length,
      totalReads: totalAccess,
      totalWrites: userEntries.length,
      cacheHits: totalAccess,
      cacheMisses: 0,
      expiredEntries: userEntries.where((entry) => entry.isExpired).length,
      clearedEntries: 0,
      totalSize: totalSize,
      memoryUsage: totalSize,
      lastUpdate: DateTime.now(),
    );
  }

  @override
  Future<CacheSizeInfo> getCacheSize(String userId) async {
    final userEntries = _cache.values.where((entry) => entry.userId == userId).toList();
    final totalSize = userEntries.fold<int>(0, (sum, entry) => sum + entry.dataSize);
    final avgSize = userEntries.isNotEmpty ? totalSize / userEntries.length : 0.0;
    
    DateTime? oldest, newest;
    if (userEntries.isNotEmpty) {
      oldest = userEntries.map((e) => e.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
      newest = userEntries.map((e) => e.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    return CacheSizeInfo(
      totalEntries: userEntries.length,
      totalSizeBytes: totalSize,
      averageEntrySize: avgSize,
      oldestEntry: oldest,
      newestEntry: newest,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}