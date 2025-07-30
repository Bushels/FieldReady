/**
 * Weather Intelligence Integration Example
 * Demonstrates how to use the integrated combine thresholds with weather predictions
 * This file shows practical usage of the CropThresholdService and enhanced HarvestIntelligenceService
 */

import '../models/harvest_models.dart';
import '../models/combine_models.dart';
import 'crop_threshold_service.dart';
import 'harvest_intelligence.dart';

/// Example service demonstrating weather intelligence integration
class WeatherIntelligenceExample {
  final HarvestIntelligenceService _harvestIntelligence;

  WeatherIntelligenceExample({
    required HarvestIntelligenceService harvestIntelligence,
  }) : _harvestIntelligence = harvestIntelligence;

  /// Example 1: Get crop-specific harvest recommendations for a farmer
  Future<Map<String, dynamic>> getCanolHarvestRecommendations({
    required String userId,
    required List<FieldLocation> fields,
  }) async {
    print('🌻 Getting canola-specific harvest recommendations...');
    
    try {
      // Get harvest recommendations with canola-specific thresholds
      final result = await _harvestIntelligence.getHarvestRecommendations(
        userId: userId,
        fields: fields,
        crop: CropType.canola,
        forecastDays: 7,
      );

      // Extract canola-specific insights
      final canolaInsights = <String, dynamic>{
        'totalWindows': result.harvestWindows.length,
        'optimalWindows': result.harvestWindows
            .where((w) => w.recommendation == HarvestRecommendation.optimal)
            .length,
        'shatteringRisk': _assessCanolaShatteringRisk(result.harvestWindows),
        'greenSeedRisk': _assessGreenSeedRisk(result.weatherForecasts),
        'economicAnalysis': _calculateCanolaEconomics(result.harvestWindows),
        'recommendations': _generateCanolaRecommendations(result.harvestWindows),
      };

      print('✅ Found ${canolaInsights['totalWindows']} harvest windows');
      print('🎯 ${canolaInsights['optimalWindows']} optimal windows identified');

      return {
        'crop': 'canola',
        'userId': userId,
        'fieldCount': fields.length,
        'processingTime': result.processingTimeMs,
        'insights': canolaInsights,
        'harvestWindows': result.harvestWindows.map((w) => w.toJson()).toList(),
        'combineCapabilities': result.combineCapabilities.map((c) => c.toJson()).toList(),
      };

    } catch (e) {
      print('❌ Error getting canola recommendations: $e');
      return {
        'error': e.toString(),
        'crop': 'canola',
        'userId': userId,
      };
    }
  }

  /// Example 2: Compare wheat harvest timing across different conditions
  Future<Map<String, dynamic>> compareWheatHarvestConditions({
    required FieldLocation field,
    required List<CombineSpec> availableCombines,
  }) async {
    print('🌾 Comparing wheat harvest conditions...');

    final comparisons = <Map<String, dynamic>>[];

    for (final combine in availableCombines) {
      try {
        // Get current weather analysis for wheat
        final currentWeather = MockWeatherData.wheatHarvestDay();
        
        final thresholdAnalysis = CropThresholdService.analyzeWeatherThresholds(
          crop: CropType.wheat,
          weather: currentWeather,
          forecast: MockWeatherData.wheatForecast(),
        );

        final combineCapability = CombineCapability.fromCombineSpec(combine);

        // Create harvest window for analysis
        final window = HarvestWindow.create(
          startTime: DateTime.now().add(const Duration(hours: 8)), // 8 AM
          endTime: DateTime.now().add(const Duration(hours: 18)), // 6 PM
          weather: currentWeather,
          combineCapability: combineCapability,
          crop: CropType.wheat,
          fieldConditions: {'fieldId': field.id},
        );

        comparisons.add({
          'combineId': combine.id,
          'combineName': '${combine.brand} ${combine.model}',
          'recommendation': window.recommendation.name,
          'confidenceScore': window.confidenceScore,
          'priority': window.priority,
          'thresholdViolations': thresholdAnalysis.violations.length,
          'thresholdOpportunities': thresholdAnalysis.opportunities.length,
          'sproutingRisk': _assessWheatSproutingRisk(thresholdAnalysis),
          'proteinQualityRisk': _assessWheatProteinRisk(currentWeather),
          'economicImpact': _calculateWheatEconomics(window, thresholdAnalysis),
        });

      } catch (e) {
        comparisons.add({
          'combineId': combine.id,
          'error': e.toString(),
        });
      }
    }

    // Sort by priority and confidence
    comparisons.sort((a, b) {
      final priorityA = a['priority'] as int? ?? 0;
      final priorityB = b['priority'] as int? ?? 0;
      return priorityB.compareTo(priorityA);
    });

    print('📊 Compared ${comparisons.length} combine options');

    return {
      'crop': 'wheat',
      'field': field.toJson(),
      'comparisons': comparisons,
      'bestOption': comparisons.isNotEmpty ? comparisons.first : null,
      'summary': _generateWheatComparisonSummary(comparisons),
    };
  }

