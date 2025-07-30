/**
 * Cache Warming Service for FieldReady
 * Implements intelligent cache warming strategies to improve performance
 * and reduce API costs by pre-fetching frequently accessed data
 */

import 'dart:async';
import 'dart:math';

import '../models/cache_models.dart';
import '../repositories/cache_repository.dart';
import 'harvest_cache_service.dart';
import 'harvest_intelligence.dart';

/// Configuration for cache warming strategies
class CacheWarmingConfig {
  final Duration warmingInterval;
  final int maxConcurrentWarms;
  final double userActivityThreshold;
  final int maxLocationsPerWarm;
  final bool enableScheduledWarming;
  final bool enablePredictiveWarming;
  final List<CacheWarmingStrategy> strategies;

  const CacheWarmingConfig({
    this.warmingInterval = const Duration(hours: 6),
    this.maxConcurrentWarms = 3,
    this.userActivityThreshold = 0.1,
    this.maxLocationsPerWarm = 10,
    this.enableScheduledWarming = true,
    this.enablePredictiveWarming = true,
    this.strategies = const [],
  });
}

/// Cache warming service for proactive cache management
class CacheWarmingService {
  final HarvestCacheService _cacheService;
  final WeatherApiService _weatherApiService;
  final CacheRepository _cacheRepository;
  final CacheWarmingConfig _config;

  // Warming state
  Timer? _scheduledWarmingTimer;
  final Set<String> _currentlyWarming = {};
  final Map<String, DateTime> _lastWarmingTimes = {};
  final Map<String, int> _warmingAttempts = {};

  // Analytics
  int _totalWarmings = 0;
  int _successfulWarmings = 0;
  double _averageWarmingTime = 0.0;
  final List<CacheWarmingResult> _recentResults = [];

  CacheWarmingService({
    required HarvestCacheService cacheService,
    required WeatherApiService weatherApiService,
    required CacheRepository cacheRepository,
    CacheWarmingConfig? config,
  }) : _cacheService = cacheService,
       _weatherApiService = weatherApiService,
       _cacheRepository = cacheRepository,
       _config = config ?? const CacheWarmingConfig() {
    _initializeScheduledWarming();
  }

  /// Initialize scheduled cache warming
  void _initializeScheduledWarming() {
    if (!_config.enableScheduledWarming) return;

    _scheduledWarmingTimer = Timer.periodic(_config.warmingInterval, (_) {
      _performScheduledWarming();
    });
  }

  /// Perform scheduled cache warming for all active users
  Future<void> _performScheduledWarming() async {
    try {
      // Get list of active users based on recent cache activity
      final activeUsers = await _getActiveUsers();
      
      // Warm cache for each active user
      final warmingFutures = <Future<void>>[];
      for (final userId in activeUsers) {
        if (warmingFutures.length >= _config.maxConcurrentWarms) {
          break;
        }
        
        warmingFutures.add(_warmCacheForUser(userId));
      }

      await Future.wait(warmingFutures);
    } catch (e) {
      print('Scheduled cache warming failed: $e');
    }
  }

  /// Get list of active users based on cache activity
  Future<List<String>> _getActiveUsers() async {
    // This would typically query user activity from the database
    // For now, return a mock list based on cache statistics
    final users = <String>[];
    
    // Get users with recent cache activity
    // In a real implementation, this would query the database
    users.addAll(['user1', 'user2', 'user3']); // Mock data
    
    return users;
  }

  /// Warm cache for a specific user
  Future<CacheWarmingResult> warmCacheForUser(String userId) async {
    return await _warmCacheForUser(userId);
  }

