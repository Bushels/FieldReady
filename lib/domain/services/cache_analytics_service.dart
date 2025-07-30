/**
 * Cache Analytics and Monitoring Service for FieldReady
 * Provides comprehensive analytics, monitoring, and insights for the caching system
 * Helps optimize performance and identify issues proactively
 */

import 'dart:async';
import 'dart:math';

import '../models/cache_models.dart';
import '../repositories/cache_repository.dart';
import 'harvest_cache_service.dart';
import 'weather_api_service.dart';
import 'cache_warming_service.dart';

/// Configuration for cache analytics
class CacheAnalyticsConfig {
  final Duration reportingInterval;
  final Duration metricsRetentionPeriod;
  final bool enableRealTimeMonitoring;
  final bool enablePredictiveAnalytics;
  final double alertThresholdHitRate;
  final double alertThresholdResponseTime;
  final int maxStoredReports;

  const CacheAnalyticsConfig({
    this.reportingInterval = const Duration(hours: 1),
    this.metricsRetentionPeriod = const Duration(days: 30),
    this.enableRealTimeMonitoring = true,
    this.enablePredictiveAnalytics = true,
    this.alertThresholdHitRate = 0.7,
    this.alertThresholdResponseTime = 1000.0, // milliseconds
    this.maxStoredReports = 720, // 30 days of hourly reports
  });
}

/// Comprehensive cache analytics service
class CacheAnalyticsService {
  final HarvestCacheService _cacheService;
  final WeatherApiService _weatherApiService;
  final CacheWarmingService? _warmingService;
  final CacheRepository _cacheRepository;
  final CacheAnalyticsConfig _config;

  // Monitoring state
  Timer? _reportingTimer;
  final List<CachePerformanceReport> _historicalReports = [];
  final List<CacheAlert> _activeAlerts = [];
  final Map<String, List<double>> _performanceTimeSeries = {};

  // Real-time metrics
  final Map<String, int> _operationCounts = {};
  final Map<String, double> _operationTimes = {};
  final List<CacheEvent> _recentEvents = [];

  CacheAnalyticsService({
    required HarvestCacheService cacheService,
    required WeatherApiService weatherApiService,
    required CacheRepository cacheRepository,
    CacheWarmingService? warmingService,
    CacheAnalyticsConfig? config,
  }) : _cacheService = cacheService,
       _weatherApiService = weatherApiService,
       _warmingService = warmingService,
       _cacheRepository = cacheRepository,
       _config = config ?? const CacheAnalyticsConfig() {
    _initializeMonitoring();
  }

  /// Initialize monitoring and reporting
  void _initializeMonitoring() {
    if (_config.enableRealTimeMonitoring) {
      _reportingTimer = Timer.periodic(_config.reportingInterval, (_) {
        _generatePerformanceReport();
      });
    }
  }

  /// Generate comprehensive performance report
  Future<CachePerformanceReport> generatePerformanceReport() async {
    return await _generatePerformanceReport();
  }

  /// Internal method to generate performance report
  Future<CachePerformanceReport> _generatePerformanceReport() async {
    final timestamp = DateTime.now();
    
    // Collect statistics from all cache components
    final harvestCacheStats = _cacheService.getStatistics();
    final weatherApiStats = (_weatherApiService as WeatherApiServiceImpl)
        .getCacheStatistics();
    
    CacheWarmingStatistics? warmingStats;
    if (_warmingService != null) {
      warmingStats = _warmingService.getStatistics();
    }

    // Calculate performance metrics
    final performanceMetrics = await _calculatePerformanceMetrics();
    
    // Analyze trends
    final trends = _analyzeTrends();
    
    // Generate insights
    final insights = _generateInsights(
      harvestCacheStats,
      weatherApiStats,
      performanceMetrics,
    );

    // Check for alerts
    final alerts = _checkForAlerts(harvestCacheStats, performanceMetrics);

    final report = CachePerformanceReport(
      timestamp: timestamp,
      harvestCacheStats: harvestCacheStats,
      weatherApiStats: weatherApiStats,
      warmingStats: warmingStats,
      performanceMetrics: performanceMetrics,
      trends: trends,
      insights: insights,
      alerts: alerts,
    );

    // Store report
    _historicalReports.add(report);
    if (_historicalReports.length > _config.maxStoredReports) {
      _historicalReports.removeAt(0);
    }

    // Update time series data
    _updateTimeSeries(report);

    return report;
  }

