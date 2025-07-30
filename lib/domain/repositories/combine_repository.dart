/**
 * Repository interfaces for combine data management
 * Implements offline-first architecture with clean separation of concerns
 * Supports dependency injection and testability
 */

import '../models/combine_models.dart';
import '../models/cache_models.dart';
import '../models/common_types.dart';

/// Base repository interface for common operations
abstract class BaseRepository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<String> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
  Future<void> syncWithRemote();
}

/// Main repository interface for combine specifications
abstract class CombineRepository extends BaseRepository<CombineSpec> {
  /// Get combine specs by brand
  Future<List<CombineSpec>> getByBrand(String brand);
  
  /// Get combine specs by model
  Future<List<CombineSpec>> getByModel(String brand, String model);
  
  /// Get combine specs for a specific region
  Future<List<CombineSpec>> getByRegion(String region);
  
  /// Search combine specs with fuzzy matching
  Future<List<CombineSpec>> search(String query);
  
  /// Get user's personal combine specifications
  Future<List<CombineSpec>> getUserSpecs(String userId);
  
  /// Get public combine specifications for aggregation
  Future<List<CombineSpec>> getPublicSpecs({String? region, String? crop});
  
  /// Update moisture tolerance for a combine spec
  Future<void> updateMoistureTolerance(
    String specId, 
    MoistureTolerance tolerance
  );
  
  /// Update tough crop ability for a combine spec
  Future<void> updateToughCropAbility(
    String specId, 
    ToughCropAbility ability
  );
  
  /// Batch update multiple specs (for offline sync)
  Future<void> batchUpdate(List<CombineSpec> specs);
  
  /// Get specs that need syncing
  Future<List<CombineSpec>> getPendingSync();
  
  /// Mark spec as synced
  Future<void> markSynced(String specId);
}

/// Repository interface for user combine equipment
abstract class UserCombineRepository extends BaseRepository<UserCombine> {
  /// Get all combines for a specific user
  Future<List<UserCombine>> getByUserId(String userId);
  
  /// Get active combines for a user
  Future<List<UserCombine>> getActiveCombines(String userId);
  
  /// Get combine by nickname
  Future<UserCombine?> getByNickname(String userId, String nickname);
  
  /// Update custom settings for user combine
  Future<void> updateCustomSettings(
    String combineId, 
    Map<String, dynamic> settings
  );
  
  /// Add crop experience rating
  Future<void> addCropExperience(
    String combineId,
    String crop,
    int rating,
    String notes
  );
  
  /// Set combine as active/inactive
  Future<void> setActive(String combineId, bool isActive);
  
  /// Get combines that need syncing
  Future<List<UserCombine>> getPendingSync();
}

/// Repository interface for model normalization rules
abstract class NormalizationRepository {
  /// Get normalization rule by pattern
  Future<ModelNormalizationRule?> getRuleByPattern(String pattern);
  
  /// Get all active normalization rules
  Future<List<ModelNormalizationRule>> getActiveRules();
  
  /// Get rules by brand
  Future<List<ModelNormalizationRule>> getRulesByBrand(String brand);
  
  /// Create new normalization rule
  Future<String> createRule(ModelNormalizationRule rule);
  
  /// Update rule usage count
  Future<void> incrementUsageCount(String ruleId);
  
  /// Disable/enable rule
  Future<void> setRuleActive(String ruleId, bool isActive);
  
  /// Get brand aliases
  Future<List<BrandAlias>> getBrandAliases();
  
  /// Get model variants
  Future<List<ModelVariant>> getModelVariants();
  
  /// Add learned normalization from user correction
  Future<void> addLearning(NormalizationLearning learning);
  
  /// Get recent learning data for analysis
  Future<List<NormalizationLearning>> getRecentLearning({int limit = 100});
}

/// Repository interface for combine insights and aggregations
abstract class InsightRepository {
  /// Get regional insights for a specific region
  Future<RegionalInsight?> getRegionalInsight(String region);
  
  /// Get combine insights with progressive detail
  Future<CombineInsight?> getCombineInsights(
    String region, {
    String? level,
    String? crop,
    String? moistureRange,
  });
  
  /// Update regional aggregation data
  Future<void> updateRegionalInsight(RegionalInsight insight);
  