  /// Example 3: Real-time barley malting quality monitoring
  Future<Map<String, dynamic>> monitorMaltingBarleyQuality({
    required List<FieldLocation> maltingFields,
  }) async {
    print('🍺 Monitoring malting barley quality conditions...');

    final monitoringResults = <Map<String, dynamic>>[];

    for (final field in maltingFields) {
      try {
        // Get comprehensive crop-specific recommendations
        final cropRecommendations = await _harvestIntelligence.getCropSpecificRecommendations(
          crop: CropType.barley,
          locations: [field],
          forecastDays: 5,
        );

        final fieldMonitoring = <String, dynamic>{
          'fieldId': field.id,
          'fieldName': field.name,
          'maltingPremiumRisk': _assessMaltingPremiumRisk(cropRecommendations),
          'germinationRisk': _assessGerminationRisk(cropRecommendations),
          'optimalHarvestDays': _countOptimalDays(cropRecommendations),
          'criticalWeatherEvents': _identifyCriticalEvents(cropRecommendations),
          'recommendedActions': _generateBarleyActions(cropRecommendations),
          'qualityProjection': _projectBarleyQuality(cropRecommendations),
        };

        monitoringResults.add(fieldMonitoring);

      } catch (e) {
        monitoringResults.add({
          'fieldId': field.id,
          'fieldName': field.name,
          'error': e.toString(),
        });
      }
    }

    // Calculate overall malting operation status
    final overallStatus = _calculateMaltingOperationStatus(monitoringResults);

    print('📊 Monitored ${monitoringResults.length} malting barley fields');
    print('🎯 Overall operation status: ${overallStatus['status']}');

    return {
      'crop': 'malting_barley',
      'fieldCount': maltingFields.length,
      'monitoringResults': monitoringResults,
      'overallStatus': overallStatus,
      'alerts': _generateMaltingAlerts(monitoringResults),
      'economicProjection': _calculateMaltingEconomics(monitoringResults),
    };
  }