  /// Internal method to warm cache for a user
  Future<CacheWarmingResult> _warmCacheForUser(String userId) async {
    if (_currentlyWarming.contains(userId)) {
      return CacheWarmingResult(
        userId: userId,
        success: false,
        strategy: 'user_specific',
        itemsWarmed: 0,
        timeElapsed: Duration.zero,
        error: 'Already warming cache for this user',
      );
    }

    _currentlyWarming.add(userId);
    final stopwatch = Stopwatch()..start();
    var itemsWarmed = 0;
    String? error;

    try {
      _totalWarmings++;
      
      // Get user's frequently accessed locations
      final locations = await _getUserFrequentLocations(userId);
      
      // Warm weather forecasts for these locations
      for (final location in locations.take(_config.maxLocationsPerWarm)) {
        try {
          // Check if already cached and fresh
          final cached = await _cacheService.getWeatherForecast(location, 7);
          if (cached == null || cached.isExpired) {
            await _weatherApiService.getForecast(location, 7);
            itemsWarmed++;
          }
          
          // Small delay to respect rate limits
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Failed to warm weather cache for location ${location.name}: $e');
        }
      }

      // Warm combine capabilities
      final userCombines = await _getUserCombines(userId);
      for (final combineId in userCombines) {
        try {
          final cached = await _cacheService.getCombineCapability(combineId);
          if (cached == null || 
              DateTime.now().difference(cached.calculatedAt) > const Duration(hours: 12)) {
            // This would trigger recalculation if needed
            itemsWarmed++;
          }
        } catch (e) {
          print('Failed to warm combine capability cache for $combineId: $e');
        }
      }

      // Predictive warming based on user patterns
      if (_config.enablePredictiveWarming) {
        await _performPredictiveWarming(userId);
      }

      _successfulWarmings++;
      _lastWarmingTimes[userId] = DateTime.now();
      _warmingAttempts[userId] = (_warmingAttempts[userId] ?? 0) + 1;

    } catch (e) {
      error = e.toString();
    } finally {
      _currentlyWarming.remove(userId);
      stopwatch.stop();
    }

    final result = CacheWarmingResult(
      userId: userId,
      success: error == null,
      strategy: 'user_specific',
      itemsWarmed: itemsWarmed,
      timeElapsed: stopwatch.elapsed,
      error: error,
    );

    _recentResults.add(result);
    if (_recentResults.length > 100) {
      _recentResults.removeAt(0);
    }

    // Update average warming time
    _averageWarmingTime = (_averageWarmingTime * (_totalWarmings - 1) + 
                          stopwatch.elapsedMilliseconds) / _totalWarmings;

    return result;
  }

  /// Get user's frequently accessed locations
  Future<List<FieldLocation>> _getUserFrequentLocations(String userId) async {
    // This would typically analyze user's location access patterns
    // For now, return mock data
    return [
      FieldLocation(
        id: 'field1',
        name: 'North Field',
        latitude: 45.0,
        longitude: -93.0,
        userId: userId,
      ),
      FieldLocation(
        id: 'field2', 
        name: 'South Field',
        latitude: 44.8,
        longitude: -93.2,
        userId: userId,
      ),
    ];
  }

  /// Get user's combines
  Future<List<String>> _getUserCombines(String userId) async {
    // This would query the user's active combines
    // For now, return mock data
    return ['combine1', 'combine2'];
  }

  /// Perform predictive cache warming based on user patterns
  Future<void> _performPredictiveWarming(String userId) async {
    // Analyze user patterns and pre-warm likely needed data
    // This could include:
    // - Weather for nearby locations
    // - Similar crop types
    // - Seasonal patterns
    
    try {
      // Get user's typical harvest times and pre-warm accordingly
      final currentMonth = DateTime.now().month;
      if (_isHarvestSeason(currentMonth)) {
        // Warm additional forecast days during harvest season
        final locations = await _getUserFrequentLocations(userId);
        for (final location in locations) {
          try {
            await _weatherApiService.getForecast(location, 10);
            await Future.delayed(const Duration(milliseconds: 150));
          } catch (e) {
            print('Predictive warming failed for ${location.name}: $e');
          }
        }
      }
    } catch (e) {
      print('Predictive warming failed for user $userId: $e');
    }
  }

