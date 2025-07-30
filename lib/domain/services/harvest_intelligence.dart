/**
 * Harvest Intelligence Service for FieldFirst
 * Integrates combine capabilities with weather conditions for optimal harvest timing
 * Implements cost-optimized weather API calls with intelligent caching
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../models/combine_models.dart';
import '../models/harvest_models.dart';
import '../models/cache_models.dart';
import '../repositories/combine_repository.dart';
import '../repositories/base_repositories.dart';
import 'harvest_cache_service.dart';
import 'crop_threshold_service.dart';

/// Configuration for harvest intelligence
class HarvestIntelligenceConfig {
  final Duration weatherCacheDuration;
  final Duration capabilityCacheDuration;
  final double locationClusterRadius; // km
  final int maxForecastDays;
  final int maxHarvestWindows;
  final Map<WeatherProvider, double> apiCosts;

  const HarvestIntelligenceConfig({
    this.weatherCacheDuration = const Duration(minutes: 15),
    this.capabilityCacheDuration = const Duration(hours: 24),
    this.locationClusterRadius = 2.0,
    this.maxForecastDays = 7,
    this.maxHarvestWindows = 10,
    this.apiCosts = const {
      WeatherProvider.tomorrowIo: 0.05, // $0.05 per call
      WeatherProvider.msc: 0.0, // Free
    },
  });
}

/// Enhanced harvest intelligence service with advanced caching
class HarvestIntelligenceService {
  final WeatherApiService _weatherService;
  final CombineRepository _combineRepository;
  final UserCombineRepository _userCombineRepository;
  final HarvestCacheService _cacheService;
  final HarvestIntelligenceConfig _config;
  
  // Cost tracking
  final List<ApiCallCost> _apiCosts = [];
  double _totalCost = 0.0;

  HarvestIntelligenceService({
    required WeatherApiService weatherService,
    required CombineRepository combineRepository,
    required UserCombineRepository userCombineRepository,
    required HarvestCacheService cacheService,
    HarvestIntelligenceConfig? config,
  }) : _weatherService = weatherService,
       _combineRepository = combineRepository,
       _userCombineRepository = userCombineRepository,
       _cacheService = cacheService,
       _config = config ?? const HarvestIntelligenceConfig();

  /// Get harvest recommendations for a user's combines and fields
  Future<HarvestIntelligenceResult> getHarvestRecommendations({
    required String userId,
    required List<FieldLocation> fields,
    required CropType crop,
    int? forecastDays,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Get user's active combines
      final userCombines = await _userCombineRepository.getActiveCombines(userId);
      if (userCombines.isEmpty) {
        throw HarvestIntelligenceException(
          'No active combines found for user',
          userId: userId,
        );
      }

      // Pre-warm cache for user if enabled
      await _cacheService.preloadCacheForUser(userId);

      // Get combine capabilities for all user combines
      final combineCapabilities = <CombineCapability>[];
      for (final userCombine in userCombines) {
        final capability = await _getCombineCapability(userCombine.combineSpecId);
        combineCapabilities.add(capability);
      }

      // Check if harvest windows are already cached
      final cachedWindows = await _cacheService.getHarvestWindows(userId, fields, crop);
      if (cachedWindows != null) {
        stopwatch.stop();
        
        return HarvestIntelligenceResult(
          userId: userId,
          harvestWindows: cachedWindows,
          combineCapabilities: combineCapabilities,
          weatherForecasts: [], // Empty since using cache
          locationClusters: _clusterLocations(fields),
          processingTimeMs: stopwatch.elapsedMilliseconds,
          apiCosts: List.from(_apiCosts),
          totalCost: _totalCost,
          cacheHitRate: 1.0, // 100% cache hit
        );
      }

      // Cluster nearby fields to minimize API calls
      final locationClusters = _clusterLocations(fields);
      
      // Get weather forecasts for clustered locations
      final weatherForecasts = <String, WeatherForecast>{};
      for (final cluster in locationClusters) {
        final forecast = await _getWeatherForecast(
          cluster.representativeLocation,
          forecastDays ?? _config.maxForecastDays,
        );
        weatherForecasts[cluster.id] = forecast;
      }

      // Generate harvest windows for each combine-field combination
      final allWindows = <HarvestWindow>[];
      for (final capability in combineCapabilities) {
        for (final cluster in locationClusters) {
          final forecast = weatherForecasts[cluster.id]!;
          final windows = await _generateHarvestWindows(
            capability: capability,
            forecast: forecast,
            crop: crop,
            fields: cluster.fields,
          );
          allWindows.addAll(windows);
        }
      }

      // Sort and filter best windows
      final bestWindows = _selectBestHarvestWindows(allWindows);

      // Cache the harvest windows result
      await _cacheService.cacheHarvestWindows(userId, fields, crop, bestWindows);

      stopwatch.stop();

      return HarvestIntelligenceResult(
        userId: userId,
        harvestWindows: bestWindows,
        combineCapabilities: combineCapabilities,
        weatherForecasts: weatherForecasts.values.toList(),
        locationClusters: locationClusters,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        apiCosts: List.from(_apiCosts),
        totalCost: _totalCost,
        cacheHitRate: _calculateCacheHitRate(),
      );

    } catch (e) {
      throw HarvestIntelligenceException(
        'Failed to generate harvest recommendations: ${e.toString()}',
        userId: userId,
      );
    }
  }

  /// Get combine capability assessment with advanced caching and equipment factors
  Future<CombineCapability> _getCombineCapability(String combineSpecId) async {
    // Check cache service first
    final cached = await _cacheService.getCombineCapability(combineSpecId);
    if (cached != null) {
      return cached;
    }

    // Calculate new capability
    final combineSpec = await _combineRepository.getById(combineSpecId);
    if (combineSpec == null) {
      throw HarvestIntelligenceException(
        'Combine specification not found',
        combineSpecId: combineSpecId,
      );
    }

    final capability = CombineCapability.fromCombineSpec(combineSpec);
    
    // Cache the result using the cache service
    await _cacheService.cacheCombineCapability(combineSpecId, capability);

    return capability;
  }

  /// Get equipment factor analysis for a combine
  Future<EquipmentFactorAnalysis> getEquipmentFactorAnalysis({
    required String combineSpecId,
    required CropType crop,
    String? weatherLocationId,
    Map<EquipmentFactorType, double>? customWeights,
  }) async {
    try {
      // Get combine spec
      final spec = await _combineRepository.getById(combineSpecId);
      if (spec == null) {
        throw HarvestIntelligenceException(
          'Combine specification not found',
          combineSpecId: combineSpecId,
        );
      }

      // Get current weather data if location provided
      WeatherData? weatherData;
      if (weatherLocationId != null) {
        try {
          final location = FieldLocation(
            id: weatherLocationId,
            name: 'Equipment Analysis Location',
            latitude: 0.0, // Would be provided by actual location service
            longitude: 0.0,
          );
          final forecast = await _getWeatherForecast(location, 1);
          if (forecast.dailyForecasts.isNotEmpty) {
            weatherData = forecast.dailyForecasts.first;
          }
        } catch (e) {
          // Continue without weather data
        }
      }

      // Perform equipment factor analysis
      final analysis = EquipmentFactorAnalysis.analyze(
        spec: spec,
        weather: weatherData,
        crop: crop,
        weatherLocationId: weatherLocationId,
        customWeights: customWeights,
      );

      return analysis;

    } catch (e) {
      throw HarvestIntelligenceException(
        'Failed to analyze equipment factors: ${e.toString()}',
        combineSpecId: combineSpecId,
      );
    }
  }

  /// Get enhanced combine insights with equipment factors
  Future<Map<String, dynamic>> getCombineInsights({
    required String brand,
    required String model,
    String? region,
    CropType? crop,
    String? weatherLocationId,
  }) async {
    try {
      // Get base insights (existing functionality)
      final baseInsights = <String, dynamic>{
        'userCount': 0,
        'brandMetrics': <String, double>{},
        'commonIssues': <String>[],
        'brandRecommendations': <String>[],
        'modelData': <String, dynamic>{},
        'peerComparison': null,
        'expertRecommendations': <String>[],
        'confidence': 0.5,
      };

      // Find combine specs for this brand/model
      final specs = await _combineRepository.getByModel(brand, model);
      if (specs.isEmpty) {
        return baseInsights;
      }

      final spec = specs.first;
      
      // Add equipment factor insights if crop is specified
      if (crop != null) {
        final equipmentAnalysis = await getEquipmentFactorAnalysis(
          combineSpecId: spec.id,
          crop: crop,
          weatherLocationId: weatherLocationId,
        );

        // Enhance insights with equipment factor data
        baseInsights['equipmentFactors'] = {
          'overallMultiplier': equipmentAnalysis.overallPerformanceMultiplier,
          'factors': equipmentAnalysis.factors.map((f) => f.toJson()).toList(),
          'advantages': equipmentAnalysis.performanceAdvantages
              .map((f) => {
                    'type': f.type.name,
                    'multiplier': f.performanceMultiplier,
                    'reason': f.reason.name,
                  })
              .toList(),
          'limitations': equipmentAnalysis.performanceLimitations
              .map((f) => {
                    'type': f.type.name,
                    'multiplier': f.performanceMultiplier,
                    'reason': f.reason.name,
                  })
              .toList(),
        };

        // Update confidence based on equipment factor analysis
        final avgConfidence = equipmentAnalysis.factors
            .map((f) => f.confidence)
            .reduce((a, b) => a + b) / equipmentAnalysis.factors.length;
        baseInsights['confidence'] = (baseInsights['confidence'] as double + avgConfidence) / 2;

        // Add equipment-based recommendations
        final recommendations = _generateEquipmentRecommendations(equipmentAnalysis);
        baseInsights['equipmentRecommendations'] = recommendations;
      }

      return baseInsights;

    } catch (e) {
      throw HarvestIntelligenceException(
        'Failed to get combine insights: ${e.toString()}',
      );
    }
  }

  /// Generate equipment-based recommendations
  List<String> _generateEquipmentRecommendations(EquipmentFactorAnalysis analysis) {
    final recommendations = <String>[];

    // Check for performance advantages
    for (final advantage in analysis.performanceAdvantages) {
      switch (advantage.type) {
        case EquipmentFactorType.moistureHandling:
          recommendations.add(
            'This combine excels in high moisture conditions - consider harvesting earlier than typical'
          );
          break;
        case EquipmentFactorType.speedEfficiency:
          recommendations.add(
            'High speed efficiency detected - optimize field patterns for maximum throughput'
          );
          break;
        case EquipmentFactorType.weatherAdaptability:
          recommendations.add(
            'Excellent weather adaptability - suitable for marginal harvest conditions'
          );
          break;
        default:
          break;
      }
    }

    // Check for performance limitations
    for (final limitation in analysis.performanceLimitations) {
      switch (limitation.type) {
        case EquipmentFactorType.moistureHandling:
          recommendations.add(
            'Monitor crop moisture closely - this combine performs best in drier conditions'
          );
          break;
        case EquipmentFactorType.fuelConsumption:
          recommendations.add(
            'Higher fuel consumption expected - plan fuel logistics accordingly'
          );
          break;
        case EquipmentFactorType.maintenanceComplexity:
          recommendations.add(
            'Complex maintenance requirements - ensure technician availability during harvest'
          );
          break;
        default:
          break;
      }
    }

    // Overall performance recommendations
    if (analysis.overallPerformanceMultiplier > 1.1) {
      recommendations.add(
        'Current conditions favor this combine - excellent harvest window opportunity'
      );
    } else if (analysis.overallPerformanceMultiplier < 0.9) {
      recommendations.add(
        'Current conditions are challenging for this combine - consider waiting for better conditions'
      );
    }

    return recommendations;
  }

  /// Get weather forecast with intelligent caching and clustering
  Future<WeatherForecast> _getWeatherForecast(
    FieldLocation location,
    int days,
  ) async {
    // Use weather service with integrated caching
    final forecast = await _weatherService.getForecast(location, days);
    
    // Track API cost (weather service handles caching internally)
    _trackApiCost(
      provider: forecast.provider,
      endpoint: 'forecast',
      callCount: 1,
      locationId: location.id,
      fromCache: false, // Weather service will handle cache tracking
    );

    return forecast;
  }

  /// Cluster nearby field locations to minimize API calls
  List<LocationCluster> _clusterLocations(List<FieldLocation> fields) {
    final clusters = <LocationCluster>[];
    final processed = <bool>[];
    
    for (int i = 0; i < fields.length; i++) {
      processed.add(false);
    }

    for (int i = 0; i < fields.length; i++) {
      if (processed[i]) continue;

      final cluster = LocationCluster(
        id: 'cluster_$i',
        representativeLocation: fields[i],
        fields: [fields[i]],
      );

      processed[i] = true;

      // Find nearby fields within cluster radius
      for (int j = i + 1; j < fields.length; j++) {
        if (processed[j]) continue;

        final distance = _calculateDistance(fields[i], fields[j]);
        if (distance <= _config.locationClusterRadius) {
          cluster.fields.add(fields[j]);
          processed[j] = true;
        }
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  /// Calculate distance between two locations in kilometers
  double _calculateDistance(FieldLocation loc1, FieldLocation loc2) {
    const earthRadius = 6371.0; // km
    final lat1Rad = loc1.latitude * pi / 180;
    final lat2Rad = loc2.latitude * pi / 180;
    final deltaLatRad = (loc2.latitude - loc1.latitude) * pi / 180;
    final deltaLonRad = (loc2.longitude - loc1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Generate harvest windows for a combine-weather combination
  Future<List<HarvestWindow>> _generateHarvestWindows({
    required CombineCapability capability,
    required WeatherForecast forecast,
    required CropType crop,
    required List<FieldLocation> fields,
  }) async {
    final windows = <HarvestWindow>[];

    for (final weatherData in forecast.dailyForecasts) {
      // Generate windows for different times of day
      final dayWindows = _generateDayWindows(weatherData);
      
      for (final window in dayWindows) {
        final harvestWindow = HarvestWindow.create(
          startTime: window.start,
          endTime: window.end,
          weather: weatherData,
          combineCapability: capability,
          crop: crop,
        );

        // Only include windows that aren't "avoid"
        if (harvestWindow.recommendation != HarvestRecommendation.avoid) {
          windows.add(harvestWindow);
        }
      }
    }

    return windows;
  }

  /// Generate time windows within a day for harvest operations
  List<TimeWindow> _generateDayWindows(WeatherData weather) {
    final date = weather.timestamp;
    final windows = <TimeWindow>[];

    // Early morning window (6 AM - 10 AM)
    windows.add(TimeWindow(
      start: DateTime(date.year, date.month, date.day, 6),
      end: DateTime(date.year, date.month, date.day, 10),
    ));

    // Mid-day window (10 AM - 2 PM)
    windows.add(TimeWindow(
      start: DateTime(date.year, date.month, date.day, 10),
      end: DateTime(date.year, date.month, date.day, 14),
    ));

    // Afternoon window (2 PM - 6 PM)
    windows.add(TimeWindow(
      start: DateTime(date.year, date.month, date.day, 14),
      end: DateTime(date.year, date.month, date.day, 18),
    ));

    // Evening window (6 PM - 8 PM) - limited
    windows.add(TimeWindow(
      start: DateTime(date.year, date.month, date.day, 18),
      end: DateTime(date.year, date.month, date.day, 20),
    ));

    return windows;
  }

  /// Select the best harvest windows based on multiple criteria
  List<HarvestWindow> _selectBestHarvestWindows(List<HarvestWindow> allWindows) {
    // Sort by priority (descending) and confidence (descending)
    allWindows.sort((a, b) {
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) return priorityComparison;
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    // Filter to avoid overlapping windows and limit count
    final selectedWindows = <HarvestWindow>[];
    
    for (final window in allWindows) {
      if (selectedWindows.length >= _config.maxHarvestWindows) break;
      
      // Check for overlap with already selected windows
      final hasOverlap = selectedWindows.any((selected) => 
        _windowsOverlap(window, selected));
      
      if (!hasOverlap) {
        selectedWindows.add(window);
      }
    }

    return selectedWindows;
  }

  /// Check if two harvest windows overlap
  bool _windowsOverlap(HarvestWindow a, HarvestWindow b) {
    return a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime);
  }

  /// Track API call costs
  void _trackApiCost({
    required WeatherProvider provider,
    required String endpoint,
    required int callCount,
    required String locationId,
    required bool fromCache,
  }) {
    final cost = _config.apiCosts[provider] ?? 0.0;
    final totalCost = cost * callCount;
    
    _totalCost += totalCost;
    
    _apiCosts.add(ApiCallCost(
      provider: provider,
      timestamp: DateTime.now(),
      endpoint: endpoint,
      callCount: callCount,
      estimatedCost: totalCost,
      locationId: locationId,
      fromCache: fromCache,
    ));
  }

  /// Calculate cache hit rate for performance monitoring
  double _calculateCacheHitRate() {
    if (_apiCosts.isEmpty) return 0.0;
    
    final cacheHits = _apiCosts.where((cost) => cost.fromCache).length;
    return cacheHits / _apiCosts.length;
  }

  /// Get comprehensive cache statistics with crop-specific insights
  Future<HarvestCacheAnalytics> getCacheAnalytics() async {
    final cacheStats = _cacheService.getStatistics();
    final weatherApiStats = (_weatherService as WeatherApiServiceImpl).getCacheStatistics();
    
    return HarvestCacheAnalytics(
      harvestCacheStats: cacheStats,
      weatherApiStats: weatherApiStats,
      totalApiCost: _totalCost,
      totalApiCalls: _apiCosts.length,
      cacheEfficiency: _calculateCacheEfficiency(),
    );
  }

  /// Get crop-specific harvest timing recommendations
  Future<Map<String, dynamic>> getCropSpecificRecommendations({
    required CropType crop,
    required List<FieldLocation> locations,
    int forecastDays = 7,
  }) async {
    final recommendations = <String, dynamic>{
      'crop': crop.name,
      'analysisDate': DateTime.now().toIso8601String(),
      'locations': locations.length,
      'forecastDays': forecastDays,
    };

    try {
      final cropThresholds = CropThresholdService.getThresholds(crop);
      if (cropThresholds == null) {
        recommendations['error'] = 'No thresholds available for crop: ${crop.name}';
        return recommendations;
      }

      // Analyze weather for each location
      final locationAnalyses = <Map<String, dynamic>>[];
      var totalRiskScore = 0.0;
      var optimalWindows = 0;
      var criticalRisks = 0;

      for (final location in locations) {
        try {
          final forecast = await _getWeatherForecast(location, forecastDays);
          final locationAnalysis = <String, dynamic>{
            'locationId': location.id,
            'locationName': location.name,
            'dailyAnalyses': <Map<String, dynamic>>[],
          };

          var locationRisk = 0.0;
          var locationOptimal = 0;

          for (final weather in forecast.dailyForecasts) {
            final thresholdAnalysis = CropThresholdService.analyzeWeatherThresholds(
              crop: crop,
              weather: weather,
              forecast: forecast.dailyForecasts,
            );

            locationRisk += thresholdAnalysis.overallRiskScore;
            
            if (thresholdAnalysis.violations.isEmpty && 
                thresholdAnalysis.opportunities.length > 1) {
              locationOptimal++;
              optimalWindows++;
            }

            if (thresholdAnalysis.violations.any((v) => v.severity == 'critical')) {
              criticalRisks++;
            }

            locationAnalysis['dailyAnalyses'].add({
              'date': weather.timestamp.toIso8601String(),
              'riskScore': thresholdAnalysis.overallRiskScore,
              'violations': thresholdAnalysis.violations.length,
              'opportunities': thresholdAnalysis.opportunities.length,
              'harvestReadiness': CropThresholdService.calculateHarvestReadiness(
                crop: crop,
                weather: weather,
              ),
              'recommendations': CropThresholdService.generateCropRecommendations(
                crop: crop,
                analysis: thresholdAnalysis,
              ),
            });
          }

          locationAnalysis['averageRiskScore'] = locationRisk / forecast.dailyForecasts.length;
          locationAnalysis['optimalDays'] = locationOptimal;
          totalRiskScore += locationRisk;
          locationAnalyses.add(locationAnalysis);

        } catch (e) {
          locationAnalyses.add({
            'locationId': location.id,
            'locationName': location.name,
            'error': 'Failed to analyze location: ${e.toString()}',
          });
        }
      }

      recommendations['locationAnalyses'] = locationAnalyses;
      recommendations['summary'] = {
        'averageRiskScore': totalRiskScore / (locations.length * forecastDays),
        'totalOptimalWindows': optimalWindows,
        'totalCriticalRisks': criticalRisks,
        'recommendation': _generateOverallRecommendation(
          totalRiskScore / (locations.length * forecastDays),
          optimalWindows,
          criticalRisks,
        ),
      };

      // Add crop-specific guidance
      recommendations['cropGuidance'] = _generateCropGuidance(crop);

    } catch (e) {
      recommendations['error'] = 'Analysis failed: ${e.toString()}';
    }

    return recommendations;
  }

  String _generateOverallRecommendation(
    double avgRiskScore,
    int optimalWindows,
    int criticalRisks,
  ) {
    if (criticalRisks > 0) {
      return 'AVOID: Critical weather conditions present';
    } else if (avgRiskScore < 0.3 && optimalWindows > 2) {
      return 'OPTIMAL: Excellent harvest conditions forecast';
    } else if (avgRiskScore < 0.5) {
      return 'ACCEPTABLE: Good conditions with minor considerations';
    } else if (avgRiskScore < 0.7) {
      return 'MARGINAL: Monitor conditions closely';
    } else {
      return 'CAUTION: Poor conditions, consider delaying';
    }
  }

  Map<String, dynamic> _generateCropGuidance(CropType crop) {
    final cropThresholds = CropThresholdService.getThresholds(crop);
    if (cropThresholds == null) return {};

    return {
      'moistureGuidance': {
        'optimal': '${cropThresholds.moisture.minOptimal}-${cropThresholds.moisture.maxOptimal}%',
        'storage': 'Dry to ${cropThresholds.moisture.storageMax}% for safe storage',
      },
      'weatherConsiderations': {
        'frost': cropThresholds.weather.frost != null 
            ? 'Avoid harvest below ${cropThresholds.weather.frost!.threshold}°C'
            : null,
        'wind': cropThresholds.weather.wind != null
            ? 'Reduce speed above ${cropThresholds.weather.wind!.operationalLimit} km/h'
            : null,
        'rain': cropThresholds.weather.rain != null
            ? 'Cease operations above ${cropThresholds.weather.rain!.heavyRain}mm'
            : null,
      },
      'qualityFactors': cropThresholds.quality.impacts,
      'economicConsiderations': _getEconomicConsiderations(crop),
    };
  }

  Map<String, String> _getEconomicConsiderations(CropType crop) {
    switch (crop) {
      case CropType.canola:
        return {
          'greenSeedPenalty': 'Grade penalty: -\$50-100/tonne for >2% green seed',
          'shatteringLoss': 'Shattering losses: 100-150 kg/ha (\$75-110/ha value)',
        };
      case CropType.wheat:
        return {
          'moisturePenalty': 'Grade loss from excess moisture: -\$15-30/tonne',
          'dryingCosts': 'Commercial drying: \$2.50/tonne per percentage point',
          'qualityLoss': 'Sprouting damage: -\$20-50/tonne for falling number issues',
        };
      case CropType.barley:
        return {
          'maltingPremium': 'Malting premium loss: -\$40-60/tonne',
          'feedDowngrade': 'Feed grade penalty: -\$30-40/tonne',
        };
      default:
        return {
          'general': 'Monitor grade standards to maximize revenue',
        };
    }
  }

  /// Calculate overall cache efficiency
  double _calculateCacheEfficiency() {
    final cacheStats = _cacheService.getStatistics();
    if (cacheStats.totalRequests == 0) return 0.0;
    
    // Combine hit rate with cost savings
    final hitRate = cacheStats.hitRate;
    final costSavings = _apiCosts.where((cost) => cost.fromCache).length / 
                       max(_apiCosts.length, 1);
    
    return (hitRate + costSavings) / 2.0;
  }

  /// Warm cache for multiple users
  Future<void> warmCacheForUsers(List<String> userIds) async {
    for (final userId in userIds) {
      try {
        await _cacheService.preloadCacheForUser(userId);
        // Small delay to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('Cache warming failed for user $userId: $e');
      }
    }
  }

  /// Perform cache maintenance
  Future<void> performCacheMaintenance() async {
    await _cacheService.performSmartEviction();
  }

  /// Get cost summary for reporting
  CostSummary getCostSummary() {
    final costsByProvider = <WeatherProvider, double>{};
    var totalCalls = 0;
    var cacheCalls = 0;

    for (final cost in _apiCosts) {
      costsByProvider[cost.provider] = 
          (costsByProvider[cost.provider] ?? 0.0) + cost.estimatedCost;
      totalCalls += cost.callCount;
      if (cost.fromCache) cacheCalls += cost.callCount;
    }

    return CostSummary(
      totalCost: _totalCost,
      costsByProvider: costsByProvider,
      totalCalls: totalCalls,
      cachedCalls: cacheCalls,
      cacheHitRate: totalCalls > 0 ? cacheCalls / totalCalls : 0.0,
    );
  }

  /// Clear caches to free memory
  void clearCaches() {
    _cacheService.clearAllCaches();
  }

  /// Get crop threshold information for UI display
  Map<String, dynamic> getCropThresholdInfo(CropType crop) {
    final thresholds = CropThresholdService.getThresholds(crop);
    if (thresholds == null) {
      return {'error': 'No threshold data available for ${crop.name}'};
    }

    return {
      'crop': crop.name,
      'moisture': {
        'optimal': {
          'min': thresholds.moisture.minOptimal,
          'max': thresholds.moisture.maxOptimal,
          'unit': thresholds.moisture.unit,
        },
        'storage': {
          'max': thresholds.moisture.storageMax,
          'unit': thresholds.moisture.unit,
        },
      },
      'weather': {
        'frost': thresholds.weather.frost != null ? {
          'threshold': thresholds.weather.frost!.threshold,
          'unit': thresholds.weather.frost!.unit,
          'description': thresholds.weather.frost!.description,
          'impact': thresholds.weather.frost!.impact,
        } : null,
        'heatStress': thresholds.weather.heatStress != null ? {
          'threshold': thresholds.weather.heatStress!.threshold,
          'unit': thresholds.weather.heatStress!.unit,
          'description': thresholds.weather.heatStress!.description,
          'impact': thresholds.weather.heatStress!.impact,
        } : null,
        'wind': thresholds.weather.wind != null ? {
          'shatterThreshold': thresholds.weather.wind!.shatterThreshold,
          'operationalLimit': thresholds.weather.wind!.operationalLimit,
          'unit': thresholds.weather.wind!.unit,
        } : null,
        'rain': thresholds.weather.rain != null ? {
          'lightRain': thresholds.weather.rain!.lightRain,
          'heavyRain': thresholds.weather.rain!.heavyRain,
          'criticalAmount': thresholds.weather.rain!.criticalAmount,
          'unit': thresholds.weather.rain!.unit,
        } : null,
      },
      'quality': {
        'factors': thresholds.quality.factors.map(
          (key, value) => MapEntry(key, {
            'min': value.min,
            'max': value.max,
            'optimal': value.optimal,
            'unit': value.unit,
          }),
        ),
        'impacts': thresholds.quality.impacts,
      },
      'specificFactors': thresholds.specificFactors,
    };
  }

  /// Dispose resources
  void dispose() {
    clearCaches();
    _apiCosts.clear();
  }
}

/// Weather API service interface
abstract class WeatherApiService {
  Future<WeatherForecast> getForecast(FieldLocation location, int days);
  Future<WeatherData> getCurrentWeather(FieldLocation location);
}

/// Supporting classes

class FieldLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? userId;

  FieldLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
    };
  }

  factory FieldLocation.fromJson(Map<String, dynamic> json) {
    return FieldLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      userId: json['userId'] as String?,
    );
  }
}

class LocationCluster {
  final String id;
  final FieldLocation representativeLocation;
  final List<FieldLocation> fields;

  LocationCluster({
    required this.id,
    required this.representativeLocation,
    required this.fields,
  });
}

class TimeWindow {
  final DateTime start;
  final DateTime end;

  TimeWindow({
    required this.start,
    required this.end,
  });
}

class HarvestIntelligenceResult {
  final String userId;
  final List<HarvestWindow> harvestWindows;
  final List<CombineCapability> combineCapabilities;
  final List<WeatherForecast> weatherForecasts;
  final List<LocationCluster> locationClusters;
  final int processingTimeMs;
  final List<ApiCallCost> apiCosts;
  final double totalCost;
  final double cacheHitRate;

  HarvestIntelligenceResult({
    required this.userId,
    required this.harvestWindows,
    required this.combineCapabilities,
    required this.weatherForecasts,
    required this.locationClusters,
    required this.processingTimeMs,
    required this.apiCosts,
    required this.totalCost,
    required this.cacheHitRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'harvestWindows': harvestWindows.map((w) => w.toJson()).toList(),
      'combineCapabilities': combineCapabilities.map((c) => c.toJson()).toList(),
      'weatherForecasts': weatherForecasts.map((f) => f.toJson()).toList(),
      'processingTimeMs': processingTimeMs,
      'apiCosts': apiCosts.map((c) => c.toJson()).toList(),
      'totalCost': totalCost,
      'cacheHitRate': cacheHitRate,
    };
  }
}

class CostSummary {
  final double totalCost;
  final Map<WeatherProvider, double> costsByProvider;
  final int totalCalls;
  final int cachedCalls;
  final double cacheHitRate;

  CostSummary({
    required this.totalCost,
    required this.costsByProvider,
    required this.totalCalls,
    required this.cachedCalls,
    required this.cacheHitRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalCost': totalCost,
      'costsByProvider': costsByProvider.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'totalCalls': totalCalls,
      'cachedCalls': cachedCalls,
      'cacheHitRate': cacheHitRate,
    };
  }
}

class HarvestCacheAnalytics {
  final CacheStatistics harvestCacheStats;
  final WeatherApiCacheStats weatherApiStats;
  final double totalApiCost;
  final int totalApiCalls;
  final double cacheEfficiency;

  HarvestCacheAnalytics({
    required this.harvestCacheStats,
    required this.weatherApiStats,
    required this.totalApiCost,
    required this.totalApiCalls,
    required this.cacheEfficiency,
  });

  Map<String, dynamic> toJson() {
    return {
      'harvestCacheStats': harvestCacheStats.toJson(),
      'weatherApiStats': weatherApiStats.toJson(),
      'totalApiCost': totalApiCost,
      'totalApiCalls': totalApiCalls,
      'cacheEfficiency': cacheEfficiency,
      'overallHealthScore': _calculateHealthScore(),
    };
  }

  double _calculateHealthScore() {
    // Combine multiple metrics for overall health
    double score = 0.0;
    
    // Cache hit rate (40% weight)
    score += harvestCacheStats.hitRate * 0.4;
    
    // Weather API cache efficiency (30% weight)
    score += weatherApiStats.hitRate * 0.3;
    
    // Cost efficiency (20% weight)
    final costEfficiency = totalApiCalls > 0 ? 
        (1.0 - (totalApiCost / (totalApiCalls * 0.05))) : 1.0;
    score += costEfficiency.clamp(0.0, 1.0) * 0.2;
    
    // Cache size management (10% weight)
    final sizeScore = harvestCacheStats.memoryUsage < 800 ? 1.0 : 0.5;
    score += sizeScore * 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'HarvestCacheAnalytics(efficiency: ${(cacheEfficiency * 100).toStringAsFixed(1)}%, '
           'cost: \$${totalApiCost.toStringAsFixed(2)}, calls: $totalApiCalls)';
  }
}

class HarvestIntelligenceException implements Exception {
  final String message;
  final String? userId;
  final String? combineSpecId;
  final String? locationId;

  HarvestIntelligenceException(
    this.message, {
    this.userId,
    this.combineSpecId,
    this.locationId,
  });

  @override
  String toString() => 'HarvestIntelligenceException: $message';
}