  /// Example 4: Multi-crop harvest scheduling optimization
  Future<Map<String, dynamic>> optimizeMultiCropHarvest({
    required String userId,
    required Map<CropType, List<FieldLocation>> cropFields,
  }) async {
    print('🌱 Optimizing multi-crop harvest schedule...');

    final cropSchedules = <String, dynamic>{};
    final conflictAnalysis = <Map<String, dynamic>>[];

    // Analyze each crop separately
    for (final entry in cropFields.entries) {
      final crop = entry.key;
      final fields = entry.value;

      try {
        final recommendations = await _harvestIntelligence.getHarvestRecommendations(
          userId: userId,
          fields: fields,
          crop: crop,
          forecastDays: 10,
        );

        cropSchedules[crop.name] = {
          'fieldCount': fields.length,
          'totalWindows': recommendations.harvestWindows.length,
          'optimalWindows': recommendations.harvestWindows
              .where((w) => w.recommendation == HarvestRecommendation.optimal)
              .toList(),
          'priority': _calculateCropPriority(crop, recommendations.harvestWindows),
          'timeConstraints': _analyzeCropTimeConstraints(crop, recommendations.harvestWindows),
        };

      } catch (e) {
        cropSchedules[crop.name] = {'error': e.toString()};
      }
    }

    // Identify scheduling conflicts
    final conflicts = _identifySchedulingConflicts(cropSchedules);

    // Generate optimized schedule
    final optimizedSchedule = _generateOptimizedSchedule(cropSchedules, conflicts);

    print('📅 Generated schedule for ${cropFields.length} crop types');
    print('⚠️ Identified ${conflicts.length} scheduling conflicts');

    return {
      'userId': userId,
      'cropCount': cropFields.length,
      'totalFields': cropFields.values.fold(0, (sum, fields) => sum + fields.length),
      'cropSchedules': cropSchedules,
      'conflicts': conflicts,
      'optimizedSchedule': optimizedSchedule,
      'recommendations': _generateMultiCropRecommendations(cropSchedules, conflicts),
    };
  }

  // Helper methods for canola analysis
  Map<String, dynamic> _assessCanolaShatteringRisk(List<HarvestWindow> windows) {
    var highRiskWindows = 0;
    var avgWindSpeed = 0.0;

    for (final window in windows) {
      final windSpeed = window.conditions['windSpeed'] as double? ?? 0.0;
      avgWindSpeed += windSpeed;
      
      if (windSpeed > 25.0) {
        highRiskWindows++;
      }
    }

    avgWindSpeed = windows.isNotEmpty ? avgWindSpeed / windows.length : 0.0;

    return {
      'averageWindSpeed': avgWindSpeed,
      'highRiskWindows': highRiskWindows,
      'riskLevel': avgWindSpeed > 25 ? 'high' : (avgWindSpeed > 15 ? 'medium' : 'low'),
      'estimatedShatterLoss': _calculateShatterLoss(avgWindSpeed),
    };
  }

  double _calculateShatterLoss(double windSpeed) {
    // Canola shattering loss calculation (simplified)
    if (windSpeed > 30) return 150.0; // kg/ha
    if (windSpeed > 25) return 100.0;
    if (windSpeed > 20) return 50.0;
    return 25.0;
  }

  Map<String, dynamic> _assessGreenSeedRisk(List<WeatherForecast> forecasts) {
    var frostRisk = false;
    var immatureHarvestRisk = false;

    for (final forecast in forecasts) {
      for (final weather in forecast.dailyForecasts) {
        final tempMin = weather.temperatureMin ?? weather.temperature ?? 10.0;
        if (tempMin <= -3.0) {
          frostRisk = true;
        }
      }
    }

    return {
      'frostRisk': frostRisk,
      'immatureHarvestRisk': immatureHarvestRisk,
      'greenSeedPenalty': frostRisk ? 75.0 : 0.0, // $/tonne
    };
  }

  Map<String, dynamic> _calculateCanolaEconomics(List<HarvestWindow> windows) {
    final optimalWindows = windows.where((w) => w.recommendation == HarvestRecommendation.optimal).length;
    final totalWindows = windows.length;
    
    return {
      'optimalWindowPercentage': totalWindows > 0 ? (optimalWindows / totalWindows) * 100 : 0,
      'expectedYieldLoss': totalWindows > 0 ? (totalWindows - optimalWindows) * 2.5 : 0, // % loss
      'economicImpact': (totalWindows - optimalWindows) * 50.0, // $/ha estimated loss
    };
  }

