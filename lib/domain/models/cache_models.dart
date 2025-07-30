/**
 * Cache Models for FieldReady
 * Defines data structures used by the caching system for offline storage,
 * statistics tracking, and cache management
 */


/// Offline cache entry for persistent storage
class OfflineCache {
  final String id;
  final String userId;
  final String key;
  final dynamic data;
  final String collection;
  final String? documentId;
  final DateTime createdAt;
  DateTime lastAccessed;
  final DateTime? expiresAt;
  int accessCount;
  final int dataSize;

  OfflineCache({
    required this.id,
    required this.userId,
    required this.key,
    required this.data,
    required this.collection,
    this.documentId,
    required this.createdAt,
    required this.lastAccessed,
    this.expiresAt,
    required this.accessCount,
    required this.dataSize,
  });

  /// Check if cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Age of cache entry
  Duration get age => DateTime.now().difference(createdAt);

  /// Time since last access
  Duration get timeSinceLastAccess => DateTime.now().difference(lastAccessed);

  /// Mark this cache entry as accessed
  void markAccessed() {
    accessCount++;
    lastAccessed = DateTime.now();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'key': key,
      'data': data,
      'collection': collection,
      'documentId': documentId,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'accessCount': accessCount,
      'dataSize': dataSize,
    };
  }

  /// Create from JSON
  factory OfflineCache.fromJson(Map<String, dynamic> json) {
    return OfflineCache(
      id: json['id'] as String,
      userId: json['userId'] as String,
      key: json['key'] as String,
      data: json['data'],
      collection: json['collection'] as String,
      documentId: json['documentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      accessCount: json['accessCount'] as int,
      dataSize: json['dataSize'] as int,
    );
  }

  @override
  String toString() {
    return 'OfflineCache(id: $id, key: $key, collection: $collection, '
           'accessCount: $accessCount, dataSize: $dataSize, '
           'isExpired: $isExpired)';
  }
}

/// Cache statistics for monitoring and optimization
class CacheStatistics {
  int totalEntries = 0;
  int totalReads = 0;
  int totalWrites = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int expiredEntries = 0;
  int clearedEntries = 0;
  int totalSize = 0;
  int memoryUsage = 0; // Added for HarvestIntelligenceService
  DateTime? lastUpdate;

  CacheStatistics({
    this.totalEntries = 0,
    this.totalReads = 0,
    this.totalWrites = 0,
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.expiredEntries = 0,
    this.clearedEntries = 0,
    this.totalSize = 0,
    this.memoryUsage = 0,
    this.lastUpdate,
  });

  /// Calculate hit rate
  double get hitRate {
    final totalRequests = cacheHits + cacheMisses;
    if (totalRequests == 0) return 0.0;
    return cacheHits / totalRequests;
  }

  /// Calculate miss rate
  double get missRate => 1.0 - hitRate;

  /// Average entry size
  double get averageEntrySize {
    if (totalEntries == 0) return 0.0;
    return totalSize / totalEntries;
  }

  /// Total requests property for compatibility
  int get totalRequests => totalReads;

  /// Update timestamp
  void updateTimestamp() {
    lastUpdate = DateTime.now();
  }

