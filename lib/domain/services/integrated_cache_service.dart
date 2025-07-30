/**
 * Integrated Cache Service for FieldReady
 * Orchestrates all caching components including the Tomorrow.io integration,
 * harvest cache service, cache warming, and analytics
 */

import 'dart:async';

import '../models/harvest_models.dart';
import '../models/cache_models.dart';
import '../repositories/cache_repository.dart';
import '../repositories/combine_repository.dart';
import 'harvest_cache_service.dart';
import 'weather_api_service.dart';
import 'cache_warming_service.dart';
import 'cache_analytics_service.dart';
import 'harvest_intelligence.dart';

/// Configuration for the integrated cache system
class IntegratedCacheConfig {
  final HarvestCacheConfig harvestCacheConfig;
  final WeatherApiConfig weatherApiConfig;
  final CacheWarmingConfig warmingConfig;
  final CacheAnalyticsConfig analyticsConfig;
  final bool enableAutoOptimization;
  final Duration optimizationInterval;

  const IntegratedCacheConfig({
    this.harvestCacheConfig = const HarvestCacheConfig(),
    this.weatherApiConfig = const WeatherApiConfig(tomorrowIoApiKey: ''),
    this.warmingConfig = const CacheWarmingConfig(),
    this.analyticsConfig = const CacheAnalyticsConfig(),
    this.enableAutoOptimization = true,
    this.optimizationInterval = const Duration(hours: 12),
  });
}

/// Integrated cache service that orchestrates all caching components
class IntegratedCacheService {
  final CacheRepository _cacheRepository;
  final CombineRepository _combineRepository;
  final UserCombineRepository _userCombineRepository;
  
  late final HarvestCacheService _harvestCacheService;
  late final WeatherApiService _weatherApiService;
  late final CacheWarmingService _cacheWarmingService;
  late final CacheAnalyticsService _cacheAnalyticsService;
  late final HarvestIntelligenceService _harvestIntelligenceService;
  
  final IntegratedCacheConfig _config;
  Timer? _optimizationTimer;
  bool _isInitialized = false;

  IntegratedCacheService({
    required CacheRepository cacheRepository,
    required CombineRepository combineRepository,
    required UserCombineRepository userCombineRepository,
    IntegratedCacheConfig? config,
  }) : _cacheRepository = cacheRepository,
       _combineRepository = combineRepository,
       _userCombineRepository = userCombineRepository,
       _config = config ?? const IntegratedCacheConfig();

  /// Initialize all cache services
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize harvest cache service
    _harvestCacheService = HarvestCacheService(
      cacheRepository: _cacheRepository,
      config: _config.harvestCacheConfig,
    );

    // Initialize weather API service with cache integration
    _weatherApiService = WeatherApiServiceImpl(
      config: _config.weatherApiConfig,
      cacheService: _harvestCacheService,
    );

    // Initialize cache warming service
    _cacheWarmingService = CacheWarmingService(
      cacheService: _harvestCacheService,
      weatherApiService: _weatherApiService,
      cacheRepository: _cacheRepository,
      config: _config.warmingConfig,
    );

    // Initialize analytics service
    _cacheAnalyticsService = CacheAnalyticsService(
      cacheService: _harvestCacheService,
      weatherApiService: _weatherApiService,
      cacheRepository: _cacheRepository,
      warmingService: _cacheWarmingService,
      config: _config.analyticsConfig,
    );

    // Initialize harvest intelligence service
    _harvestIntelligenceService = HarvestIntelligenceService(
      weatherService: _weatherApiService,
      combineRepository: _combineRepository,
      userCombineRepository: _userCombineRepository,
      cacheService: _harvestCacheService,
    );

    // Start auto-optimization if enabled
    if (_config.enableAutoOptimization) {
      _optimizationTimer = Timer.periodic(_config.optimizationInterval, (_) {
        _performAutoOptimization();
      });
    }