  /// Get insights by brand for a region
  Future<List<BrandInsight>> getBrandInsights(String region);
  
  /// Get insights by model for a region
  Future<List<ModelInsight>> getModelInsights(String region);
  
  /// Cache insight data for offline access
  Future<void> cacheInsight(CombineInsight insight);
  
  /// Get cached insights
  Future<CombineInsight?> getCachedInsight(String cacheKey);
  
  /// Clear expired cached insights
  Future<void> clearExpiredCache();
  
  /// Get insight generation statistics
  Future<InsightStats> getInsightStats(String region);
}

/// Repository interface for offline synchronization
abstract class SyncRepository {
  /// Queue a sync operation
  Future<String> queueOperation(SyncOperation operation);
  
  /// Get pending operations for a user
  Future<List<SyncOperation>> getPendingOperations(String userId);
  
  /// Get failed operations that need retry
  Future<List<SyncOperation>> getFailedOperations(String userId);
  
  /// Mark operation as completed
  Future<void> markOperationComplete(String operationId);
  
  /// Mark operation as failed with error details
  Future<void> markOperationFailed(String operationId, String error);
  
  /// Update operation retry count
  Future<void> incrementRetryCount(String operationId);
  
  /// Get sync status for a user
  Future<SyncStatus> getSyncStatus(String userId);
  
  /// Update sync status
  Future<void> updateSyncStatus(SyncStatus status);
  
  /// Clean up old completed operations
  Future<void> cleanupCompletedOperations({int daysOld = 7});
  
  /// Get operations by priority
  Future<List<SyncOperation>> getOperationsByPriority(
    String userId, 
    OperationPriority priority
  );
}

/// Repository interface for offline cache management
abstract class CacheRepository {
  /// Store data in offline cache
  Future<void> cacheData(
    String userId,
    String cacheKey,
    dynamic data,
    String collection,
    {String? documentId, Duration? expiry}
  );
  
  /// Retrieve cached data
  Future<OfflineCache?> getCachedData(String userId, String cacheKey);
  
  /// Get all cached data for a user
  Future<List<OfflineCache>> getUserCache(String userId);
  
  /// Remove cached data
  Future<void> removeCachedData(String userId, String cacheKey);
  
  /// Clear expired cache entries
  Future<void> clearExpiredCache(String userId);
  
  /// Get cache statistics
  Future<CacheStats> getCacheStats(String userId);
  
  /// Update cache access count and timestamp
  Future<void> updateCacheAccess(String cacheId);
  
  /// Get cache size for a user
  Future<int> getUserCacheSize(String userId);
  
  /// Clear all cache for a user
  Future<void> clearUserCache(String userId);
}

/// Repository interface for user preferences and settings
abstract class PreferencesRepository {
  /// Get user preferences
  Future<UserPreferences?> getUserPreferences(String userId);
  
  /// Update user preferences
  Future<void> updatePreferences(String userId, UserPreferences preferences);
  
  /// Update data sharing settings
  Future<void> updateDataSharing(String userId, DataSharingSettings settings);
  
  /// Update notification preferences
  Future<void> updateNotifications(String userId, NotificationSettings settings);
  
  /// Update privacy settings
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings);
  
  /// Get default preferences for new user
  UserPreferences getDefaultPreferences();
  
  /// Check if user allows data aggregation
  Future<bool> allowsDataAggregation(String userId);
  
  /// Check if user allows research data sharing
  Future<bool> allowsResearchSharing(String userId);
  
  /// Get users who opted out of data sharing
  Future<List<String>> getOptedOutUsers();
}

/// Repository interface for audit logging (PIPEDA compliance)
abstract class AuditRepository {
  /// Log an audit event
  Future<void> logEvent(AuditLog event);
  
  /// Get audit logs for a user
  Future<List<AuditLog>> getUserAuditLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });
  
  /// Get audit logs by action type
  Future<List<AuditLog>> getLogsByAction(
    String action, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });
  
  /// Get audit logs for compliance review
  Future<List<AuditLog>> getComplianceLogs({
    DateTime? startDate,
    DateTime? endDate,
    ComplianceLevel? level,
  });
  
  /// Clean up old audit logs per retention policy
  Future<void> cleanupOldLogs(int retentionDays);
  
  /// Export audit logs for user (PIPEDA right to data)
  Future<List<Map<String, dynamic>>> exportUserLogs(String userId);
  
  /// Delete user audit logs (right to be forgotten)
  Future<void> deleteUserLogs(String userId);
}

