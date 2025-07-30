/**
 * Base Repository Interfaces for FieldReady
 * Defines abstract interfaces for all repositories in the system
 */

import '../models/combine_models.dart';
import '../models/cache_models.dart';
import '../services/sync_service.dart';

/// Base interface for all repositories
abstract class BaseRepository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<String> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
}

/// Repository for sync operations
abstract class SyncRepository {
  Future<String> queueOperation(SyncOperation operation);
  Future<List<SyncOperation>> getPendingOperations(String userId);
  Future<List<SyncOperation>> getFailedOperations(String userId);
  Future<void> markOperationComplete(String operationId);
  Future<void> markOperationFailed(String operationId, String error);
  Future<SyncStatusData> getSyncStatus(String userId);
  Future<void> updateSyncStatus(SyncStatusData status);
  Future<void> cleanupCompletedOperations({int daysOld = 7});
}

/// Repository for user combines
abstract class UserCombineRepository extends BaseRepository<UserCombine> {
  Future<List<UserCombine>> getUserCombines(String userId);
  Future<List<UserCombine>> getActiveCombines(String userId);
  Future<UserCombine?> getUserCombineBySpecId(String userId, String combineSpecId);
  Future<void> setActiveStatus(String combineId, bool isActive);
}

/// Repository for cache entries
abstract class CacheRepository extends BaseRepository<OfflineCache> {
  Future<OfflineCache?> getCacheEntry(String key, String userId);
  Future<void> setCacheEntry(String key, String userId, OfflineCache entry);
  Future<void> clearCache(String userId);
  Future<void> clearExpiredEntries();
  Future<CacheStatistics> getCacheStatistics(String userId);
  Future<CacheSizeInfo> getCacheSize(String userId);
}

/// Repository for audit logs
abstract class AuditRepository extends BaseRepository<AuditLog> {
  Future<void> logEvent(AuditLog log);
  Future<List<AuditLog>> getUserLogs(String userId, {DateTime? startDate, DateTime? endDate});
  Future<List<AuditLog>> getCollectionLogs(String collection, {DateTime? startDate, DateTime? endDate});
  Future<void> clearOldLogs({int daysOld = 90});
  Future<Map<String, int>> getActionSummary(String userId, {DateTime? startDate, DateTime? endDate});
}