  /// Reset all statistics
  void reset() {
    totalEntries = 0;
    totalReads = 0;
    totalWrites = 0;
    cacheHits = 0;
    cacheMisses = 0;
    expiredEntries = 0;
    clearedEntries = 0;
    totalSize = 0;
    memoryUsage = 0;
    lastUpdate = DateTime.now();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'totalReads': totalReads,
      'totalWrites': totalWrites,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'expiredEntries': expiredEntries,
      'clearedEntries': clearedEntries,
      'totalSize': totalSize,
      'hitRate': hitRate,
      'missRate': missRate,
      'averageEntrySize': averageEntrySize,
      'memoryUsage': memoryUsage,
      'lastUpdate': lastUpdate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CacheStatistics.fromJson(Map<String, dynamic> json) {
    return CacheStatistics(
      totalEntries: json['totalEntries'] as int,
      totalReads: json['totalReads'] as int,
      totalWrites: json['totalWrites'] as int,
      cacheHits: json['cacheHits'] as int,
      cacheMisses: json['cacheMisses'] as int,
      expiredEntries: json['expiredEntries'] as int,
      clearedEntries: json['clearedEntries'] as int,
      totalSize: json['totalSize'] as int,
      memoryUsage: json['memoryUsage'] ?? 0,
      lastUpdate: json['lastUpdate'] != null 
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'CacheStatistics(entries: $totalEntries, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
           'size: ${(totalSize / 1024).toStringAsFixed(1)}KB)';
  }
}

/// Cache size information for monitoring
class CacheSizeInfo {
  final int totalEntries;
  final int totalSizeBytes;
  final double averageEntrySize;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  CacheSizeInfo({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.averageEntrySize,
    this.oldestEntry,
    this.newestEntry,
  });

  /// Total size in kilobytes
  double get totalSizeKB => totalSizeBytes / 1024;

  /// Total size in megabytes
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// Age span of cached data
  Duration? get ageSpan {
    if (oldestEntry == null || newestEntry == null) return null;
    return newestEntry!.difference(oldestEntry!);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'totalSizeBytes': totalSizeBytes,
      'totalSizeKB': totalSizeKB,
      'totalSizeMB': totalSizeMB,
      'averageEntrySize': averageEntrySize,
      'oldestEntry': oldestEntry?.toIso8601String(),
      'newestEntry': newestEntry?.toIso8601String(),
      'ageSpanHours': ageSpan?.inHours,
    };
  }

  /// Create from JSON
  factory CacheSizeInfo.fromJson(Map<String, dynamic> json) {
    return CacheSizeInfo(
      totalEntries: json['totalEntries'] as int,
      totalSizeBytes: json['totalSizeBytes'] as int,
      averageEntrySize: (json['averageEntrySize'] as num).toDouble(),
      oldestEntry: json['oldestEntry'] != null 
          ? DateTime.parse(json['oldestEntry'] as String)
          : null,
      newestEntry: json['newestEntry'] != null 
          ? DateTime.parse(json['newestEntry'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'CacheSizeInfo(entries: $totalEntries, size: ${totalSizeKB.toStringAsFixed(1)}KB, '
           'avgSize: ${averageEntrySize.toStringAsFixed(1)}B)';
  }
}

/// Cache performance metrics for analysis
class CachePerformanceMetrics {
  final DateTime timestamp;
  final Duration averageAccessTime;
  final Duration averageWriteTime;
  final int activeEntries;
  final int staleEntries;
  final double fragmentation;
  final Map<String, int> accessPatterns;

  CachePerformanceMetrics({
    required this.timestamp,
    required this.averageAccessTime,
    required this.averageWriteTime,
    required this.activeEntries,
    required this.staleEntries,
    required this.fragmentation,
    required this.accessPatterns,
  });

  /// Total entries (active + stale)
  int get totalEntries => activeEntries + staleEntries;

  /// Percentage of stale entries
  double get stalePercentage {
    if (totalEntries == 0) return 0.0;
    return staleEntries / totalEntries;
  }

  /// Cache health score (0-1, higher is better)
  double get healthScore {
    double score = 1.0;
    
    // Penalize high stale percentage
    score -= stalePercentage * 0.3;
    
    // Penalize high fragmentation
    score -= fragmentation * 0.2;
    
    // Penalize slow access times
    if (averageAccessTime.inMilliseconds > 100) {
      score -= 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'averageAccessTimeMs': averageAccessTime.inMilliseconds,
      'averageWriteTimeMs': averageWriteTime.inMilliseconds,
      'activeEntries': activeEntries,
      'staleEntries': staleEntries,
      'totalEntries': totalEntries,
      'stalePercentage': stalePercentage,
      'fragmentation': fragmentation,
      'healthScore': healthScore,
      'accessPatterns': accessPatterns,
    };
  }

  /// Create from JSON
  factory CachePerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return CachePerformanceMetrics(
      timestamp: DateTime.parse(json['timestamp'] as String),
      averageAccessTime: Duration(
        milliseconds: json['averageAccessTimeMs'] as int,
      ),
      averageWriteTime: Duration(
        milliseconds: json['averageWriteTimeMs'] as int,
      ),
      activeEntries: json['activeEntries'] as int,
      staleEntries: json['staleEntries'] as int,
      fragmentation: (json['fragmentation'] as num).toDouble(),
      accessPatterns: Map<String, int>.from(json['accessPatterns']),
    );
  }

  @override
  String toString() {
    return 'CachePerformanceMetrics(health: ${(healthScore * 100).toStringAsFixed(1)}%, '
           'active: $activeEntries, stale: $staleEntries, '
           'avgAccess: ${averageAccessTime.inMilliseconds}ms)';
  }
}

/// Cache warming strategy configuration
class CacheWarmingStrategy {
  final String name;
  final bool enabled;
  final Duration interval;
  final List<String> collections;
  final Map<String, dynamic> parameters;
  final int priority;

  CacheWarmingStrategy({
    required this.name,
    this.enabled = true,
    required this.interval,
    required this.collections,
    this.parameters = const {},
    this.priority = 5,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enabled': enabled,
      'intervalMs': interval.inMilliseconds,
      'collections': collections,
      'parameters': parameters,
      'priority': priority,
    };
  }

  /// Create from JSON
  factory CacheWarmingStrategy.fromJson(Map<String, dynamic> json) {
    return CacheWarmingStrategy(
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
      interval: Duration(milliseconds: json['intervalMs'] as int),
      collections: List<String>.from(json['collections']),
      parameters: Map<String, dynamic>.from(json['parameters']),
      priority: json['priority'] as int,
    );
  }

  @override
  String toString() {
    return 'CacheWarmingStrategy(name: $name, enabled: $enabled, '
           'interval: ${interval.inMinutes}min, priority: $priority)';
  }
}

/// Cache eviction policy configuration
class CacheEvictionPolicy {
  final String name;
  final EvictionStrategy strategy;
  final double thresholdPercentage;
  final int maxEntries;
  final Duration maxAge;
  final int minAccessCount;

  CacheEvictionPolicy({
    required this.name,
    required this.strategy,
    this.thresholdPercentage = 0.8,
    this.maxEntries = 1000,
    this.maxAge = const Duration(hours: 24),
    this.minAccessCount = 1,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'strategy': strategy.name,
      'thresholdPercentage': thresholdPercentage,
      'maxEntries': maxEntries,
      'maxAgeMs': maxAge.inMilliseconds,
      'minAccessCount': minAccessCount,
    };
  }

  /// Create from JSON
  factory CacheEvictionPolicy.fromJson(Map<String, dynamic> json) {
    return CacheEvictionPolicy(
      name: json['name'] as String,
      strategy: EvictionStrategy.values.firstWhere(
        (e) => e.name == json['strategy'],
      ),
      thresholdPercentage: (json['thresholdPercentage'] as num).toDouble(),
      maxEntries: json['maxEntries'] as int,
      maxAge: Duration(milliseconds: json['maxAgeMs'] as int),
      minAccessCount: json['minAccessCount'] as int,
    );
  }

  @override
  String toString() {
    return 'CacheEvictionPolicy(name: $name, strategy: ${strategy.name}, '
           'threshold: ${(thresholdPercentage * 100).toStringAsFixed(1)}%)';
  }
}

/// Eviction strategies
enum EvictionStrategy {
  lru,        // Least Recently Used
  lfu,        // Least Frequently Used
  fifo,       // First In, First Out
  random,     // Random eviction
  ttl,        // Time To Live based
  size,       // Size based
  hybrid,     // Combination of strategies
}

/// Cache health report
class CacheHealthReport {
  final DateTime generatedAt;
  final String userId;
  final CacheStatistics statistics;
  final CacheSizeInfo sizeInfo;
  final CachePerformanceMetrics performanceMetrics;
  final List<String> warnings;
  final List<String> recommendations;
  final double overallHealthScore;

  CacheHealthReport({
    required this.generatedAt,
    required this.userId,
    required this.statistics,
    required this.sizeInfo,
    required this.performanceMetrics,
    required this.warnings,
    required this.recommendations,
    required this.overallHealthScore,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'userId': userId,
      'statistics': statistics.toJson(),
      'sizeInfo': sizeInfo.toJson(),
      'performanceMetrics': performanceMetrics.toJson(),
      'warnings': warnings,
      'recommendations': recommendations,
      'overallHealthScore': overallHealthScore,
    };
  }

  /// Create from JSON
  factory CacheHealthReport.fromJson(Map<String, dynamic> json) {
    return CacheHealthReport(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      userId: json['userId'] as String,
      statistics: CacheStatistics.fromJson(json['statistics']),
      sizeInfo: CacheSizeInfo.fromJson(json['sizeInfo']),
      performanceMetrics: CachePerformanceMetrics.fromJson(json['performanceMetrics']),
      warnings: List<String>.from(json['warnings']),
      recommendations: List<String>.from(json['recommendations']),
      overallHealthScore: (json['overallHealthScore'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'CacheHealthReport(user: $userId, health: ${(overallHealthScore * 100).toStringAsFixed(1)}%, '
           'warnings: ${warnings.length}, recommendations: ${recommendations.length})';
  }
}

/// Weather API specific cache statistics
class WeatherApiCacheStats extends CacheStatistics {
  final int apiCallsSaved;
  final double costSavings;
  final int locationsCached;
  final Map<String, int> providerCacheHits;
  final Duration averageResponseTime;

  WeatherApiCacheStats({
    super.totalEntries,
    super.totalReads,
    super.totalWrites,
    super.cacheHits,
    super.cacheMisses,
    super.expiredEntries,
    super.clearedEntries,
    super.totalSize,
    super.memoryUsage,
    super.lastUpdate,
    required this.apiCallsSaved,
    required this.costSavings,
    required this.locationsCached,
    required this.providerCacheHits,
    required this.averageResponseTime,
  });

  /// Calculate cost savings rate
  double get costSavingsRate {
    if (totalReads == 0) return 0.0;
    return apiCallsSaved / totalReads;
  }

  /// Get most cached provider
  String get topCachedProvider {
    if (providerCacheHits.isEmpty) return 'none';
    return providerCacheHits.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.addAll({
      'apiCallsSaved': apiCallsSaved,
      'costSavings': costSavings,
      'locationsCached': locationsCached,
      'providerCacheHits': providerCacheHits,
      'averageResponseTimeMs': averageResponseTime.inMilliseconds,
      'costSavingsRate': costSavingsRate,
      'topCachedProvider': topCachedProvider,
    });
    return baseJson;
  }

  factory WeatherApiCacheStats.fromJson(Map<String, dynamic> json) {
    return WeatherApiCacheStats(
      totalEntries: json['totalEntries'] as int,
      totalReads: json['totalReads'] as int,
      totalWrites: json['totalWrites'] as int,
      cacheHits: json['cacheHits'] as int,
      cacheMisses: json['cacheMisses'] as int,
      expiredEntries: json['expiredEntries'] as int,
      clearedEntries: json['clearedEntries'] as int,
      totalSize: json['totalSize'] as int,
      memoryUsage: json['memoryUsage'] ?? 0,
      lastUpdate: json['lastUpdate'] != null 
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
      apiCallsSaved: json['apiCallsSaved'] as int,
      costSavings: (json['costSavings'] as num).toDouble(),
      locationsCached: json['locationsCached'] as int,
      providerCacheHits: Map<String, int>.from(json['providerCacheHits']),
      averageResponseTime: Duration(
        milliseconds: json['averageResponseTimeMs'] as int,
      ),
    );
  }

  @override
  String toString() {
    return 'WeatherApiCacheStats(entries: $totalEntries, '
           'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
           'apiCallsSaved: $apiCallsSaved, costSavings: \$${costSavings.toStringAsFixed(2)})';
  }
}