  /// Calculate detailed performance metrics
  Future<CachePerformanceMetrics> _calculatePerformanceMetrics() async {
    final now = DateTime.now();
    
    // Calculate average response times
    final avgAccessTime = _operationTimes['access'] ?? 0.0;
    final avgWriteTime = _operationTimes['write'] ?? 0.0;
    
    // Count active vs stale entries
    final cacheStats = _cacheService.getStatistics();
    final activeEntries = cacheStats.totalEntries - cacheStats.expiredEntries;
    final staleEntries = cacheStats.expiredEntries;
    
    // Calculate fragmentation (simplified)
    final fragmentation = staleEntries > 0 ? 
        staleEntries / cacheStats.totalEntries : 0.0;
    
    // Analyze access patterns
    final accessPatterns = _analyzeAccessPatterns();

    return CachePerformanceMetrics(
      timestamp: now,
      averageAccessTime: Duration(milliseconds: avgAccessTime.round()),
      averageWriteTime: Duration(milliseconds: avgWriteTime.round()),
      activeEntries: activeEntries,
      staleEntries: staleEntries,
      fragmentation: fragmentation,
      accessPatterns: accessPatterns,
    );
  }

  /// Analyze access patterns
  Map<String, int> _analyzeAccessPatterns() {
    final patterns = <String, int>{};
    
    for (final event in _recentEvents) {
      final hour = event.timestamp.hour;
      final key = 'hour_$hour';
      patterns[key] = (patterns[key] ?? 0) + 1;
    }
    
    return patterns;
  }

  /// Analyze performance trends
  CacheTrendAnalysis _analyzeTrends() {
    if (_historicalReports.length < 2) {
      return CacheTrendAnalysis(
        hitRateTrend: TrendDirection.stable,
        responseTimeTrend: TrendDirection.stable,
        cacheSizeTrend: TrendDirection.stable,
        errorRateTrend: TrendDirection.stable,
        trendStrength: 0.0,
      );
    }

    final recent = _historicalReports.takeLast(24).toList(); // Last 24 hours
    
    // Calculate hit rate trend
    final hitRates = recent.map((r) => r.harvestCacheStats.hitRate).toList();
    final hitRateTrend = _calculateTrendDirection(hitRates);
    
    // Calculate response time trend
    final responseTimes = recent
        .map((r) => r.performanceMetrics.averageAccessTime.inMilliseconds.toDouble())
        .toList();
    final responseTimeTrend = _calculateTrendDirection(responseTimes);
    
    // Calculate cache size trend
    final cacheSizes = recent
        .map((r) => r.harvestCacheStats.memoryUsage.toDouble())
        .toList();
    final cacheSizeTrend = _calculateTrendDirection(cacheSizes);
    
    // Calculate error rate trend (simplified)
    final errorRates = recent
        .map((r) => r.harvestCacheStats.missRate)
        .toList();
    final errorRateTrend = _calculateTrendDirection(errorRates);
    
    // Calculate overall trend strength
    final trendStrength = _calculateTrendStrength([
      hitRates,
      responseTimes,
      cacheSizes,
      errorRates,
    ]);

    return CacheTrendAnalysis(
      hitRateTrend: hitRateTrend,
      responseTimeTrend: responseTimeTrend,
      cacheSizeTrend: cacheSizeTrend,
      errorRateTrend: errorRateTrend,
      trendStrength: trendStrength,
    );
  }

