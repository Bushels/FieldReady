/**
 * Repository interface for combine data operations
 * Handles combine performance data, historical records, and analytics
 * Supports offline-first architecture with clean separation of concerns
 */

import '../models/combine_models.dart';

/// Repository interface for combine performance data management
abstract class CombineDataRepository extends BaseRepository<CombineDataRecord> {
  /// Get performance data for a specific combine
  Future<List<CombineDataRecord>> getByUserCombineId(String userCombineId);
  
  /// Get performance data by date range
  Future<List<CombineDataRecord>> getByDateRange(
    String userCombineId,
    DateTime startDate,
    DateTime endDate,
  );
  
  /// Get performance data by crop type
  Future<List<CombineDataRecord>> getByCrop(
    String userCombineId,
    String crop,
  );
  
  /// Get performance data by field conditions
  Future<List<CombineDataRecord>> getByFieldConditions(
    String userCombineId,
    Map<String, dynamic> conditions,
  );
  
  /// Record new performance data entry
  Future<String> recordPerformanceData(CombineDataRecord data);
  
  /// Update existing performance data
  Future<void> updatePerformanceData(String recordId, CombineDataRecord data);
  
  /// Get performance statistics for a combine
  Future<CombinePerformanceStats> getPerformanceStats(
    String userCombineId, {
    DateTime? startDate,
    DateTime? endDate,
    String? crop,
  });
  
  /// Get comparative performance data (peer comparison)
  Future<List<ComparativeData>> getComparativeData(
    String region,
    String combineSpec,
    String crop, {
    String? moistureRange,
    String? fieldConditions,
  });
  