  List<String> _generateCanolaRecommendations(List<HarvestWindow> windows) {
    final recommendations = <String>[];
    
    final optimalWindows = windows.where((w) => w.recommendation == HarvestRecommendation.optimal).length;
    if (optimalWindows > 3) {
      recommendations.add('🎯 Excellent harvest window opportunities - prioritize canola fields');
    } else if (optimalWindows > 0) {
      recommendations.add('⏰ Limited optimal windows - schedule harvest carefully');
    } else {
      recommendations.add('⚠️ No optimal windows found - monitor conditions closely');
    }

    final highWindWindows = windows.where((w) => 
      (w.conditions['windSpeed'] as double? ?? 0.0) > 25.0).length;
    if (highWindWindows > 2) {
      recommendations.add('💨 High wind risk - reduce ground speed to minimize shattering');
    }

    return recommendations;
  }

  // Helper methods for wheat analysis
  String _assessWheatSproutingRisk(WeatherThresholdAnalysis analysis) {
    final sproutingViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('sprouting'))
        .length;
    
    if (sproutingViolations > 0) return 'high';
    if (analysis.warnings.any((w) => w.factor.toLowerCase().contains('rain'))) return 'medium';
    return 'low';
  }

  String _assessWheatProteinRisk(WeatherData weather) {
    final temp = weather.temperature ?? 20.0;
    if (temp > 30.0) return 'high';
    if (temp > 25.0) return 'medium';
    return 'low';
  }

  Map<String, dynamic> _calculateWheatEconomics(HarvestWindow window, WeatherThresholdAnalysis analysis) {
    var economicImpact = 0.0;
    
    // Calculate moisture penalties
    final violations = analysis.violations.length;
    economicImpact += violations * 15.0; // $15/tonne per violation
    
    // Calculate quality premiums/penalties
    if (window.recommendation == HarvestRecommendation.optimal) {
      economicImpact -= 10.0; // $10/tonne premium for optimal timing
    }
    
    return {
      'estimatedImpact': economicImpact,
      'moisturePenalty': violations * 10.0,
      'qualityAdjustment': window.recommendation == HarvestRecommendation.optimal ? -10.0 : 0.0,
    };
  }

  Map<String, dynamic> _generateWheatComparisonSummary(List<Map<String, dynamic>> comparisons) {
    if (comparisons.isEmpty) return {'message': 'No valid comparisons'};
    
    final validComparisons = comparisons.where((c) => c['error'] == null).toList();
    if (validComparisons.isEmpty) return {'message': 'No valid combinations found'};
    
    final avgConfidence = validComparisons
        .map((c) => c['confidenceScore'] as double? ?? 0.0)
        .reduce((a, b) => a + b) / validComparisons.length;
    
    return {
      'totalOptions': comparisons.length,
      'validOptions': validComparisons.length,
      'averageConfidence': avgConfidence,
      'bestCombine': validComparisons.first['combineName'],
      'recommendation': avgConfidence > 0.8 ? 'Proceed with harvest' : 'Monitor conditions',
    };
  }

  // Helper methods for barley analysis
  String _assessMaltingPremiumRisk(Map<String, dynamic> recommendations) {
    final avgRisk = recommendations['summary']?['averageRiskScore'] as double? ?? 0.5;
    if (avgRisk > 0.7) return 'high';
    if (avgRisk > 0.4) return 'medium';
    return 'low';
  }

  String _assessGerminationRisk(Map<String, dynamic> recommendations) {
    final criticalRisks = recommendations['summary']?['totalCriticalRisks'] as int? ?? 0;
    if (criticalRisks > 2) return 'critical';
    if (criticalRisks > 0) return 'high';
    return 'low';
  }

  int _countOptimalDays(Map<String, dynamic> recommendations) {
    return recommendations['summary']?['totalOptimalWindows'] as int? ?? 0;
  }

  List<String> _identifyCriticalEvents(Map<String, dynamic> recommendations) {
    final events = <String>[];
    final locationAnalyses = recommendations['locationAnalyses'] as List? ?? [];
    
    for (final location in locationAnalyses) {
      final dailyAnalyses = location['dailyAnalyses'] as List? ?? [];
      for (final day in dailyAnalyses) {
        final violations = day['violations'] as int? ?? 0;
        if (violations > 2) {
          events.add('High risk day: ${day['date']}');
        }
      }
    }
    
    return events;
  }

  List<String> _generateBarleyActions(Map<String, dynamic> recommendations) {
    final actions = <String>[];
    final avgRisk = recommendations['summary']?['averageRiskScore'] as double? ?? 0.5;
    
    if (avgRisk > 0.7) {
      actions.add('🚨 Immediate harvest required to preserve malting quality');
    } else if (avgRisk > 0.4) {
      actions.add('⏰ Schedule harvest within 48 hours');
    } else {
      actions.add('📊 Continue monitoring - conditions are stable');
    }
    
    return actions;
  }

  Map<String, dynamic> _projectBarleyQuality(Map<String, dynamic> recommendations) {
    final avgRisk = recommendations['summary']?['averageRiskScore'] as double? ?? 0.5;
    
    return {
      'maltingGrade': avgRisk < 0.3 ? 'Premium' : (avgRisk < 0.6 ? 'Standard' : 'At Risk'),
      'germinationProjection': avgRisk < 0.4 ? '>95%' : (avgRisk < 0.7 ? '90-95%' : '<90%'),
      'proteinProjection': '10.5-12.5%', // Would be calculated based on conditions
    };
  }

  Map<String, dynamic> _calculateMaltingOperationStatus(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return {'status': 'No data', 'confidence': 0.0};
    }
    
    final validResults = results.where((r) => r['error'] == null).toList();
    if (validResults.isEmpty) {
      return {'status': 'Error', 'confidence': 0.0};
    }
    
    final highRiskFields = validResults.where((r) => r['maltingPremiumRisk'] == 'high').length;
    final totalFields = validResults.length;
    
    if (highRiskFields > totalFields * 0.5) {
      return {'status': 'Critical', 'confidence': 0.9, 'action': 'Immediate harvest required'};
    } else if (highRiskFields > 0) {
      return {'status': 'Caution', 'confidence': 0.7, 'action': 'Monitor closely'};
    } else {
      return {'status': 'Optimal', 'confidence': 0.8, 'action': 'Proceed as planned'};
    }
  }

  List<Map<String, dynamic>> _generateMaltingAlerts(List<Map<String, dynamic>> results) {
    final alerts = <Map<String, dynamic>>[];
    
    for (final result in results) {
      if (result['maltingPremiumRisk'] == 'high') {
        alerts.add({
          'type': 'critical',
          'field': result['fieldName'],
          'message': 'Malting premium at risk - immediate action required',
        });
      }
      
      if (result['germinationRisk'] == 'critical') {
        alerts.add({
          'type': 'critical',
          'field': result['fieldName'],
          'message': 'Germination viability threatened - harvest immediately',  
        });
      }
    }
    
    return alerts;
  }

  Map<String, dynamic> _calculateMaltingEconomics(List<Map<String, dynamic>> results) {
    var totalPremiumRisk = 0.0;
    var fieldsAtRisk = 0;
    
    for (final result in results) {
      if (result['maltingPremiumRisk'] == 'high') {
        totalPremiumRisk += 50.0; // $50/tonne premium loss
        fieldsAtRisk++;
      }
    }
    
    return {
      'fieldsAtRisk': fieldsAtRisk,
      'totalFields': results.length,
      'estimatedPremiumLoss': totalPremiumRisk,
      'riskPercentage': results.isNotEmpty ? (fieldsAtRisk / results.length) * 100 : 0,
    };
  }

  // Helper methods for multi-crop optimization
  int _calculateCropPriority(CropType crop, List<HarvestWindow> windows) {
    // Canola gets highest priority due to shattering risk
    if (crop == CropType.canola) return 10;
    // Malting barley next due to quality sensitivity
    if (crop == CropType.barley) return 9;
    // Wheat is more flexible
    if (crop == CropType.wheat) return 7;
    return 5;
  }

  Map<String, dynamic> _analyzeCropTimeConstraints(CropType crop, List<HarvestWindow> windows) {
    final optimalWindows = windows.where((w) => w.recommendation == HarvestRecommendation.optimal).toList();
    
    return {
      'optimalWindowCount': optimalWindows.length,
      'timeFlexibility': optimalWindows.length > 5 ? 'high' : (optimalWindows.length > 2 ? 'medium' : 'low'),
      'urgency': crop == CropType.canola ? 'high' : 'medium',
    };
  }

  List<Map<String, dynamic>> _identifySchedulingConflicts(Map<String, dynamic> cropSchedules) {
    final conflicts = <Map<String, dynamic>>[];
    
    // This would implement overlap detection between crop harvest windows
    // For now, return simple conflicts based on priority
    final highPriorityCrops = cropSchedules.entries
        .where((entry) => (entry.value['priority'] as int? ?? 0) > 8)
        .length;
    
    if (highPriorityCrops > 1) {
      conflicts.add({
        'type': 'priority_conflict',
        'message': 'Multiple high-priority crops need attention simultaneously',
        'affectedCrops': cropSchedules.keys.toList(),
      });
    }
    
    return conflicts;
  }

  Map<String, dynamic> _generateOptimizedSchedule(
    Map<String, dynamic> cropSchedules,
    List<Map<String, dynamic>> conflicts,
  ) {
    // Sort crops by priority
    final sortedCrops = cropSchedules.entries.toList()
      ..sort((a, b) => (b.value['priority'] as int? ?? 0).compareTo(a.value['priority'] as int? ?? 0));
    
    return {
      'schedulingOrder': sortedCrops.map((e) => e.key).toList(),
      'conflicts': conflicts.length,
      'recommendation': conflicts.isEmpty ? 'Proceed with schedule' : 'Resource conflicts detected',
    };
  }

  List<String> _generateMultiCropRecommendations(
    Map<String, dynamic> cropSchedules,
    List<Map<String, dynamic>> conflicts,
  ) {
    final recommendations = <String>[];
    
    if (conflicts.isEmpty) {
      recommendations.add('✅ No scheduling conflicts detected - proceed as planned');
    } else {
      recommendations.add('⚠️ ${conflicts.length} scheduling conflicts require attention');
    }
    
    final highPriorityCrops = cropSchedules.entries
        .where((entry) => (entry.value['priority'] as int? ?? 0) > 8)
        .map((e) => e.key)
        .toList();
    
    if (highPriorityCrops.isNotEmpty) {
      recommendations.add('🎯 Prioritize: ${highPriorityCrops.join(', ')}');
    }
    
    return recommendations;
  }
}