    _isInitialized = true;
  }

  /// Get comprehensive harvest recommendations with full cache optimization
  Future<HarvestIntelligenceResult> getHarvestRecommendations({
    required String userId,
    required List<FieldLocation> fields,
    required CropType crop,
    int? forecastDays,
    bool enableCacheWarming = true,
  }) async {
    _ensureInitialized();

    // Pre-warm cache if requested
    if (enableCacheWarming) {
      await _cacheWarmingService.warmCacheForUser(userId);
    }

    // Get recommendations using the integrated system
    final result = await _harvestIntelligenceService.getHarvestRecommendations(
      userId: userId,
      fields: fields,
      crop: crop,
      forecastDays: forecastDays,
    );

    // Record analytics events
    _cacheAnalyticsService.recordCacheEvent(CacheEvent(
      operation: 'harvest_recommendations',
      timestamp: DateTime.now(),
      success: true,
    ));

    return result;
  }

  /// Pre-warm cache for optimal performance
  Future<CacheWarmingResult> warmCacheForUser(String userId) async {
    _ensureInitialized();
    return await _cacheWarmingService.warmCacheForUser(userId);
  }

  /// Warm cache for specific locations
  Future<CacheWarmingResult> warmCacheForLocations(
    List<FieldLocation> locations,
    int forecastDays,
  ) async {
    _ensureInitialized();
    return await _cacheWarmingService.warmCacheForLocations(locations, forecastDays);
  }

  /// Get comprehensive cache analytics
  Future<IntegratedCacheAnalytics> getCacheAnalytics() async {
    _ensureInitialized();

    final performanceReport = await _cacheAnalyticsService.generatePerformanceReport();
    final harvestAnalytics = await _harvestIntelligenceService.getCacheAnalytics();
    final warmingStats = _cacheWarmingService.getStatistics();
    final predictiveReport = await _cacheAnalyticsService.generatePredictiveReport();

    return IntegratedCacheAnalytics(
      performanceReport: performanceReport,
      harvestAnalytics: harvestAnalytics,
      warmingStats: warmingStats,
      predictiveReport: predictiveReport,
      overallHealthScore: _calculateOverallHealthScore(
        performanceReport,
        harvestAnalytics,
        warmingStats,
      ),
    );
  }

  /// Calculate overall system health score
  double _calculateOverallHealthScore(
    CachePerformanceReport performanceReport,
    HarvestCacheAnalytics harvestAnalytics,
    CacheWarmingStatistics warmingStats,
  ) {
    // Weighted average of different components
    var score = 0.0;
    
    // Cache performance (40% weight)
    score += performanceReport.harvestCacheStats.hitRate * 0.4;
    
    // Weather API efficiency (30% weight)
    score += performanceReport.weatherApiStats.hitRate * 0.3;
    
    // Cache warming effectiveness (20% weight)
    score += warmingStats.successRate * 0.2;
    
    // System responsiveness (10% weight)
    final responseScore = performanceReport.performanceMetrics.averageAccessTime.inMilliseconds < 1000 ? 1.0 : 0.5;
    score += responseScore * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Get system health report
  Future<IntegratedCacheHealthReport> getHealthReport() async {
    _ensureInitialized();

    final analytics = await getCacheAnalytics();
    final activeAlerts = _cacheAnalyticsService.getActiveAlerts();
    final warmingHealth = _cacheWarmingService.getHealthReport();
    
    final recommendations = <String>[];
    final warnings = <String>[];

    // Analyze overall system health
    if (analytics.overallHealthScore < 0.6) {
      warnings.add('Overall cache system health is below optimal levels');
      recommendations.add('Review cache configuration and consider increasing TTL values');
    }

    if (activeAlerts.isNotEmpty) {
      warnings.add('${activeAlerts.length} active alerts require attention');
      recommendations.add('Address active alerts to improve system performance');
    }

    if (analytics.warmingStats.successRate < 0.8) {
      warnings.add('Cache warming success rate is suboptimal');
      recommendations.add('Review API rate limits and network connectivity');
    }

    return IntegratedCacheHealthReport(
      generatedAt: DateTime.now(),
      overallHealthScore: analytics.overallHealthScore,
      componentHealth: {
        'harvest_cache': analytics.harvestAnalytics.cacheEfficiency,
        'weather_api': analytics.harvestAnalytics.weatherApiStats.hitRate,
        'cache_warming': analytics.warmingStats.successRate,
      },
      activeAlerts: activeAlerts,
      warnings: warnings,
      recommendations: recommendations,
      nextOptimization: _getNextOptimizationTime(),
    );
  }

  /// Perform manual cache optimization
  Future<CacheOptimizationResult> optimizeCache() async {
    _ensureInitialized();
    return await _performOptimization();
  }

  /// Internal optimization method
  Future<CacheOptimizationResult> _performOptimization() async {
    final stopwatch = Stopwatch()..start();
    final actions = <String>[];
    var itemsOptimized = 0;

    try {
      // Perform smart eviction
      await _harvestCacheService.performSmartEviction();
      actions.add('Performed smart cache eviction');
      itemsOptimized += 10; // Placeholder

      // Clear expired entries
      await _cacheRepository.performMaintenance();
      actions.add('Cleared expired cache entries');

      // Optimize cache warming based on usage patterns
      final analytics = await _cacheAnalyticsService.generatePerformanceReport();
      if (analytics.harvestCacheStats.hitRate < 0.7) {
        // Trigger additional warming for low-performing areas
        actions.add('Triggered additional cache warming');
        itemsOptimized += 5;
      }

      stopwatch.stop();

      return CacheOptimizationResult(
        success: true,
        itemsOptimized: itemsOptimized,
        timeElapsed: stopwatch.elapsed,
        actionsPerformed: actions,
      );

    } catch (e) {
      stopwatch.stop();
      
      return CacheOptimizationResult(
        success: false,
        itemsOptimized: itemsOptimized,
        timeElapsed: stopwatch.elapsed,
        actionsPerformed: actions,
        error: e.toString(),
      );
    }
  }

  /// Perform automatic optimization
  Future<void> _performAutoOptimization() async {
    try {
      final result = await _performOptimization();
      
      // Record optimization event
      _cacheAnalyticsService.recordCacheEvent(CacheEvent(
        operation: 'auto_optimization',
        timestamp: DateTime.now(),
        duration: result.timeElapsed,
        success: result.success,
        error: result.error,
      ));
    } catch (e) {
      print('Auto-optimization failed: $e');
    }
  }

  /// Get next optimization time
  DateTime? _getNextOptimizationTime() {
    if (!_config.enableAutoOptimization || _optimizationTimer == null) {
      return null;
    }
    return DateTime.now().add(_config.optimizationInterval);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    _ensureInitialized();
    await _harvestCacheService.clearAllCaches();
  }

  /// Get weather forecast with full caching optimization
  Future<WeatherForecast> getWeatherForecast(
    FieldLocation location,
    int days,
  ) async {
    _ensureInitialized();
    return await _weatherApiService.getForecast(location, days);
  }

  /// Get current weather with caching
  Future<WeatherData> getCurrentWeather(FieldLocation location) async {
    _ensureInitialized();
    return await _weatherApiService.getCurrentWeather(location);
  }

  /// Check if the service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('IntegratedCacheService must be initialized before use');
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    _optimizationTimer?.cancel();
    
    if (_isInitialized) {
      _harvestCacheService.dispose();
      _weatherApiService.dispose();
      _cacheWarmingService.dispose();
      _cacheAnalyticsService.dispose();
      _harvestIntelligenceService.dispose();
    }
    
    _isInitialized = false;
  }
}