/// Repository interface for data retention policies
abstract class RetentionRepository {
  /// Get retention policy for a collection
  Future<DataRetentionPolicy?> getRetentionPolicy(String collection);
  
  /// Update retention policy
  Future<void> updateRetentionPolicy(DataRetentionPolicy policy);
  
  /// Get all retention policies
  Future<List<DataRetentionPolicy>> getAllPolicies();
  
  /// Execute retention cleanup for a collection
  Future<CleanupResult> executeCleanup(String collection);
  
  /// Schedule next cleanup
  Future<void> scheduleNextCleanup(String collection, DateTime nextRun);
  
  /// Get cleanup statistics
  Future<List<CleanupResult>> getCleanupHistory(String collection);
  
  /// Check if user is exempt from retention policy
  Future<bool> isUserExempt(String userId, String collection);
  
  /// Add user exemption
  Future<void> addUserExemption(String userId, String collection);
  
  /// Remove user exemption
  Future<void> removeUserExemption(String userId, String collection);
}

/// Supporting data classes for repository responses

class InsightStats {
  final String region;
  final int totalInsights;
  final int activeInsights;
  final DateTime lastGenerated;
  final String dataQuality;
  final Map<String, int> insightsByLevel;

  InsightStats({
    required this.region,
    required this.totalInsights,
    required this.activeInsights,
    required this.lastGenerated,
    required this.dataQuality,
    required this.insightsByLevel,
  });
}

class CacheStats {
  final String userId;
  final int totalEntries;
  final int totalSize;
  final int expiredEntries;
  final DateTime lastAccessed;
  final Map<String, int> sizeByCollection;

  CacheStats({
    required this.userId,
    required this.totalEntries,
    required this.totalSize,
    required this.expiredEntries,
    required this.lastAccessed,
    required this.sizeByCollection,
  });
}

class CleanupResult {
  final String collection;
  final int deletedCount;
  final int backedUpCount;
  final DateTime executedAt;
  final List<String> errors;

  CleanupResult({
    required this.collection,
    required this.deletedCount,
    required this.backedUpCount,
    required this.executedAt,
    required this.errors,
  });
}

enum OperationPriority { high, medium, low }
enum ComplianceLevel { required, optional, system }

/// Additional model classes for insights

class BrandInsight {
  final String brand;
  final int farmers;
  final int started;
  final double averageMoisture;
  final String moistureRange;
  final String recommendation;

  BrandInsight({
    required this.brand,
    required this.farmers,
    required this.started,
    required this.averageMoisture,
    required this.moistureRange,
    required this.recommendation,
  });
}

class ModelInsight {
  final String brand;
  final String model;
  final int farmers;
  final int started;
  final double averageMoisture;
  final String moistureRange;
  final double toughCropRating;
  final List<String> recommendations;
  final PeerComparison? peerComparison;

  ModelInsight({
    required this.brand,
    required this.model,
    required this.farmers,
    required this.started,
    required this.averageMoisture,
    required this.moistureRange,
    required this.toughCropRating,
    required this.recommendations,
    this.peerComparison,
  });
}

class PeerComparison {
  final List<String> betterThan;
  final List<String> similarTo;
  final List<String> challengedBy;

  PeerComparison({
    required this.betterThan,
    required this.similarTo,
    required this.challengedBy,
  });
}

class DataSharingSettings {
  final bool allowAggregation;
  final bool allowResearch;
  final bool shareLocation;

  DataSharingSettings({
    required this.allowAggregation,
    required this.allowResearch,
    required this.shareLocation,
  });
}

class NotificationSettings {
  final bool combineUpdates;
  final bool communityInsights;
  final bool systemAlerts;

  NotificationSettings({
    required this.combineUpdates,
    required this.communityInsights,
    required this.systemAlerts,
  });
}

class PrivacySettings {
  final int dataRetentionDays;
  final bool deleteOnInactive;
  final bool shareAnonymized;

  PrivacySettings({
    required this.dataRetentionDays,
    required this.deleteOnInactive,
    required this.shareAnonymized,
  });
}