/// Mock weather data for examples
class MockWeatherData {
  static WeatherData wheatHarvestDay() {
    return WeatherData(
      locationId: 'field_001',
      timestamp: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      temperature: 22.0,
      temperatureMin: 15.0,
      temperatureMax: 25.0,
      humidity: 65.0,
      precipitation: 0.0,
      windSpeed: 12.0,
      windDirection: 180.0,
      dewPoint: 14.0,
      condition: WeatherCondition.clear,
      description: 'Clear skies, ideal for harvest',
    );
  }

  static List<WeatherData> wheatForecast() {
    return List.generate(7, (index) {
      return WeatherData(
        locationId: 'field_001',
        timestamp: DateTime.now().add(Duration(days: index)),
        provider: WeatherProvider.tomorrowIo,
        temperature: 20.0 + (index * 2),
        temperatureMin: 12.0 + index,
        temperatureMax: 28.0 + index,
        humidity: 60.0 + (index * 3),
        precipitation: index > 4 ? 5.0 : 0.0,
        windSpeed: 10.0 + (index * 2),
        windDirection: 180.0,
        dewPoint: 12.0 + index,
        condition: index > 4 ? WeatherCondition.rain : WeatherCondition.clear,
        description: index > 4 ? 'Rain expected' : 'Good conditions',
      );
    });
  }
}