  /// Calculate trend direction for a series of values
  TrendDirection _calculateTrendDirection(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;
    
    var increasingCount = 0;
    var decreasingCount = 0;
    
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[i - 1]) {
        increasingCount++;
      } else if (values[i] < values[i - 1]) {
        decreasingCount++;
      }
    }
    
    final totalComparisons = values.length - 1;
    final increasingRatio = increasingCount / totalComparisons;
    final decreasingRatio = decreasingCount / totalComparisons;
    
    if (increasingRatio > 0.6) {
      return TrendDirection.increasing;
    } else if (decreasingRatio > 0.6) {
      return TrendDirection.decreasing;
    } else {
      return TrendDirection.stable;
    }
  }

  /// Calculate trend strength
  double _calculateTrendStrength(List<List<double>> valuesSeries) {
    var totalStrength = 0.0;
    var validSeries = 0;
    
    for (final values in valuesSeries) {
      if (values.length < 2) continue;
      
      // Calculate coefficient of variation
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values
          .map((v) => pow(v - mean, 2))
          .reduce((a, b) => a + b) / values.length;
      final cv = sqrt(variance) / mean;
      
      totalStrength += cv;
      validSeries++;
    }
    
    return validSeries > 0 ? (totalStrength / validSeries).clamp(0.0, 1.0) : 0.0;
  }

  /// Generate insights based on performance data
  List<CacheInsight> _generateInsights(
    CacheStatistics harvestStats,
    WeatherApiCacheStats weatherStats,
    CachePerformanceMetrics performanceMetrics,
  ) {
    final insights = <CacheInsight>[];
    
    // Hit rate insights
    if (harvestStats.hitRate < 0.5) {
      insights.add(CacheInsight(
        type: InsightType.performance,
        severity: InsightSeverity.high,
        title: 'Low Cache Hit Rate',
        description: 'Cache hit rate is ${(harvestStats.hitRate * 100).toStringAsFixed(1)}%, '
                    'which may indicate inefficient caching strategies.',
        recommendation: 'Consider adjusting cache TTL settings or implementing '
                      'more aggressive pre-warming strategies.',
        impact: InsightImpact.high,
      ));
    }
    
    // Response time insights
    if (performanceMetrics.averageAccessTime.inMilliseconds > 500) {
      insights.add(CacheInsight(
        type: InsightType.performance,
        severity: InsightSeverity.medium,
        title: 'Slow Cache Access',
        description: 'Average cache access time is '
                    '${performanceMetrics.averageAccessTime.inMilliseconds}ms, '
                    'which may impact user experience.',
        recommendation: 'Investigate cache storage optimization or consider '
                      'implementing cache partitioning.',
        impact: InsightImpact.medium,
      ));
    }
    
    // Memory usage insights
    if (harvestStats.memoryUsage > 800) {
      insights.add(CacheInsight(
        type: InsightType.resource,
        severity: InsightSeverity.medium,
        title: 'High Memory Usage',
        description: 'Cache is using ${harvestStats.memoryUsage} units of memory, '
                    'approaching capacity limits.',
        recommendation: 'Implement more aggressive eviction policies or '
                      'increase cache size limits.',
        impact: InsightImpact.medium,
      ));
    }
    
    // API cost insights
    if (weatherStats.hitRate < 0.8) {
      insights.add(CacheInsight(
        type: InsightType.cost,
        severity: InsightSeverity.low,
        title: 'API Cost Optimization Opportunity',
        description: 'Weather API cache hit rate is '
                    '${(weatherStats.hitRate * 100).toStringAsFixed(1)}%, '
                    'indicating potential cost savings.',
        recommendation: 'Extend weather forecast cache duration or implement '
                      'location clustering for better cache utilization.',
        impact: InsightImpact.low,
      ));
    }
    
    return insights;
  }

  /// Check for performance alerts
  List<CacheAlert> _checkForAlerts(
    CacheStatistics stats,
    CachePerformanceMetrics metrics,
  ) {
    final alerts = <CacheAlert>[];
    final now = DateTime.now();
    
    // Hit rate alert
    if (stats.hitRate < _config.alertThresholdHitRate) {
      alerts.add(CacheAlert(
        id: 'hit_rate_low',
        type: AlertType.performance,
        severity: AlertSeverity.warning,
        title: 'Low Cache Hit Rate',
        message: 'Cache hit rate (${(stats.hitRate * 100).toStringAsFixed(1)}%) '
                'is below threshold (${(_config.alertThresholdHitRate * 100).toStringAsFixed(1)}%)',
        timestamp: now,
        isActive: true,
      ));
    }
    
    // Response time alert
    if (metrics.averageAccessTime.inMilliseconds > _config.alertThresholdResponseTime) {
      alerts.add(CacheAlert(
        id: 'response_time_high',
        type: AlertType.performance,
        severity: AlertSeverity.warning,
        title: 'High Response Time',
        message: 'Average cache access time (${metrics.averageAccessTime.inMilliseconds}ms) '
                'exceeds threshold (${_config.alertThresholdResponseTime}ms)',
        timestamp: now,
        isActive: true,
      ));
    }
    
    // Memory usage alert
    if (stats.memoryUsage > 900) {
      alerts.add(CacheAlert(
        id: 'memory_usage_critical',
        type: AlertType.resource,
        severity: AlertSeverity.critical,
        title: 'Critical Memory Usage',
        message: 'Cache memory usage (${stats.memoryUsage}) is critically high',
        timestamp: now,
        isActive: true,
      ));
    }
    
    return alerts;
  }

  /// Update time series data for trend analysis
  void _updateTimeSeries(CachePerformanceReport report) {
    // Store key metrics in time series format
    _addToTimeSeries('hit_rate', report.harvestCacheStats.hitRate);
    _addToTimeSeries('response_time', 
        report.performanceMetrics.averageAccessTime.inMilliseconds.toDouble());
    _addToTimeSeries('memory_usage', report.harvestCacheStats.memoryUsage.toDouble());
    _addToTimeSeries('cache_size', report.harvestCacheStats.totalEntries.toDouble());
  }

  /// Add value to time series
  void _addToTimeSeries(String metric, double value) {
    final series = _performanceTimeSeries[metric] ??= [];
    series.add(value);
    
    // Keep only recent data
    final maxPoints = 24 * 7; // 7 days of hourly data
    if (series.length > maxPoints) {
      series.removeAt(0);
    }
  }

  /// Get time series data for a metric
  List<double> getTimeSeries(String metric) {
    return List.from(_performanceTimeSeries[metric] ?? []);
  }

  /// Record cache event for analytics
  void recordCacheEvent(CacheEvent event) {
    _recentEvents.add(event);
    
    // Keep only recent events
    final maxEvents = 1000;
    if (_recentEvents.length > maxEvents) {
      _recentEvents.removeAt(0);
    }
    
    // Update operation counters
    _operationCounts[event.operation] = 
        (_operationCounts[event.operation] ?? 0) + 1;
    
    // Update timing if available
    if (event.duration != null) {
      final currentAvg = _operationTimes[event.operation] ?? 0.0;
      final count = _operationCounts[event.operation]!;
      _operationTimes[event.operation] = 
          (currentAvg * (count - 1) + event.duration!.inMilliseconds) / count;
    }
  }

  /// Get historical reports
  List<CachePerformanceReport> getHistoricalReports({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) {
    var reports = _historicalReports.where((report) {
      if (startTime != null && report.timestamp.isBefore(startTime)) {
        return false;
      }
      if (endTime != null && report.timestamp.isAfter(endTime)) {
        return false;
      }
      return true;
    }).toList();
    
    if (limit != null && reports.length > limit) {
      reports = reports.takeLast(limit).toList();
    }
    
    return reports;
  }

  /// Get active alerts
  List<CacheAlert> getActiveAlerts() {
    return _activeAlerts.where((alert) => alert.isActive).toList();
  }

  /// Generate predictive analytics report
  Future<CachePredictiveReport> generatePredictiveReport() async {
    if (!_config.enablePredictiveAnalytics) {
      throw StateError('Predictive analytics is disabled');
    }
    
    final predictions = <CachePrediction>[];
    
    // Predict hit rate trend
    final hitRates = getTimeSeries('hit_rate');
    if (hitRates.length >= 24) {
      final prediction = _predictValue(hitRates);
      predictions.add(CachePrediction(
        metric: 'hit_rate',
        predictedValue: prediction,
        confidence: _calculatePredictionConfidence(hitRates),
        timeHorizon: const Duration(hours: 24),
      ));
    }
    
    // Predict memory usage
    final memoryUsage = getTimeSeries('memory_usage');
    if (memoryUsage.length >= 24) {
      final prediction = _predictValue(memoryUsage);
      predictions.add(CachePrediction(
        metric: 'memory_usage',
        predictedValue: prediction,
        confidence: _calculatePredictionConfidence(memoryUsage),
        timeHorizon: const Duration(hours: 24),
      ));
    }
    
    return CachePredictiveReport(
      generatedAt: DateTime.now(),
      predictions: predictions,
      recommendations: _generatePredictiveRecommendations(predictions),
    );
  }

  /// Simple linear prediction
  double _predictValue(List<double> values) {
    if (values.length < 2) return values.isNotEmpty ? values.last : 0.0;
    
    // Simple linear regression
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;
    
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    
    // Predict next value
    return slope * n + intercept;
  }

  /// Calculate prediction confidence
  double _calculatePredictionConfidence(List<double> values) {
    if (values.length < 3) return 0.5; // Low confidence for small samples
    
    // Calculate variance to determine confidence
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) / values.length;
    
    // Lower variance = higher confidence
    final cv = sqrt(variance) / mean;
    return (1.0 - cv).clamp(0.0, 1.0);
  }

  /// Generate predictive recommendations
  List<String> _generatePredictiveRecommendations(List<CachePrediction> predictions) {
    final recommendations = <String>[];
    
    for (final prediction in predictions) {
      switch (prediction.metric) {
        case 'hit_rate':
          if (prediction.predictedValue < 0.6) {
            recommendations.add(
              'Hit rate is predicted to drop to ${(prediction.predictedValue * 100).toStringAsFixed(1)}%. '
              'Consider implementing preemptive cache warming.'
            );
          }
          break;
        case 'memory_usage':
          if (prediction.predictedValue > 900) {
            recommendations.add(
              'Memory usage is predicted to reach ${prediction.predictedValue.toStringAsFixed(0)} units. '
              'Plan for cache eviction or capacity expansion.'
            );
          }
          break;
      }
    }
    
    return recommendations;
  }

  /// Dispose resources
  void dispose() {
    _reportingTimer?.cancel();
    _historicalReports.clear();
    _activeAlerts.clear();
    _performanceTimeSeries.clear();
    _recentEvents.clear();
  }
}