  /// Check if current month is harvest season
  bool _isHarvestSeason(int month) {
    // Harvest season typically falls in late summer/early fall
    return month >= 8 && month <= 10;
  }

  /// Warm cache for specific locations and timeframes
  Future<CacheWarmingResult> warmCacheForLocations(
    List<FieldLocation> locations,
    int forecastDays,
  ) async {
    final stopwatch = Stopwatch()..start();
    var itemsWarmed = 0;
    String? error;

    try {
      for (final location in locations) {
        try {
          final cached = await _cacheService.getWeatherForecast(location, forecastDays);
          if (cached == null || cached.isExpired) {
            await _weatherApiService.getForecast(location, forecastDays);
            itemsWarmed++;
          }
          
          // Respect rate limits
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Failed to warm cache for location ${location.name}: $e');
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      stopwatch.stop();
    }

    return CacheWarmingResult(
      userId: 'system',
      success: error == null,
      strategy: 'location_specific',
      itemsWarmed: itemsWarmed,
      timeElapsed: stopwatch.elapsed,
      error: error,
    );
  }

  /// Execute custom warming strategy
  Future<CacheWarmingResult> executeWarmingStrategy(CacheWarmingStrategy strategy) async {
    if (!strategy.enabled) {
      return CacheWarmingResult(
        userId: 'system',
        success: false,
        strategy: strategy.name,
        itemsWarmed: 0,
        timeElapsed: Duration.zero,
        error: 'Strategy is disabled',
      );
    }

    final stopwatch = Stopwatch()..start();
    var itemsWarmed = 0;
    String? error;

    try {
      switch (strategy.name.toLowerCase()) {
        case 'weather_forecasts':
          itemsWarmed = await _warmWeatherForecasts(strategy);
          break;
        case 'combine_capabilities':
          itemsWarmed = await _warmCombineCapabilities(strategy);
          break;
        case 'harvest_windows':
          itemsWarmed = await _warmHarvestWindows(strategy);
          break;
        default:
          throw ArgumentError('Unknown warming strategy: ${strategy.name}');
      }
    } catch (e) {
      error = e.toString();
    } finally {
      stopwatch.stop();
    }

    return CacheWarmingResult(
      userId: 'system',
      success: error == null,
      strategy: strategy.name,
      itemsWarmed: itemsWarmed,
      timeElapsed: stopwatch.elapsed,
      error: error,
    );
  }

  /// Warm weather forecasts based on strategy
  Future<int> _warmWeatherForecasts(CacheWarmingStrategy strategy) async {
    // Implementation would depend on strategy parameters
    return 0; // Placeholder
  }

  /// Warm combine capabilities based on strategy
  Future<int> _warmCombineCapabilities(CacheWarmingStrategy strategy) async {
    // Implementation would depend on strategy parameters
    return 0; // Placeholder
  }

  /// Warm harvest windows based on strategy
  Future<int> _warmHarvestWindows(CacheWarmingStrategy strategy) async {
    // Implementation would depend on strategy parameters
    return 0; // Placeholder
  }

  /// Get warming statistics
  CacheWarmingStatistics getStatistics() {
    final successRate = _totalWarmings > 0 ? 
        _successfulWarmings / _totalWarmings : 0.0;
    
    return CacheWarmingStatistics(
      totalWarmings: _totalWarmings,
      successfulWarmings: _successfulWarmings,
      failedWarmings: _totalWarmings - _successfulWarmings,
      successRate: successRate,
      averageWarmingTimeMs: _averageWarmingTime,
      currentlyWarming: _currentlyWarming.length,
      recentResults: List.from(_recentResults),
    );
  }

  /// Get warming health report
  CacheWarmingHealthReport getHealthReport() {
    final stats = getStatistics();
    final warnings = <String>[];
    final recommendations = <String>[];

    // Analyze warming performance
    if (stats.successRate < 0.8) {
      warnings.add('Low warming success rate: ${(stats.successRate * 100).toStringAsFixed(1)}%');
      recommendations.add('Check API connectivity and rate limits');
    }

    if (stats.averageWarmingTimeMs > 10000) {
      warnings.add('Slow warming performance: ${stats.averageWarmingTimeMs.toStringAsFixed(0)}ms avg');
      recommendations.add('Consider reducing concurrent warming operations');
    }

    if (_currentlyWarming.length >= _config.maxConcurrentWarms) {
      warnings.add('Maximum concurrent warmings reached');
      recommendations.add('Monitor system load and adjust limits if needed');
    }

    // Calculate health score
    double healthScore = 1.0;
    healthScore -= (1.0 - stats.successRate) * 0.4; // Success rate impact
    healthScore -= min(stats.averageWarmingTimeMs / 10000, 1.0) * 0.3; // Speed impact
    healthScore -= (_currentlyWarming.length / _config.maxConcurrentWarms) * 0.3; // Load impact

    return CacheWarmingHealthReport(
      generatedAt: DateTime.now(),
      statistics: stats,
      warnings: warnings,
      recommendations: recommendations,
      healthScore: healthScore.clamp(0.0, 1.0),
    );
  }

  /// Stop all warming activities
  void stop() {
    _scheduledWarmingTimer?.cancel();
    _currentlyWarming.clear();
  }

  /// Dispose resources
  void dispose() {
    stop();
    _recentResults.clear();
    _lastWarmingTimes.clear();
    _warmingAttempts.clear();
  }
}

/// Result of a cache warming operation
class CacheWarmingResult {
  final String userId;
  final bool success;
  final String strategy;
  final int itemsWarmed;
  final Duration timeElapsed;
  final String? error;
  final DateTime timestamp;

  CacheWarmingResult({
    required this.userId,
    required this.success,
    required this.strategy,
    required this.itemsWarmed,
    required this.timeElapsed,
    this.error,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'success': success,
      'strategy': strategy,
      'itemsWarmed': itemsWarmed,
      'timeElapsedMs': timeElapsed.inMilliseconds,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CacheWarmingResult(user: $userId, success: $success, '
           'items: $itemsWarmed, time: ${timeElapsed.inMilliseconds}ms)';
  }
}

/// Statistics for cache warming operations
class CacheWarmingStatistics {
  final int totalWarmings;
  final int successfulWarmings;
  final int failedWarmings;
  final double successRate;
  final double averageWarmingTimeMs;
  final int currentlyWarming;
  final List<CacheWarmingResult> recentResults;

  CacheWarmingStatistics({
    required this.totalWarmings,
    required this.successfulWarmings,
    required this.failedWarmings,
    required this.successRate,
    required this.averageWarmingTimeMs,
    required this.currentlyWarming,
    required this.recentResults,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalWarmings': totalWarmings,
      'successfulWarmings': successfulWarmings,
      'failedWarmings': failedWarmings,
      'successRate': successRate,
      'averageWarmingTimeMs': averageWarmingTimeMs,
      'currentlyWarming': currentlyWarming,
      'recentResults': recentResults.map((r) => r.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'CacheWarmingStatistics(total: $totalWarmings, '
           'success: ${(successRate * 100).toStringAsFixed(1)}%, '
           'avgTime: ${averageWarmingTimeMs.toStringAsFixed(0)}ms)';
  }
}

/// Health report for cache warming
class CacheWarmingHealthReport {
  final DateTime generatedAt;
  final CacheWarmingStatistics statistics;
  final List<String> warnings;
  final List<String> recommendations;
  final double healthScore;

  CacheWarmingHealthReport({
    required this.generatedAt,
    required this.statistics,
    required this.warnings,
    required this.recommendations,
    required this.healthScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'statistics': statistics.toJson(),
      'warnings': warnings,
      'recommendations': recommendations,
      'healthScore': healthScore,
    };
  }

  @override
  String toString() {
    return 'CacheWarmingHealthReport(health: ${(healthScore * 100).toStringAsFixed(1)}%, '
           'warnings: ${warnings.length}, recommendations: ${recommendations.length})';
  }
}