  /// Get efficiency trends over time
  Future<List<EfficiencyTrend>> getEfficiencyTrends(
    String userCombineId,
    String metric, // 'fuel_efficiency', 'harvest_rate', 'grain_loss', etc.
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// Get maintenance impact data
  Future<List<MaintenanceImpact>> getMaintenanceImpact(String userCombineId);
  
  /// Record maintenance event and its impact
  Future<void> recordMaintenanceEvent(MaintenanceEvent event);
  
  /// Get optimal settings recommendations based on historical data
  Future<SettingsRecommendation> getOptimalSettings(
    String userCombineId,
    String crop,
    Map<String, dynamic> currentConditions,
  );
  
  /// Export performance data for user (PIPEDA compliance)
  Future<List<Map<String, dynamic>>> exportUserData(String userId);
  
  /// Delete user performance data (right to be forgotten)
  Future<void> deleteUserData(String userId);
  
  /// Get aggregated regional performance data (anonymized)
  Future<RegionalPerformanceData> getRegionalData(
    String region,
    String crop, {
    String? combineSpec,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Batch import performance data (for data migration)
  Future<List<String>> batchImportData(List<CombineDataRecord> records);
  
  /// Get data quality metrics
  Future<DataQualityMetrics> getDataQuality(String userCombineId);
  
  /// Validate and clean performance data
  Future<ValidationResult> validateData(CombineDataRecord data);
  
  /// Get pending data synchronization records
  Future<List<CombineDataRecord>> getPendingSync(String userId);
  
  /// Mark data as synchronized
  Future<void> markSynced(String recordId, DateTime syncedAt);
}

/// Repository interface for combine field operations data
abstract class CombineFieldDataRepository {
  /// Record field operation start
  Future<String> startFieldOperation(FieldOperationStart operation);
  
  /// Record field operation end
  Future<void> endFieldOperation(String operationId, FieldOperationEnd operation);
  
  /// Get active field operations for a combine
  Future<List<ActiveFieldOperation>> getActiveOperations(String userCombineId);
  
  /// Get completed field operations
  Future<List<CompletedFieldOperation>> getCompletedOperations(
    String userCombineId, {
    DateTime? startDate,
    DateTime? endDate,
    String? crop,
    String? field,
  });
  
  /// Get field operation summary
  Future<FieldOperationSummary> getOperationSummary(
    String operationId,
  );
  
  /// Get field-specific performance data
  Future<FieldPerformanceData> getFieldPerformance(
    String fieldId,
    String crop,
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// Record real-time operation data
  Future<void> recordRealTimeData(String operationId, RealTimeData data);
  
  /// Get real-time operation data stream
  Stream<RealTimeData> getRealTimeDataStream(String operationId);
  
  /// Calculate field completion percentage
  Future<double> getFieldCompletionPercentage(String operationId);
  
  /// Get weather impact on field operations
  Future<WeatherImpactData> getWeatherImpact(String operationId);
  
  /// Record GPS track data for field operation
  Future<void> recordGPSTrack(String operationId, List<GPSPoint> track);
  
  /// Get GPS track data for analysis
  Future<List<GPSPoint>> getGPSTrack(String operationId);
  
  /// Calculate field coverage efficiency
  Future<CoverageAnalysis> analyzeCoverage(String operationId);
}

/// Repository interface for combine settings and configurations
abstract class CombineSettingsRepository {
  /// Get combine settings profile
  Future<CombineSettingsProfile?> getSettingsProfile(
    String userCombineId,
    String crop,
    {String? conditions}
  );
  
  /// Save combine settings profile
  Future<String> saveSettingsProfile(CombineSettingsProfile profile);
  
  /// Update settings profile
  Future<void> updateSettingsProfile(String profileId, CombineSettingsProfile profile);
  
  /// Get all settings profiles for a combine
  Future<List<CombineSettingsProfile>> getAllProfiles(String userCombineId);
  
  /// Get optimal settings based on conditions
  Future<OptimalSettings> getOptimalSettings(
    String combineSpecId,
    String crop,
    Map<String, dynamic> conditions,
  );
  
  /// Record settings usage and effectiveness
  Future<void> recordSettingsUsage(SettingsUsageRecord usage);
  
  /// Get settings effectiveness data
  Future<SettingsEffectiveness> getSettingsEffectiveness(
    String profileId,
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// Get shared settings recommendations from community
  Future<List<CommunitySettingsRecommendation>> getCommunityRecommendations(
    String combineSpecId,
    String crop,
    String region,
  );
  
  /// Share settings profile with community (anonymized)
  Future<void> shareSettingsProfile(
    String profileId,
    bool shareAnonymously,
  );
  
  /// Import settings from external source
  Future<String> importSettings(
    String userCombineId,
    Map<String, dynamic> settingsData,
    String source,
  );
  
  /// Export settings for backup
  Future<Map<String, dynamic>> exportSettings(String userCombineId);
  
  /// Get factory default settings
  Future<Map<String, dynamic>> getFactoryDefaults(String combineSpecId);
  
  /// Reset settings to factory defaults
  Future<void> resetToDefaults(String userCombineId, String combineSpecId);
}

/// Supporting data classes for combine data operations

class CombineDataRecord extends BaseDocument {
  final String userCombineId;
  final String crop;
  final String? fieldId;
  final DateTime operationDate;
  final double harvestedArea; // hectares
  final double harvestTime; // hours
  final double fuelConsumed; // liters
  final double grainYield; // tonnes
  final double grainMoisture; // percentage
  final double grainLoss; // percentage
  final Map<String, dynamic> combineSettings;
  final Map<String, dynamic> fieldConditions;
  final Map<String, dynamic> weatherConditions;
  final double? operatorRating; // 1-10 scale
  final String? operatorNotes;
  final List<String>? issues;
  final Map<String, double>? performanceMetrics;
  final GPSBounds? fieldBounds;
  final bool isValidated;
  final DateTime? syncedAt;

  CombineDataRecord({
    required String id,
    required this.userCombineId,
    required this.crop,
    this.fieldId,
    required this.operationDate,
    required this.harvestedArea,
    required this.harvestTime,
    required this.fuelConsumed,
    required this.grainYield,
    required this.grainMoisture,
    required this.grainLoss,
    required this.combineSettings,
    required this.fieldConditions,
    required this.weatherConditions,
    this.operatorRating,
    this.operatorNotes,
    this.issues,
    this.performanceMetrics,
    this.fieldBounds,
    required this.isValidated,
    this.syncedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CombineDataRecord.fromJson(Map<String, dynamic> json) {
    return CombineDataRecord(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      fieldId: json['fieldId'] as String?,
      operationDate: DateTime.parse(json['operationDate'] as String),
      harvestedArea: (json['harvestedArea'] as num).toDouble(),
      harvestTime: (json['harvestTime'] as num).toDouble(),
      fuelConsumed: (json['fuelConsumed'] as num).toDouble(),
      grainYield: (json['grainYield'] as num).toDouble(),
      grainMoisture: (json['grainMoisture'] as num).toDouble(),
      grainLoss: (json['grainLoss'] as num).toDouble(),
      combineSettings: Map<String, dynamic>.from(json['combineSettings'] as Map),
      fieldConditions: Map<String, dynamic>.from(json['fieldConditions'] as Map),
      weatherConditions: Map<String, dynamic>.from(json['weatherConditions'] as Map),
      operatorRating: json['operatorRating'] != null 
          ? (json['operatorRating'] as num).toDouble()
          : null,
      operatorNotes: json['operatorNotes'] as String?,
      issues: json['issues'] != null 
          ? List<String>.from(json['issues'] as List)
          : null,
      performanceMetrics: json['performanceMetrics'] != null
          ? Map<String, double>.from(json['performanceMetrics'])
          : null,
      fieldBounds: json['fieldBounds'] != null
          ? GPSBounds.fromJson(json['fieldBounds'])
          : null,
      isValidated: json['isValidated'] as bool,
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'crop': crop,
      'fieldId': fieldId,
      'operationDate': operationDate.toIso8601String(),
      'harvestedArea': harvestedArea,
      'harvestTime': harvestTime,
      'fuelConsumed': fuelConsumed,
      'grainYield': grainYield,
      'grainMoisture': grainMoisture,
      'grainLoss': grainLoss,
      'combineSettings': combineSettings,
      'fieldConditions': fieldConditions,
      'weatherConditions': weatherConditions,
      'operatorRating': operatorRating,
      'operatorNotes': operatorNotes,
      'issues': issues,
      'performanceMetrics': performanceMetrics,
      'fieldBounds': fieldBounds?.toJson(),
      'isValidated': isValidated,
      'syncedAt': syncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CombinePerformanceStats {
  final String userCombineId;
  final double totalHours;
  final double totalArea;
  final double totalFuel;
  final double totalGrain;
  final double averageFuelEfficiency; // L/ha
  final double averageHarvestRate; // ha/h
  final double averageGrainLoss; // percentage
  final double averageYield; // tonnes/ha
  final Map<String, double> cropSpecificStats;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalOperations;

  CombinePerformanceStats({
    required this.userCombineId,
    required this.totalHours,
    required this.totalArea,
    required this.totalFuel,
    required this.totalGrain,
    required this.averageFuelEfficiency,
    required this.averageHarvestRate,
    required this.averageGrainLoss,
    required this.averageYield,
    required this.cropSpecificStats,
    required this.periodStart,
    required this.periodEnd,
    required this.totalOperations,
  });

  factory CombinePerformanceStats.fromJson(Map<String, dynamic> json) {
    return CombinePerformanceStats(
      userCombineId: json['userCombineId'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      totalArea: (json['totalArea'] as num).toDouble(),
      totalFuel: (json['totalFuel'] as num).toDouble(),
      totalGrain: (json['totalGrain'] as num).toDouble(),
      averageFuelEfficiency: (json['averageFuelEfficiency'] as num).toDouble(),
      averageHarvestRate: (json['averageHarvestRate'] as num).toDouble(),
      averageGrainLoss: (json['averageGrainLoss'] as num).toDouble(),
      averageYield: (json['averageYield'] as num).toDouble(),
      cropSpecificStats: Map<String, double>.from(json['cropSpecificStats']),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalOperations: json['totalOperations'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'totalHours': totalHours,
      'totalArea': totalArea,
      'totalFuel': totalFuel,
      'totalGrain': totalGrain,
      'averageFuelEfficiency': averageFuelEfficiency,
      'averageHarvestRate': averageHarvestRate,
      'averageGrainLoss': averageGrainLoss,
      'averageYield': averageYield,
      'cropSpecificStats': cropSpecificStats,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalOperations': totalOperations,
    };
  }
}

class ComparativeData {
  final String combineSpec;
  final String crop;
  final String region;
  final int sampleSize;
  final double benchmarkFuelEfficiency;
  final double benchmarkHarvestRate;
  final double benchmarkGrainLoss;
  final double benchmarkYield;
  final Map<String, double> percentileRanges;
  final DateTime lastUpdated;

  ComparativeData({
    required this.combineSpec,
    required this.crop,
    required this.region,
    required this.sampleSize,
    required this.benchmarkFuelEfficiency,
    required this.benchmarkHarvestRate,
    required this.benchmarkGrainLoss,
    required this.benchmarkYield,
    required this.percentileRanges,
    required this.lastUpdated,
  });

  factory ComparativeData.fromJson(Map<String, dynamic> json) {
    return ComparativeData(
      combineSpec: json['combineSpec'] as String,
      crop: json['crop'] as String,
      region: json['region'] as String,
      sampleSize: json['sampleSize'] as int,
      benchmarkFuelEfficiency: (json['benchmarkFuelEfficiency'] as num).toDouble(),
      benchmarkHarvestRate: (json['benchmarkHarvestRate'] as num).toDouble(),
      benchmarkGrainLoss: (json['benchmarkGrainLoss'] as num).toDouble(),
      benchmarkYield: (json['benchmarkYield'] as num).toDouble(),
      percentileRanges: Map<String, double>.from(json['percentileRanges']),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpec': combineSpec,
      'crop': crop,
      'region': region,
      'sampleSize': sampleSize,
      'benchmarkFuelEfficiency': benchmarkFuelEfficiency,
      'benchmarkHarvestRate': benchmarkHarvestRate,
      'benchmarkGrainLoss': benchmarkGrainLoss,
      'benchmarkYield': benchmarkYield,
      'percentileRanges': percentileRanges,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class EfficiencyTrend {
  final DateTime date;
  final double value;
  final String metric;
  final double movingAverage;
  final String? annotation;

  EfficiencyTrend({
    required this.date,
    required this.value,
    required this.metric,
    required this.movingAverage,
    this.annotation,
  });

  factory EfficiencyTrend.fromJson(Map<String, dynamic> json) {
    return EfficiencyTrend(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      metric: json['metric'] as String,
      movingAverage: (json['movingAverage'] as num).toDouble(),
      annotation: json['annotation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      'metric': metric,
      'movingAverage': movingAverage,
      'annotation': annotation,
    };
  }
}

class MaintenanceImpact {
  final String maintenanceType;
  final DateTime maintenanceDate;
  final double prePerformance;
  final double postPerformance;
  final double improvementPercentage;
  final String metric;
  final Map<String, dynamic> maintenanceDetails;

  MaintenanceImpact({
    required this.maintenanceType,
    required this.maintenanceDate,
    required this.prePerformance,
    required this.postPerformance,
    required this.improvementPercentage,
    required this.metric,
    required this.maintenanceDetails,
  });

  factory MaintenanceImpact.fromJson(Map<String, dynamic> json) {
    return MaintenanceImpact(
      maintenanceType: json['maintenanceType'] as String,
      maintenanceDate: DateTime.parse(json['maintenanceDate'] as String),
      prePerformance: (json['prePerformance'] as num).toDouble(),
      postPerformance: (json['postPerformance'] as num).toDouble(),
      improvementPercentage: (json['improvementPercentage'] as num).toDouble(),
      metric: json['metric'] as String,
      maintenanceDetails: Map<String, dynamic>.from(json['maintenanceDetails']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceType': maintenanceType,
      'maintenanceDate': maintenanceDate.toIso8601String(),
      'prePerformance': prePerformance,
      'postPerformance': postPerformance,
      'improvementPercentage': improvementPercentage,
      'metric': metric,
      'maintenanceDetails': maintenanceDetails,
    };
  }
}

class MaintenanceEvent extends BaseDocument {
  final String userCombineId;
  final String maintenanceType;
  final DateTime eventDate;
  final double cost;
  final String? description;
  final List<String> partsReplaced;
  final Map<String, dynamic> preMaintenanceData;
  final Map<String, dynamic>? postMaintenanceData;
  final String? serviceProvider;
  final bool isWarrantyWork;

  MaintenanceEvent({
    required String id,
    required this.userCombineId,
    required this.maintenanceType,
    required this.eventDate,
    required this.cost,
    this.description,
    required this.partsReplaced,
    required this.preMaintenanceData,
    this.postMaintenanceData,
    this.serviceProvider,
    required this.isWarrantyWork,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory MaintenanceEvent.fromJson(Map<String, dynamic> json) {
    return MaintenanceEvent(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      maintenanceType: json['maintenanceType'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      cost: (json['cost'] as num).toDouble(),
      description: json['description'] as String?,
      partsReplaced: List<String>.from(json['partsReplaced'] as List),
      preMaintenanceData: Map<String, dynamic>.from(json['preMaintenanceData']),
      postMaintenanceData: json['postMaintenanceData'] != null
          ? Map<String, dynamic>.from(json['postMaintenanceData'])
          : null,
      serviceProvider: json['serviceProvider'] as String?,
      isWarrantyWork: json['isWarrantyWork'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'maintenanceType': maintenanceType,
      'eventDate': eventDate.toIso8601String(),
      'cost': cost,
      'description': description,
      'partsReplaced': partsReplaced,
      'preMaintenanceData': preMaintenanceData,
      'postMaintenanceData': postMaintenanceData,
      'serviceProvider': serviceProvider,
      'isWarrantyWork': isWarrantyWork,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SettingsRecommendation {
  final String userCombineId;
  final String crop;
  final Map<String, dynamic> recommendedSettings;
  final Map<String, double> confidenceScores;
  final List<String> reasoning;
  final Map<String, dynamic> expectedImprovement;
  final DateTime generatedAt;
  final String recommendationSource;

  SettingsRecommendation({
    required this.userCombineId,
    required this.crop,
    required this.recommendedSettings,
    required this.confidenceScores,
    required this.reasoning,
    required this.expectedImprovement,
    required this.generatedAt,
    required this.recommendationSource,
  });

  factory SettingsRecommendation.fromJson(Map<String, dynamic> json) {
    return SettingsRecommendation(
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      recommendedSettings: Map<String, dynamic>.from(json['recommendedSettings']),
      confidenceScores: Map<String, double>.from(json['confidenceScores']),
      reasoning: List<String>.from(json['reasoning'] as List),
      expectedImprovement: Map<String, dynamic>.from(json['expectedImprovement']),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      recommendationSource: json['recommendationSource'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'crop': crop,
      'recommendedSettings': recommendedSettings,
      'confidenceScores': confidenceScores,
      'reasoning': reasoning,
      'expectedImprovement': expectedImprovement,
      'generatedAt': generatedAt.toIso8601String(),
      'recommendationSource': recommendationSource,
    };
  }
}

class GPSBounds {
  final double northLat;
  final double southLat;
  final double eastLng;
  final double westLng;

  GPSBounds({
    required this.northLat,
    required this.southLat,
    required this.eastLng,
    required this.westLng,
  });

  factory GPSBounds.fromJson(Map<String, dynamic> json) {
    return GPSBounds(
      northLat: (json['northLat'] as num).toDouble(),
      southLat: (json['southLat'] as num).toDouble(),
      eastLng: (json['eastLng'] as num).toDouble(),
      westLng: (json['westLng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'northLat': northLat,
      'southLat': southLat,
      'eastLng': eastLng,
      'westLng': westLng,
    };
  }
}

class RegionalPerformanceData {
  final String region;
  final String crop;
  final int participatingFarms;
  final double averageFuelEfficiency;
  final double averageHarvestRate;
  final double averageGrainLoss;
  final double averageYield;
  final Map<String, double> performanceDistribution;
  final DateTime dataAsOf;

  RegionalPerformanceData({
    required this.region,
    required this.crop,
    required this.participatingFarms,
    required this.averageFuelEfficiency,
    required this.averageHarvestRate,
    required this.averageGrainLoss,
    required this.averageYield,
    required this.performanceDistribution,
    required this.dataAsOf,
  });

  factory RegionalPerformanceData.fromJson(Map<String, dynamic> json) {
    return RegionalPerformanceData(
      region: json['region'] as String,
      crop: json['crop'] as String,
      participatingFarms: json['participatingFarms'] as int,
      averageFuelEfficiency: (json['averageFuelEfficiency'] as num).toDouble(),
      averageHarvestRate: (json['averageHarvestRate'] as num).toDouble(),
      averageGrainLoss: (json['averageGrainLoss'] as num).toDouble(),
      averageYield: (json['averageYield'] as num).toDouble(),
      performanceDistribution: Map<String, double>.from(json['performanceDistribution']),
      dataAsOf: DateTime.parse(json['dataAsOf'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'crop': crop,
      'participatingFarms': participatingFarms,
      'averageFuelEfficiency': averageFuelEfficiency,
      'averageHarvestRate': averageHarvestRate,
      'averageGrainLoss': averageGrainLoss,
      'averageYield': averageYield,
      'performanceDistribution': performanceDistribution,
      'dataAsOf': dataAsOf.toIso8601String(),
    };
  }
}

class DataQualityMetrics {
  final String userCombineId;
  final double completenessScore;
  final double accuracyScore;
  final double consistencyScore;
  final double overallQuality;
  final List<String> qualityIssues;
  final Map<String, int> missingDataCounts;
  final DateTime assessedAt;

  DataQualityMetrics({
    required this.userCombineId,
    required this.completenessScore,
    required this.accuracyScore,
    required this.consistencyScore,
    required this.overallQuality,
    required this.qualityIssues,
    required this.missingDataCounts,
    required this.assessedAt,
  });

  factory DataQualityMetrics.fromJson(Map<String, dynamic> json) {
    return DataQualityMetrics(
      userCombineId: json['userCombineId'] as String,
      completenessScore: (json['completenessScore'] as num).toDouble(),
      accuracyScore: (json['accuracyScore'] as num).toDouble(),
      consistencyScore: (json['consistencyScore'] as num).toDouble(),
      overallQuality: (json['overallQuality'] as num).toDouble(),
      qualityIssues: List<String>.from(json['qualityIssues'] as List),
      missingDataCounts: Map<String, int>.from(json['missingDataCounts']),
      assessedAt: DateTime.parse(json['assessedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'completenessScore': completenessScore,
      'accuracyScore': accuracyScore,
      'consistencyScore': consistencyScore,
      'overallQuality': overallQuality,
      'qualityIssues': qualityIssues,
      'missingDataCounts': missingDataCounts,
      'assessedAt': assessedAt.toIso8601String(),
    };
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? correctedData;
  final double confidenceScore;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.correctedData,
    required this.confidenceScore,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValid: json['isValid'] as bool,
      errors: List<String>.from(json['errors'] as List),
      warnings: List<String>.from(json['warnings'] as List),
      correctedData: json['correctedData'] != null
          ? Map<String, dynamic>.from(json['correctedData'])
          : null,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'errors': errors,
      'warnings': warnings,
      'correctedData': correctedData,
      'confidenceScore': confidenceScore,
    };
  }
}

/// Additional supporting classes for field operations

class FieldOperationStart {
  final String userCombineId;
  final String crop;
  final String? fieldId;
  final DateTime startTime;
  final Map<String, dynamic> initialConditions;
  final Map<String, dynamic> combineSettings;
  final GPSPoint startLocation;

  FieldOperationStart({
    required this.userCombineId,
    required this.crop,
    this.fieldId,
    required this.startTime,
    required this.initialConditions,
    required this.combineSettings,
    required this.startLocation,
  });

  factory FieldOperationStart.fromJson(Map<String, dynamic> json) {
    return FieldOperationStart(
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      fieldId: json['fieldId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      initialConditions: Map<String, dynamic>.from(json['initialConditions']),
      combineSettings: Map<String, dynamic>.from(json['combineSettings']),
      startLocation: GPSPoint.fromJson(json['startLocation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'crop': crop,
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'initialConditions': initialConditions,
      'combineSettings': combineSettings,
      'startLocation': startLocation.toJson(),
    };
  }
}

class FieldOperationEnd {
  final DateTime endTime;
  final double totalArea;
  final double totalGrain;
  final double totalFuel;
  final GPSPoint endLocation;
  final Map<String, dynamic> finalConditions;
  final String? operatorNotes;
  final List<String>? issues;

  FieldOperationEnd({
    required this.endTime,
    required this.totalArea,
    required this.totalGrain,
    required this.totalFuel,
    required this.endLocation,
    required this.finalConditions,
    this.operatorNotes,
    this.issues,
  });

  factory FieldOperationEnd.fromJson(Map<String, dynamic> json) {
    return FieldOperationEnd(
      endTime: DateTime.parse(json['endTime'] as String),
      totalArea: (json['totalArea'] as num).toDouble(),
      totalGrain: (json['totalGrain'] as num).toDouble(),
      totalFuel: (json['totalFuel'] as num).toDouble(),
      endLocation: GPSPoint.fromJson(json['endLocation']),
      finalConditions: Map<String, dynamic>.from(json['finalConditions']),
      operatorNotes: json['operatorNotes'] as String?,
      issues: json['issues'] != null
          ? List<String>.from(json['issues'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endTime': endTime.toIso8601String(),
      'totalArea': totalArea,
      'totalGrain': totalGrain,
      'totalFuel': totalFuel,
      'endLocation': endLocation.toJson(),
      'finalConditions': finalConditions,
      'operatorNotes': operatorNotes,
      'issues': issues,
    };
  }
}

class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  factory GPSPoint.fromJson(Map<String, dynamic> json) {
    return GPSPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }
}

class ActiveFieldOperation extends BaseDocument {
  final String userCombineId;
  final String crop;
  final String? fieldId;
  final DateTime startTime;
  final GPSPoint startLocation;
  final Map<String, dynamic> combineSettings;
  final double currentArea;
  final double currentGrain;
  final double currentFuel;

  ActiveFieldOperation({
    required String id,
    required this.userCombineId,
    required this.crop,
    this.fieldId,
    required this.startTime,
    required this.startLocation,
    required this.combineSettings,
    required this.currentArea,
    required this.currentGrain,
    required this.currentFuel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory ActiveFieldOperation.fromJson(Map<String, dynamic> json) {
    return ActiveFieldOperation(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      fieldId: json['fieldId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      startLocation: GPSPoint.fromJson(json['startLocation']),
      combineSettings: Map<String, dynamic>.from(json['combineSettings']),
      currentArea: (json['currentArea'] as num).toDouble(),
      currentGrain: (json['currentGrain'] as num).toDouble(),
      currentFuel: (json['currentFuel'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'crop': crop,
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'startLocation': startLocation.toJson(),
      'combineSettings': combineSettings,
      'currentArea': currentArea,
      'currentGrain': currentGrain,
      'currentFuel': currentFuel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CompletedFieldOperation extends BaseDocument {
  final String userCombineId;
  final String crop;
  final String? fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalArea;
  final double totalGrain;
  final double totalFuel;
  final double averageYield;
  final double averageMoisture;
  final double fuelEfficiency;
  final double harvestRate;
  final String? operatorNotes;
  final List<String>? issues;

  CompletedFieldOperation({
    required String id,
    required this.userCombineId,
    required this.crop,
    this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.totalArea,
    required this.totalGrain,
    required this.totalFuel,
    required this.averageYield,
    required this.averageMoisture,
    required this.fuelEfficiency,
    required this.harvestRate,
    this.operatorNotes,
    this.issues,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CompletedFieldOperation.fromJson(Map<String, dynamic> json) {
    return CompletedFieldOperation(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      fieldId: json['fieldId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalArea: (json['totalArea'] as num).toDouble(),
      totalGrain: (json['totalGrain'] as num).toDouble(),
      totalFuel: (json['totalFuel'] as num).toDouble(),
      averageYield: (json['averageYield'] as num).toDouble(),
      averageMoisture: (json['averageMoisture'] as num).toDouble(),
      fuelEfficiency: (json['fuelEfficiency'] as num).toDouble(),
      harvestRate: (json['harvestRate'] as num).toDouble(),
      operatorNotes: json['operatorNotes'] as String?,
      issues: json['issues'] != null
          ? List<String>.from(json['issues'] as List)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'crop': crop,
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalArea': totalArea,
      'totalGrain': totalGrain,
      'totalFuel': totalFuel,
      'averageYield': averageYield,
      'averageMoisture': averageMoisture,
      'fuelEfficiency': fuelEfficiency,
      'harvestRate': harvestRate,
      'operatorNotes': operatorNotes,
      'issues': issues,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class FieldOperationSummary {
  final String operationId;
  final double totalHours;
  final double totalArea;
  final double totalGrain;
  final double totalFuel;
  final double averageSpeed;
  final double peakEfficiency;
  final List<String> settingsChanges;
  final Map<String, double> performanceMetrics;

  FieldOperationSummary({
    required this.operationId,
    required this.totalHours,
    required this.totalArea,
    required this.totalGrain,
    required this.totalFuel,
    required this.averageSpeed,
    required this.peakEfficiency,
    required this.settingsChanges,
    required this.performanceMetrics,
  });

  factory FieldOperationSummary.fromJson(Map<String, dynamic> json) {
    return FieldOperationSummary(
      operationId: json['operationId'] as String,
      totalHours: (json['totalHours'] as num).toDouble(),
      totalArea: (json['totalArea'] as num).toDouble(),
      totalGrain: (json['totalGrain'] as num).toDouble(),
      totalFuel: (json['totalFuel'] as num).toDouble(),
      averageSpeed: (json['averageSpeed'] as num).toDouble(),
      peakEfficiency: (json['peakEfficiency'] as num).toDouble(),
      settingsChanges: List<String>.from(json['settingsChanges'] as List),
      performanceMetrics: Map<String, double>.from(json['performanceMetrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'totalHours': totalHours,
      'totalArea': totalArea,
      'totalGrain': totalGrain,
      'totalFuel': totalFuel,
      'averageSpeed': averageSpeed,
      'peakEfficiency': peakEfficiency,
      'settingsChanges': settingsChanges,
      'performanceMetrics': performanceMetrics,
    };
  }
}

class FieldPerformanceData {
  final String fieldId;
  final String crop;
  final int totalOperations;
  final double totalArea;
  final double averageYield;
  final double bestYield;
  final double averageMoisture;
  final Map<String, double> combinePerformance;
  final DateTime firstHarvest;
  final DateTime lastHarvest;

  FieldPerformanceData({
    required this.fieldId,
    required this.crop,
    required this.totalOperations,
    required this.totalArea,
    required this.averageYield,
    required this.bestYield,
    required this.averageMoisture,
    required this.combinePerformance,
    required this.firstHarvest,
    required this.lastHarvest,
  });

  factory FieldPerformanceData.fromJson(Map<String, dynamic> json) {
    return FieldPerformanceData(
      fieldId: json['fieldId'] as String,
      crop: json['crop'] as String,
      totalOperations: json['totalOperations'] as int,
      totalArea: (json['totalArea'] as num).toDouble(),
      averageYield: (json['averageYield'] as num).toDouble(),
      bestYield: (json['bestYield'] as num).toDouble(),
      averageMoisture: (json['averageMoisture'] as num).toDouble(),
      combinePerformance: Map<String, double>.from(json['combinePerformance']),
      firstHarvest: DateTime.parse(json['firstHarvest'] as String),
      lastHarvest: DateTime.parse(json['lastHarvest'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'crop': crop,
      'totalOperations': totalOperations,
      'totalArea': totalArea,
      'averageYield': averageYield,
      'bestYield': bestYield,
      'averageMoisture': averageMoisture,
      'combinePerformance': combinePerformance,
      'firstHarvest': firstHarvest.toIso8601String(),
      'lastHarvest': lastHarvest.toIso8601String(),
    };
  }
}

class RealTimeData {
  final DateTime timestamp;
  final GPSPoint location;
  final double currentSpeed;
  final double currentYield;
  final double currentMoisture;
  final double currentFuelRate;
  final Map<String, dynamic> sensorData;

  RealTimeData({
    required this.timestamp,
    required this.location,
    required this.currentSpeed,
    required this.currentYield,
    required this.currentMoisture,
    required this.currentFuelRate,
    required this.sensorData,
  });

  factory RealTimeData.fromJson(Map<String, dynamic> json) {
    return RealTimeData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: GPSPoint.fromJson(json['location']),
      currentSpeed: (json['currentSpeed'] as num).toDouble(),
      currentYield: (json['currentYield'] as num).toDouble(),
      currentMoisture: (json['currentMoisture'] as num).toDouble(),
      currentFuelRate: (json['currentFuelRate'] as num).toDouble(),
      sensorData: Map<String, dynamic>.from(json['sensorData']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'location': location.toJson(),
      'currentSpeed': currentSpeed,
      'currentYield': currentYield,
      'currentMoisture': currentMoisture,
      'currentFuelRate': currentFuelRate,
      'sensorData': sensorData,
    };
  }
}

class WeatherImpactData {
  final String operationId;
  final Map<String, dynamic> weatherConditions;
  final double performanceImpact;
  final List<String> weatherFactors;
  final Map<String, double> metricImpacts;

  WeatherImpactData({
    required this.operationId,
    required this.weatherConditions,
    required this.performanceImpact,
    required this.weatherFactors,
    required this.metricImpacts,
  });

  factory WeatherImpactData.fromJson(Map<String, dynamic> json) {
    return WeatherImpactData(
      operationId: json['operationId'] as String,
      weatherConditions: Map<String, dynamic>.from(json['weatherConditions']),
      performanceImpact: (json['performanceImpact'] as num).toDouble(),
      weatherFactors: List<String>.from(json['weatherFactors'] as List),
      metricImpacts: Map<String, double>.from(json['metricImpacts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'weatherConditions': weatherConditions,
      'performanceImpact': performanceImpact,
      'weatherFactors': weatherFactors,
      'metricImpacts': metricImpacts,
    };
  }
}

class CoverageAnalysis {
  final String operationId;
  final double totalFieldArea;
  final double coveredArea;
  final double coveragePercentage;
  final double overlapPercentage;
  final double skippedPercentage;
  final List<GPSPoint> uncoveredAreas;
  final double efficiencyScore;

  CoverageAnalysis({
    required this.operationId,
    required this.totalFieldArea,
    required this.coveredArea,
    required this.coveragePercentage,
    required this.overlapPercentage,
    required this.skippedPercentage,
    required this.uncoveredAreas,
    required this.efficiencyScore,
  });

  factory CoverageAnalysis.fromJson(Map<String, dynamic> json) {
    return CoverageAnalysis(
      operationId: json['operationId'] as String,
      totalFieldArea: (json['totalFieldArea'] as num).toDouble(),
      coveredArea: (json['coveredArea'] as num).toDouble(),
      coveragePercentage: (json['coveragePercentage'] as num).toDouble(),
      overlapPercentage: (json['overlapPercentage'] as num).toDouble(),
      skippedPercentage: (json['skippedPercentage'] as num).toDouble(),
      uncoveredAreas: (json['uncoveredAreas'] as List)
          .map((e) => GPSPoint.fromJson(e))
          .toList(),
      efficiencyScore: (json['efficiencyScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'totalFieldArea': totalFieldArea,
      'coveredArea': coveredArea,
      'coveragePercentage': coveragePercentage,
      'overlapPercentage': overlapPercentage,
      'skippedPercentage': skippedPercentage,
      'uncoveredAreas': uncoveredAreas.map((e) => e.toJson()).toList(),
      'efficiencyScore': efficiencyScore,
    };
  }
}

/// Settings-related data classes

class CombineSettingsProfile extends BaseDocument {
  final String userCombineId;
  final String crop;
  final String profileName;
  final Map<String, dynamic> settings;
  final Map<String, dynamic>? conditions;
  final bool isDefault;
  final double effectivenessScore;
  final int usageCount;
  final DateTime? lastUsed;

  CombineSettingsProfile({
    required String id,
    required this.userCombineId,
    required this.crop,
    required this.profileName,
    required this.settings,
    this.conditions,
    required this.isDefault,
    required this.effectivenessScore,
    required this.usageCount,
    this.lastUsed,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CombineSettingsProfile.fromJson(Map<String, dynamic> json) {
    return CombineSettingsProfile(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      profileName: json['profileName'] as String,
      settings: Map<String, dynamic>.from(json['settings']),
      conditions: json['conditions'] != null
          ? Map<String, dynamic>.from(json['conditions'])
          : null,
      isDefault: json['isDefault'] as bool,
      effectivenessScore: (json['effectivenessScore'] as num).toDouble(),
      usageCount: json['usageCount'] as int,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'crop': crop,
      'profileName': profileName,
      'settings': settings,
      'conditions': conditions,
      'isDefault': isDefault,
      'effectivenessScore': effectivenessScore,
      'usageCount': usageCount,
      'lastUsed': lastUsed?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OptimalSettings {
  final String combineSpecId;
  final String crop;
  final Map<String, dynamic> optimalSettings;
  final Map<String, double> confidenceScores;
  final Map<String, dynamic> conditions;
  final List<String> reasoning;
  final DateTime generatedAt;

  OptimalSettings({
    required this.combineSpecId,
    required this.crop,
    required this.optimalSettings,
    required this.confidenceScores,
    required this.conditions,
    required this.reasoning,
    required this.generatedAt,
  });

  factory OptimalSettings.fromJson(Map<String, dynamic> json) {
    return OptimalSettings(
      combineSpecId: json['combineSpecId'] as String,
      crop: json['crop'] as String,
      optimalSettings: Map<String, dynamic>.from(json['optimalSettings']),
      confidenceScores: Map<String, double>.from(json['confidenceScores']),
      conditions: Map<String, dynamic>.from(json['conditions']),
      reasoning: List<String>.from(json['reasoning'] as List),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'crop': crop,
      'optimalSettings': optimalSettings,
      'confidenceScores': confidenceScores,
      'conditions': conditions,
      'reasoning': reasoning,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

class SettingsUsageRecord extends BaseDocument {
  final String profileId;
  final String userCombineId;
  final DateTime usageDate;
  final double operationTime;
  final double areaHarvested;
  final Map<String, double> performanceResults;
  final Map<String, dynamic>? conditions;
  final String? operatorFeedback;

  SettingsUsageRecord({
    required String id,
    required this.profileId,
    required this.userCombineId,
    required this.usageDate,
    required this.operationTime,
    required this.areaHarvested,
    required this.performanceResults,
    this.conditions,
    this.operatorFeedback,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory SettingsUsageRecord.fromJson(Map<String, dynamic> json) {
    return SettingsUsageRecord(
      id: json['id'] as String,
      profileId: json['profileId'] as String,
      userCombineId: json['userCombineId'] as String,
      usageDate: DateTime.parse(json['usageDate'] as String),
      operationTime: (json['operationTime'] as num).toDouble(),
      areaHarvested: (json['areaHarvested'] as num).toDouble(),
      performanceResults: Map<String, double>.from(json['performanceResults']),
      conditions: json['conditions'] != null
          ? Map<String, dynamic>.from(json['conditions'])
          : null,
      operatorFeedback: json['operatorFeedback'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'userCombineId': userCombineId,
      'usageDate': usageDate.toIso8601String(),
      'operationTime': operationTime,
      'areaHarvested': areaHarvested,
      'performanceResults': performanceResults,
      'conditions': conditions,
      'operatorFeedback': operatorFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class SettingsEffectiveness {
  final String profileId;
  final double overallEffectiveness;
  final Map<String, double> metricEffectiveness;
  final int totalUsages;
  final double averagePerformance;
  final double improvementOverBaseline;
  final DateTime analysisDate;

  SettingsEffectiveness({
    required this.profileId,
    required this.overallEffectiveness,
    required this.metricEffectiveness,
    required this.totalUsages,
    required this.averagePerformance,
    required this.improvementOverBaseline,
    required this.analysisDate,
  });

  factory SettingsEffectiveness.fromJson(Map<String, dynamic> json) {
    return SettingsEffectiveness(
      profileId: json['profileId'] as String,
      overallEffectiveness: (json['overallEffectiveness'] as num).toDouble(),
      metricEffectiveness: Map<String, double>.from(json['metricEffectiveness']),
      totalUsages: json['totalUsages'] as int,
      averagePerformance: (json['averagePerformance'] as num).toDouble(),
      improvementOverBaseline: (json['improvementOverBaseline'] as num).toDouble(),
      analysisDate: DateTime.parse(json['analysisDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'overallEffectiveness': overallEffectiveness,
      'metricEffectiveness': metricEffectiveness,
      'totalUsages': totalUsages,
      'averagePerformance': averagePerformance,
      'improvementOverBaseline': improvementOverBaseline,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

class CommunitySettingsRecommendation {
  final String combineSpecId;
  final String crop;
  final String region;
  final Map<String, dynamic> recommendedSettings;
  final double communityRating;
  final int totalVotes;
  final Map<String, dynamic> expectedPerformance;
  final List<String> tags;
  final DateTime lastUpdated;

  CommunitySettingsRecommendation({
    required this.combineSpecId,
    required this.crop,
    required this.region,
    required this.recommendedSettings,
    required this.communityRating,
    required this.totalVotes,
    required this.expectedPerformance,
    required this.tags,
    required this.lastUpdated,
  });

  factory CommunitySettingsRecommendation.fromJson(Map<String, dynamic> json) {
    return CommunitySettingsRecommendation(
      combineSpecId: json['combineSpecId'] as String,
      crop: json['crop'] as String,
      region: json['region'] as String,
      recommendedSettings: Map<String, dynamic>.from(json['recommendedSettings']),
      communityRating: (json['communityRating'] as num).toDouble(),
      totalVotes: json['totalVotes'] as int,
      expectedPerformance: Map<String, dynamic>.from(json['expectedPerformance']),
      tags: List<String>.from(json['tags'] as List),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'crop': crop,
      'region': region,
      'recommendedSettings': recommendedSettings,
      'communityRating': communityRating,
      'totalVotes': totalVotes,
      'expectedPerformance': expectedPerformance,
      'tags': tags,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}