// Supporting classes for analytics

class CachePerformanceReport {
  final DateTime timestamp;
  final CacheStatistics harvestCacheStats;
  final WeatherApiCacheStats weatherApiStats;
  final CacheWarmingStatistics? warmingStats;
  final CachePerformanceMetrics performanceMetrics;
  final CacheTrendAnalysis trends;
  final List<CacheInsight> insights;
  final List<CacheAlert> alerts;

  CachePerformanceReport({
    required this.timestamp,
    required this.harvestCacheStats,
    required this.weatherApiStats,
    this.warmingStats,
    required this.performanceMetrics,
    required this.trends,
    required this.insights,
    required this.alerts,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'harvestCacheStats': harvestCacheStats.toJson(),
      'weatherApiStats': weatherApiStats.toJson(),
      'warmingStats': warmingStats?.toJson(),
      'performanceMetrics': performanceMetrics.toJson(),
      'trends': trends.toJson(),
      'insights': insights.map((i) => i.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
    };
  }
}

class CacheTrendAnalysis {
  final TrendDirection hitRateTrend;
  final TrendDirection responseTimeTrend;
  final TrendDirection cacheSizeTrend;
  final TrendDirection errorRateTrend;
  final double trendStrength;

  CacheTrendAnalysis({
    required this.hitRateTrend,
    required this.responseTimeTrend,
    required this.cacheSizeTrend,
    required this.errorRateTrend,
    required this.trendStrength,
  });