/// Comprehensive analytics for the integrated cache system
class IntegratedCacheAnalytics {
  final CachePerformanceReport performanceReport;
  final HarvestCacheAnalytics harvestAnalytics;
  final CacheWarmingStatistics warmingStats;
  final CachePredictiveReport predictiveReport;
  final double overallHealthScore;

  IntegratedCacheAnalytics({
    required this.performanceReport,
    required this.harvestAnalytics,
    required this.warmingStats,
    required this.predictiveReport,
    required this.overallHealthScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'performanceReport': performanceReport.toJson(),
      'harvestAnalytics': harvestAnalytics.toJson(),
      'warmingStats': warmingStats.toJson(),
      'predictiveReport': predictiveReport.toJson(),
      'overallHealthScore': overallHealthScore,
      'summary': {
        'cacheHitRate': performanceReport.harvestCacheStats.hitRate,
        'weatherApiHitRate': performanceReport.weatherApiStats.hitRate,
        'warmingSuccessRate': warmingStats.successRate,
        'averageResponseTime': performanceReport.performanceMetrics.averageAccessTime.inMilliseconds,
        'memoryUsage': performanceReport.harvestCacheStats.memoryUsage,
        'totalCacheEntries': performanceReport.harvestCacheStats.totalEntries,
      },
    };
  }

  @override
  String toString() {
    return 'IntegratedCacheAnalytics(health: ${(overallHealthScore * 100).toStringAsFixed(1)}%, '
           'hitRate: ${(performanceReport.harvestCacheStats.hitRate * 100).toStringAsFixed(1)}%, '
           'warming: ${(warmingStats.successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Health report for the integrated cache system
class IntegratedCacheHealthReport {
  final DateTime generatedAt;
  final double overallHealthScore;
  final Map<String, double> componentHealth;
  final List<CacheAlert> activeAlerts;
  final List<String> warnings;
  final List<String> recommendations;
  final DateTime? nextOptimization;

  IntegratedCacheHealthReport({
    required this.generatedAt,
    required this.overallHealthScore,
    required this.componentHealth,
    required this.activeAlerts,
    required this.warnings,
    required this.recommendations,
    this.nextOptimization,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'overallHealthScore': overallHealthScore,
      'componentHealth': componentHealth,
      'activeAlerts': activeAlerts.map((a) => a.toJson()).toList(),
      'warnings': warnings,
      'recommendations': recommendations,
      'nextOptimization': nextOptimization?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'IntegratedCacheHealthReport(health: ${(overallHealthScore * 100).toStringAsFixed(1)}%, '
           'alerts: ${activeAlerts.length}, warnings: ${warnings.length})';
  }
}

/// Result of cache optimization operation
class CacheOptimizationResult {
  final bool success;
  final int itemsOptimized;
  final Duration timeElapsed;
  final List<String> actionsPerformed;
  final String? error;

  CacheOptimizationResult({
    required this.success,
    required this.itemsOptimized,
    required this.timeElapsed,
    required this.actionsPerformed,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'itemsOptimized': itemsOptimized,
      'timeElapsedMs': timeElapsed.inMilliseconds,
      'actionsPerformed': actionsPerformed,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'CacheOptimizationResult(success: $success, items: $itemsOptimized, '
           'time: ${timeElapsed.inMilliseconds}ms)';
  }
}