  Map<String, dynamic> toJson() {
    return {
      'hitRateTrend': hitRateTrend.name,
      'responseTimeTrend': responseTimeTrend.name,
      'cacheSizeTrend': cacheSizeTrend.name,
      'errorRateTrend': errorRateTrend.name,
      'trendStrength': trendStrength,
    };
  }
}

enum TrendDirection { increasing, decreasing, stable }

class CacheInsight {
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String description;
  final String recommendation;
  final InsightImpact impact;

  CacheInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.impact,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'description': description,
      'recommendation': recommendation,
      'impact': impact.name,
    };
  }
}

enum InsightType { performance, resource, cost, usage }
enum InsightSeverity { low, medium, high, critical }
enum InsightImpact { low, medium, high }

class CacheAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isActive;

  CacheAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
    };
  }
}

enum AlertType { performance, resource, error, security }
enum AlertSeverity { info, warning, critical }

class CacheEvent {
  final String operation;
  final DateTime timestamp;
  final Duration? duration;
  final bool success;
  final String? error;

  CacheEvent({
    required this.operation,
    required this.timestamp,
    this.duration,
    required this.success,
    this.error,
  });
}

class CachePredictiveReport {
  final DateTime generatedAt;
  final List<CachePrediction> predictions;
  final List<String> recommendations;

  CachePredictiveReport({
    required this.generatedAt,
    required this.predictions,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'recommendations': recommendations,
    };
  }
}

class CachePrediction {
  final String metric;
  final double predictedValue;
  final double confidence;
  final Duration timeHorizon;

  CachePrediction({
    required this.metric,
    required this.predictedValue,
    required this.confidence,
    required this.timeHorizon,
  });

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'predictedValue': predictedValue,
      'confidence': confidence,
      'timeHorizonHours': timeHorizon.inHours,
    };
  }
}