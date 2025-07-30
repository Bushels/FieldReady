/**
 * Repository interface for capability learning operations
 * Handles machine learning for combine capabilities, adaptive optimization,
 * and continuous improvement of recommendations
 * Supports offline-first architecture with clean separation of concerns
 */

import '../models/combine_models.dart';

/// Repository interface for learning combine capabilities from data
abstract class CapabilityLearningRepository {
  /// Record learning data point for capability improvement
  Future<String> recordLearningPoint(CapabilityLearningPoint point);
  
  /// Get learning data for a specific combine spec
  Future<List<CapabilityLearningPoint>> getLearningData(
    String combineSpecId, {
    String? crop,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  /// Update capability estimates based on new data
  Future<CapabilityUpdate> updateCapabilities(
    String combineSpecId,
    List<CapabilityLearningPoint> newData,
  );
  
  /// Get capability confidence scores
  Future<CapabilityConfidence> getCapabilityConfidence(String combineSpecId);
  
  /// Learn from user corrections and feedback
  Future<void> learnFromCorrection(CapabilityCorrection correction);
  
  /// Get adaptive recommendations based on learning
  Future<AdaptiveRecommendation> getAdaptiveRecommendation(
    String combineSpecId,
    String crop,
    Map<String, dynamic> conditions,
  );
  
  /// Record recommendation effectiveness feedback
  Future<void> recordRecommendationFeedback(RecommendationFeedback feedback);
  
  /// Get learning model statistics
  Future<LearningModelStats> getModelStats(String combineSpecId);
  
  /// Trigger model retraining
  Future<ModelTrainingResult> retrainModel(
    String combineSpecId, {
    bool forceRetrain = false,
  });
  
  /// Get feature importance for capability predictions
  Future<Map<String, double>> getFeatureImportance(String combineSpecId);
  
  /// Export learning data for analysis
  Future<List<Map<String, dynamic>>> exportLearningData(
    String combineSpecId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Import learning data from external source
  Future<ImportResult> importLearningData(
    String combineSpecId,
    List<Map<String, dynamic>> data,
    String source,
  );
  
  /// Get learning trends over time
  Future<List<LearningTrend>> getLearningTrends(
    String combineSpecId,
    String metric,
    {DateTime? startDate, DateTime? endDate}
  );
  
  /// Get comparative learning across similar combines
  Future<ComparativeLearning> getComparativeLearning(
    String combineSpecId,
    String region,
  );
  
  /// Reset learning model (use with caution)
  Future<void> resetLearningModel(String combineSpecId);
  
  /// Get pending learning data for sync
  Future<List<CapabilityLearningPoint>> getPendingSync(String userId);
  
  /// Mark learning data as synchronized
  Future<void> markSynced(String learningPointId, DateTime syncedAt);
}

/// Repository interface for pattern recognition and anomaly detection
abstract class PatternRecognitionRepository {
  /// Detect patterns in combine performance data
  Future<List<PerformancePattern>> detectPatterns(
    String userCombineId, {
    String? crop,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Detect anomalies in performance data
  Future<List<PerformanceAnomaly>> detectAnomalies(
    String userCombineId,
    List<Map<String, dynamic>> performanceData,
  );
  
  /// Get pattern-based recommendations
  Future<List<PatternRecommendation>> getPatternRecommendations(
    String userCombineId,
    String currentContext,
  );
  
  /// Record pattern validation from user
  Future<void> validatePattern(String patternId, bool isValid, String? feedback);
  
  /// Get pattern confidence scores
  Future<Map<String, double>> getPatternConfidence(String userCombineId);
  
  /// Learn from pattern feedback
  Future<void> updatePatternModel(
    String patternId,
    Map<String, dynamic> validationData,
  );
  
  /// Get seasonal patterns
  Future<List<SeasonalPattern>> getSeasonalPatterns(
    String region,
    String crop,
    {int? year}
  );
  
  /// Detect maintenance patterns
  Future<List<MaintenancePattern>> detectMaintenancePatterns(
    String userCombineId,
  );
  
  /// Get predictive maintenance recommendations
  Future<List<PredictiveMaintenance>> getPredictiveMaintenanceAlerts(
    String userCombineId,
  );
  
  /// Record maintenance outcome for learning
  Future<void> recordMaintenanceOutcome(MaintenanceOutcome outcome);
}

/// Repository interface for adaptive optimization algorithms
abstract class AdaptiveOptimizationRepository {
  /// Initialize optimization for a combine
  Future<String> initializeOptimization(OptimizationConfig config);
  
  /// Update optimization parameters based on performance
  Future<void> updateOptimization(
    String optimizationId,
    Map<String, double> performanceMetrics,
  );
  
  /// Get next optimization suggestions
  Future<OptimizationSuggestion> getOptimizationSuggestion(
    String optimizationId,
    Map<String, dynamic> currentConditions,
  );
  
  /// Record optimization results
  Future<void> recordOptimizationResult(OptimizationResult result);
  
  /// Get optimization history
  Future<List<OptimizationHistory>> getOptimizationHistory(
    String optimizationId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Get optimization convergence data
  Future<ConvergenceData> getConvergenceData(String optimizationId);
  
  /// Reset optimization (restart learning)
  Future<void> resetOptimization(String optimizationId);
  
  /// Get multi-objective optimization results
  Future<MultiObjectiveResults> getMultiObjectiveOptimization(
    String optimizationId,
    List<String> objectives,
    Map<String, double> weights,
  );
  
  /// Export optimization data
  Future<Map<String, dynamic>> exportOptimizationData(String optimizationId);
  
  /// Clone optimization configuration
  Future<String> cloneOptimization(
    String sourceOptimizationId,
    String targetUserCombineId,
  );
}

/// Repository interface for knowledge base and expert systems
abstract class KnowledgeBaseRepository {
  /// Add expert knowledge rule
  Future<String> addKnowledgeRule(KnowledgeRule rule);
  
  /// Get applicable knowledge rules
  Future<List<KnowledgeRule>> getApplicableRules(
    String combineSpecId,
    String crop,
    Map<String, dynamic> conditions,
  );
  
  /// Update rule based on effectiveness
  Future<void> updateRuleEffectiveness(
    String ruleId,
    double effectiveness,
    Map<String, dynamic> context,
  );
  
  /// Get expert recommendations
  Future<List<ExpertRecommendation>> getExpertRecommendations(
    String combineSpecId,
    String crop,
    String problemContext,
  );
  
  /// Record expert knowledge validation
  Future<void> validateExpertKnowledge(
    String ruleId,
    bool isValid,
    String? feedback,
    String validatorId,
  );
  
  /// Get knowledge conflicts
  Future<List<KnowledgeConflict>> getKnowledgeConflicts();
  
  /// Resolve knowledge conflict
  Future<void> resolveKnowledgeConflict(
    String conflictId,
    String resolution,
    String resolverId,
  });
  
  /// Learn from field data to create new rules
  Future<List<String>> generateRulesFromData(
    List<Map<String, dynamic>> fieldData,
    double minConfidence,
  );
  
  /// Get rule effectiveness statistics
  Future<RuleEffectivenessStats> getRuleStats(String ruleId);
  
  /// Retire ineffective rules
  Future<void> retireRule(String ruleId, String reason);
  
  /// Get knowledge base coverage
  Future<KnowledgeCoverage> getKnowledgeCoverage(
    String combineSpecId,
    String crop,
  );
  
  /// Import expert knowledge from external source
  Future<ImportResult> importKnowledge(
    List<Map<String, dynamic>> knowledgeData,
    String source,
    String importerId,
  });
}

/// Supporting data classes for capability learning

class CapabilityLearningPoint extends BaseDocument {
  final String combineSpecId;
  final String userCombineId;
  final String crop;
  final Map<String, dynamic> inputConditions;
  final Map<String, dynamic> combineSettings;
  final Map<String, double> performanceResults;
  final double moistureLevel;
  final double fieldDifficulty;
  final Map<String, dynamic> weatherConditions;
  final double operatorExperience;
  final String? operatorFeedback;
  final ConfidenceLevel dataQuality;
  final List<String>? tags;
  final bool isValidated;
  final DateTime? syncedAt;

  CapabilityLearningPoint({
    required String id,
    required this.combineSpecId,
    required this.userCombineId,
    required this.crop,
    required this.inputConditions,
    required this.combineSettings,
    required this.performanceResults,
    required this.moistureLevel,
    required this.fieldDifficulty,
    required this.weatherConditions,
    required this.operatorExperience,
    this.operatorFeedback,
    required this.dataQuality,
    this.tags,
    required this.isValidated,
    this.syncedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CapabilityLearningPoint.fromJson(Map<String, dynamic> json) {
    return CapabilityLearningPoint(
      id: json['id'] as String,
      combineSpecId: json['combineSpecId'] as String,
      userCombineId: json['userCombineId'] as String,
      crop: json['crop'] as String,
      inputConditions: Map<String, dynamic>.from(json['inputConditions']),
      combineSettings: Map<String, dynamic>.from(json['combineSettings']),
      performanceResults: Map<String, double>.from(json['performanceResults']),
      moistureLevel: (json['moistureLevel'] as num).toDouble(),
      fieldDifficulty: (json['fieldDifficulty'] as num).toDouble(),
      weatherConditions: Map<String, dynamic>.from(json['weatherConditions']),
      operatorExperience: (json['operatorExperience'] as num).toDouble(),
      operatorFeedback: json['operatorFeedback'] as String?,
      dataQuality: ConfidenceLevel.values.firstWhere(
        (e) => e.name == json['dataQuality'],
        orElse: () => ConfidenceLevel.medium,
      ),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
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
      'combineSpecId': combineSpecId,
      'userCombineId': userCombineId,
      'crop': crop,
      'inputConditions': inputConditions,
      'combineSettings': combineSettings,
      'performanceResults': performanceResults,
      'moistureLevel': moistureLevel,
      'fieldDifficulty': fieldDifficulty,
      'weatherConditions': weatherConditions,
      'operatorExperience': operatorExperience,
      'operatorFeedback': operatorFeedback,
      'dataQuality': dataQuality.name,
      'tags': tags,
      'isValidated': isValidated,
      'syncedAt': syncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CapabilityUpdate {
  final String combineSpecId;
  final Map<String, double> previousCapabilities;
  final Map<String, double> updatedCapabilities;
  final Map<String, double> confidenceChanges;
  final List<String> significantChanges;
  final int dataPointsUsed;
  final DateTime updateTime;
  final String updateReason;

  CapabilityUpdate({
    required this.combineSpecId,
    required this.previousCapabilities,
    required this.updatedCapabilities,
    required this.confidenceChanges,
    required this.significantChanges,
    required this.dataPointsUsed,
    required this.updateTime,
    required this.updateReason,
  });

  factory CapabilityUpdate.fromJson(Map<String, dynamic> json) {
    return CapabilityUpdate(
      combineSpecId: json['combineSpecId'] as String,
      previousCapabilities: Map<String, double>.from(json['previousCapabilities']),
      updatedCapabilities: Map<String, double>.from(json['updatedCapabilities']),
      confidenceChanges: Map<String, double>.from(json['confidenceChanges']),
      significantChanges: List<String>.from(json['significantChanges'] as List),
      dataPointsUsed: json['dataPointsUsed'] as int,
      updateTime: DateTime.parse(json['updateTime'] as String),
      updateReason: json['updateReason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'previousCapabilities': previousCapabilities,
      'updatedCapabilities': updatedCapabilities,
      'confidenceChanges': confidenceChanges,
      'significantChanges': significantChanges,
      'dataPointsUsed': dataPointsUsed,
      'updateTime': updateTime.toIso8601String(),
      'updateReason': updateReason,
    };
  }
}

class CapabilityConfidence {
  final String combineSpecId;
  final Map<String, double> capabilityScores;
  final Map<String, ConfidenceLevel> confidenceLevels;
  final Map<String, int> dataPointCounts;
  final Map<String, DateTime> lastUpdated;
  final double overallConfidence;
  final List<String> uncertainAreas;

  CapabilityConfidence({
    required this.combineSpecId,
    required this.capabilityScores,
    required this.confidenceLevels,
    required this.dataPointCounts,
    required this.lastUpdated,
    required this.overallConfidence,
    required this.uncertainAreas,
  });

  factory CapabilityConfidence.fromJson(Map<String, dynamic> json) {
    return CapabilityConfidence(
      combineSpecId: json['combineSpecId'] as String,
      capabilityScores: Map<String, double>.from(json['capabilityScores']),
      confidenceLevels: Map<String, ConfidenceLevel>.from(
        json['confidenceLevels'].map((k, v) => MapEntry(
          k as String,
          ConfidenceLevel.values.firstWhere(
            (e) => e.name == v,
            orElse: () => ConfidenceLevel.medium,
          ),
        )),
      ),
      dataPointCounts: Map<String, int>.from(json['dataPointCounts']),
      lastUpdated: Map<String, DateTime>.from(
        json['lastUpdated'].map((k, v) => MapEntry(
          k as String,
          DateTime.parse(v as String),
        )),
      ),
      overallConfidence: (json['overallConfidence'] as num).toDouble(),
      uncertainAreas: List<String>.from(json['uncertainAreas'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'capabilityScores': capabilityScores,
      'confidenceLevels': confidenceLevels.map((k, v) => MapEntry(k, v.name)),
      'dataPointCounts': dataPointCounts,
      'lastUpdated': lastUpdated.map((k, v) => MapEntry(k, v.toIso8601String())),
      'overallConfidence': overallConfidence,
      'uncertainAreas': uncertainAreas,
    };
  }
}

class CapabilityCorrection extends BaseDocument {
  final String combineSpecId;
  final String userId;
  final String capability;
  final double originalValue;
  final double correctedValue;
  final String correctionReason;
  final Map<String, dynamic>? context;
  final ConfidenceLevel userConfidence;
  final bool isExpertCorrection;

  CapabilityCorrection({
    required String id,
    required this.combineSpecId,
    required this.userId,
    required this.capability,
    required this.originalValue,
    required this.correctedValue,
    required this.correctionReason,
    this.context,
    required this.userConfidence,
    required this.isExpertCorrection,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CapabilityCorrection.fromJson(Map<String, dynamic> json) {
    return CapabilityCorrection(
      id: json['id'] as String,
      combineSpecId: json['combineSpecId'] as String,
      userId: json['userId'] as String,
      capability: json['capability'] as String,
      originalValue: (json['originalValue'] as num).toDouble(),
      correctedValue: (json['correctedValue'] as num).toDouble(),
      correctionReason: json['correctionReason'] as String,
      context: json['context'] != null
          ? Map<String, dynamic>.from(json['context'])
          : null,
      userConfidence: ConfidenceLevel.values.firstWhere(
        (e) => e.name == json['userConfidence'],
        orElse: () => ConfidenceLevel.medium,
      ),
      isExpertCorrection: json['isExpertCorrection'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combineSpecId': combineSpecId,
      'userId': userId,
      'capability': capability,
      'originalValue': originalValue,
      'correctedValue': correctedValue,
      'correctionReason': correctionReason,
      'context': context,
      'userConfidence': userConfidence.name,
      'isExpertCorrection': isExpertCorrection,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class AdaptiveRecommendation {
  final String combineSpecId;
  final String crop;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> recommendedSettings;
  final Map<String, double> expectedPerformance;
  final double confidenceScore;
  final List<String> adaptationReasons;
  final Map<String, dynamic> alternativeOptions;
  final DateTime generatedAt;
  final String modelVersion;

  AdaptiveRecommendation({
    required this.combineSpecId,
    required this.crop,
    required this.conditions,
    required this.recommendedSettings,
    required this.expectedPerformance,
    required this.confidenceScore,
    required this.adaptationReasons,
    required this.alternativeOptions,
    required this.generatedAt,
    required this.modelVersion,
  });

  factory AdaptiveRecommendation.fromJson(Map<String, dynamic> json) {
    return AdaptiveRecommendation(
      combineSpecId: json['combineSpecId'] as String,
      crop: json['crop'] as String,
      conditions: Map<String, dynamic>.from(json['conditions']),
      recommendedSettings: Map<String, dynamic>.from(json['recommendedSettings']),
      expectedPerformance: Map<String, double>.from(json['expectedPerformance']),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      adaptationReasons: List<String>.from(json['adaptationReasons'] as List),
      alternativeOptions: Map<String, dynamic>.from(json['alternativeOptions']),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      modelVersion: json['modelVersion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'crop': crop,
      'conditions': conditions,
      'recommendedSettings': recommendedSettings,
      'expectedPerformance': expectedPerformance,
      'confidenceScore': confidenceScore,
      'adaptationReasons': adaptationReasons,
      'alternativeOptions': alternativeOptions,
      'generatedAt': generatedAt.toIso8601String(),
      'modelVersion': modelVersion,
    };
  }
}

class RecommendationFeedback extends BaseDocument {
  final String recommendationId;
  final String userId;
  final double effectivenessRating;
  final Map<String, double>? actualPerformance;
  final bool wasFollowed;
  final String? userComments;
  final Map<String, dynamic>? actualConditions;
  final List<String>? issues;
  final bool wouldRecommendToOthers;

  RecommendationFeedback({
    required String id,
    required this.recommendationId,
    required this.userId,
    required this.effectivenessRating,
    this.actualPerformance,
    required this.wasFollowed,
    this.userComments,
    this.actualConditions,
    this.issues,
    required this.wouldRecommendToOthers,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory RecommendationFeedback.fromJson(Map<String, dynamic> json) {
    return RecommendationFeedback(
      id: json['id'] as String,
      recommendationId: json['recommendationId'] as String,
      userId: json['userId'] as String,
      effectivenessRating: (json['effectivenessRating'] as num).toDouble(),
      actualPerformance: json['actualPerformance'] != null
          ? Map<String, double>.from(json['actualPerformance'])
          : null,
      wasFollowed: json['wasFollowed'] as bool,
      userComments: json['userComments'] as String?,
      actualConditions: json['actualConditions'] != null
          ? Map<String, dynamic>.from(json['actualConditions'])
          : null,
      issues: json['issues'] != null
          ? List<String>.from(json['issues'] as List)
          : null,
      wouldRecommendToOthers: json['wouldRecommendToOthers'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recommendationId': recommendationId,
      'userId': userId,
      'effectivenessRating': effectivenessRating,
      'actualPerformance': actualPerformance,
      'wasFollowed': wasFollowed,
      'userComments': userComments,
      'actualConditions': actualConditions,
      'issues': issues,
      'wouldRecommendToOthers': wouldRecommendToOthers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LearningModelStats {
  final String combineSpecId;
  final String modelVersion;
  final int totalDataPoints;
  final Map<String, int> dataPointsByCrop;
  final double modelAccuracy;
  final double modelPrecision;
  final double modelRecall;
  final DateTime lastTraining;
  final DateTime? nextScheduledTraining;
  final Map<String, double> featureImportance;
  final List<String> modelWarnings;

  LearningModelStats({
    required this.combineSpecId,
    required this.modelVersion,
    required this.totalDataPoints,
    required this.dataPointsByCrop,
    required this.modelAccuracy,
    required this.modelPrecision,
    required this.modelRecall,
    required this.lastTraining,
    this.nextScheduledTraining,
    required this.featureImportance,
    required this.modelWarnings,
  });

  factory LearningModelStats.fromJson(Map<String, dynamic> json) {
    return LearningModelStats(
      combineSpecId: json['combineSpecId'] as String,
      modelVersion: json['modelVersion'] as String,
      totalDataPoints: json['totalDataPoints'] as int,
      dataPointsByCrop: Map<String, int>.from(json['dataPointsByCrop']),
      modelAccuracy: (json['modelAccuracy'] as num).toDouble(),
      modelPrecision: (json['modelPrecision'] as num).toDouble(),
      modelRecall: (json['modelRecall'] as num).toDouble(),
      lastTraining: DateTime.parse(json['lastTraining'] as String),
      nextScheduledTraining: json['nextScheduledTraining'] != null
          ? DateTime.parse(json['nextScheduledTraining'] as String)
          : null,
      featureImportance: Map<String, double>.from(json['featureImportance']),
      modelWarnings: List<String>.from(json['modelWarnings'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'modelVersion': modelVersion,
      'totalDataPoints': totalDataPoints,
      'dataPointsByCrop': dataPointsByCrop,
      'modelAccuracy': modelAccuracy,
      'modelPrecision': modelPrecision,
      'modelRecall': modelRecall,
      'lastTraining': lastTraining.toIso8601String(),
      'nextScheduledTraining': nextScheduledTraining?.toIso8601String(),
      'featureImportance': featureImportance,
      'modelWarnings': modelWarnings,
    };
  }
}

class ModelTrainingResult {
  final String combineSpecId;
  final String previousModelVersion;
  final String newModelVersion;
  final bool trainingSuccessful;
  final double improvementScore;
  final Map<String, double> performanceMetrics;
  final int dataPointsUsed;
  final Duration trainingTime;
  final List<String> trainingNotes;
  final DateTime completedAt;

  ModelTrainingResult({
    required this.combineSpecId,
    required this.previousModelVersion,
    required this.newModelVersion,
    required this.trainingSuccessful,
    required this.improvementScore,
    required this.performanceMetrics,
    required this.dataPointsUsed,
    required this.trainingTime,
    required this.trainingNotes,
    required this.completedAt,
  });

  factory ModelTrainingResult.fromJson(Map<String, dynamic> json) {
    return ModelTrainingResult(
      combineSpecId: json['combineSpecId'] as String,
      previousModelVersion: json['previousModelVersion'] as String,
      newModelVersion: json['newModelVersion'] as String,
      trainingSuccessful: json['trainingSuccessful'] as bool,
      improvementScore: (json['improvementScore'] as num).toDouble(),
      performanceMetrics: Map<String, double>.from(json['performanceMetrics']),
      dataPointsUsed: json['dataPointsUsed'] as int,
      trainingTime: Duration(milliseconds: json['trainingTimeMs'] as int),
      trainingNotes: List<String>.from(json['trainingNotes'] as List),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'previousModelVersion': previousModelVersion,
      'newModelVersion': newModelVersion,
      'trainingSuccessful': trainingSuccessful,
      'improvementScore': improvementScore,
      'performanceMetrics': performanceMetrics,
      'dataPointsUsed': dataPointsUsed,
      'trainingTimeMs': trainingTime.inMilliseconds,
      'trainingNotes': trainingNotes,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class ImportResult {
  final bool successful;
  final int recordsProcessed;
  final int recordsImported;
  final int recordsSkipped;
  final List<String> errors;
  final List<String> warnings;
  final DateTime importedAt;
  final String importId;

  ImportResult({
    required this.successful,
    required this.recordsProcessed,
    required this.recordsImported,
    required this.recordsSkipped,
    required this.errors,
    required this.warnings,
    required this.importedAt,
    required this.importId,
  });

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      successful: json['successful'] as bool,
      recordsProcessed: json['recordsProcessed'] as int,
      recordsImported: json['recordsImported'] as int,
      recordsSkipped: json['recordsSkipped'] as int,
      errors: List<String>.from(json['errors'] as List),
      warnings: List<String>.from(json['warnings'] as List),
      importedAt: DateTime.parse(json['importedAt'] as String),
      importId: json['importId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'successful': successful,
      'recordsProcessed': recordsProcessed,
      'recordsImported': recordsImported,
      'recordsSkipped': recordsSkipped,
      'errors': errors,
      'warnings': warnings,
      'importedAt': importedAt.toIso8601String(),
      'importId': importId,
    };
  }
}

class LearningTrend {
  final DateTime date;
  final String metric;
  final double value;
  final double confidence;
  final double trendDirection;
  final String? annotation;

  LearningTrend({
    required this.date,
    required this.metric,
    required this.value,
    required this.confidence,
    required this.trendDirection,
    this.annotation,
  });

  factory LearningTrend.fromJson(Map<String, dynamic> json) {
    return LearningTrend(
      date: DateTime.parse(json['date'] as String),
      metric: json['metric'] as String,
      value: (json['value'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      trendDirection: (json['trendDirection'] as num).toDouble(),
      annotation: json['annotation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'metric': metric,
      'value': value,
      'confidence': confidence,
      'trendDirection': trendDirection,
      'annotation': annotation,
    };
  }
}

class ComparativeLearning {
  final String combineSpecId;
  final String region;
  final int peerCount;
  final Map<String, double> averageCapabilities;
  final Map<String, double> myCapabilities;
  final Map<String, String> comparativeRanking;
  final List<String> improvementAreas;
  final List<String> strengthAreas;
  final DateTime analysisDate;

  ComparativeLearning({
    required this.combineSpecId,
    required this.region,
    required this.peerCount,
    required this.averageCapabilities,
    required this.myCapabilities,
    required this.comparativeRanking,
    required this.improvementAreas,
    required this.strengthAreas,
    required this.analysisDate,
  });

  factory ComparativeLearning.fromJson(Map<String, dynamic> json) {
    return ComparativeLearning(
      combineSpecId: json['combineSpecId'] as String,
      region: json['region'] as String,
      peerCount: json['peerCount'] as int,
      averageCapabilities: Map<String, double>.from(json['averageCapabilities']),
      myCapabilities: Map<String, double>.from(json['myCapabilities']),
      comparativeRanking: Map<String, String>.from(json['comparativeRanking']),
      improvementAreas: List<String>.from(json['improvementAreas'] as List),
      strengthAreas: List<String>.from(json['strengthAreas'] as List),
      analysisDate: DateTime.parse(json['analysisDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'region': region,
      'peerCount': peerCount,
      'averageCapabilities': averageCapabilities,
      'myCapabilities': myCapabilities,
      'comparativeRanking': comparativeRanking,
      'improvementAreas': improvementAreas,
      'strengthAreas': strengthAreas,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

/// Pattern recognition data classes

class PerformancePattern extends BaseDocument {
  final String userCombineId;
  final String patternType; // 'seasonal', 'hourly', 'weather_dependent', etc.
  final String description;
  final Map<String, dynamic> patternData;
  final double confidence;
  final double impact; // Impact on performance (-1 to 1)
  final List<String> conditions;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool isValidated;
  final String? userFeedback;

  PerformancePattern({
    required String id,
    required this.userCombineId,
    required this.patternType,
    required this.description,
    required this.patternData,
    required this.confidence,
    required this.impact,
    required this.conditions,
    this.validFrom,
    this.validTo,
    required this.isValidated,
    this.userFeedback,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory PerformancePattern.fromJson(Map<String, dynamic> json) {
    return PerformancePattern(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      patternType: json['patternType'] as String,
      description: json['description'] as String,
      patternData: Map<String, dynamic>.from(json['patternData']),
      confidence: (json['confidence'] as num).toDouble(),
      impact: (json['impact'] as num).toDouble(),
      conditions: List<String>.from(json['conditions'] as List),
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : null,
      validTo: json['validTo'] != null
          ? DateTime.parse(json['validTo'] as String)
          : null,
      isValidated: json['isValidated'] as bool,
      userFeedback: json['userFeedback'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'patternType': patternType,
      'description': description,
      'patternData': patternData,
      'confidence': confidence,
      'impact': impact,
      'conditions': conditions,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
      'isValidated': isValidated,
      'userFeedback': userFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PerformanceAnomaly extends BaseDocument {
  final String userCombineId;
  final String anomalyType; // 'performance_drop', 'unusual_consumption', etc.
  final Map<String, dynamic> anomalyData;
  final double severity; // 0-10 scale
  final double confidence;
  final List<String> possibleCauses;
  final List<String> recommendedActions;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolution;

  PerformanceAnomaly({
    required String id,
    required this.userCombineId,
    required this.anomalyType,
    required this.anomalyData,
    required this.severity,
    required this.confidence,
    required this.possibleCauses,
    required this.recommendedActions,
    required this.isResolved,
    this.resolvedAt,
    this.resolution,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory PerformanceAnomaly.fromJson(Map<String, dynamic> json) {
    return PerformanceAnomaly(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      anomalyType: json['anomalyType'] as String,
      anomalyData: Map<String, dynamic>.from(json['anomalyData']),
      severity: (json['severity'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      possibleCauses: List<String>.from(json['possibleCauses'] as List),
      recommendedActions: List<String>.from(json['recommendedActions'] as List),
      isResolved: json['isResolved'] as bool,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolution: json['resolution'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCombineId': userCombineId,
      'anomalyType': anomalyType,
      'anomalyData': anomalyData,
      'severity': severity,
      'confidence': confidence,
      'possibleCauses': possibleCauses,
      'recommendedActions': recommendedActions,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PatternRecommendation {
  final String patternId;
  final String recommendationType;
  final String description;
  final Map<String, dynamic> recommendedAction;
  final double confidence;
  final double expectedImprovement;
  final List<String> prerequisites;
  final DateTime validUntil;

  PatternRecommendation({
    required this.patternId,
    required this.recommendationType,
    required this.description,
    required this.recommendedAction,
    required this.confidence,
    required this.expectedImprovement,
    required this.prerequisites,
    required this.validUntil,
  });

  factory PatternRecommendation.fromJson(Map<String, dynamic> json) {
    return PatternRecommendation(
      patternId: json['patternId'] as String,
      recommendationType: json['recommendationType'] as String,
      description: json['description'] as String,
      recommendedAction: Map<String, dynamic>.from(json['recommendedAction']),
      confidence: (json['confidence'] as num).toDouble(),
      expectedImprovement: (json['expectedImprovement'] as num).toDouble(),
      prerequisites: List<String>.from(json['prerequisites'] as List),
      validUntil: DateTime.parse(json['validUntil'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'recommendationType': recommendationType,
      'description': description,
      'recommendedAction': recommendedAction,
      'confidence': confidence,
      'expectedImprovement': expectedImprovement,
      'prerequisites': prerequisites,
      'validUntil': validUntil.toIso8601String(),
    };
  }
}

class SeasonalPattern {
  final String region;
  final String crop;
  final int year;
  final Map<String, double> monthlyPerformance;
  final Map<String, String> seasonalTrends;
  final List<String> keyInsights;
  final DateTime analysisDate;

  SeasonalPattern({
    required this.region,
    required this.crop,
    required this.year,
    required this.monthlyPerformance,
    required this.seasonalTrends,
    required this.keyInsights,
    required this.analysisDate,
  });

  factory SeasonalPattern.fromJson(Map<String, dynamic> json) {
    return SeasonalPattern(
      region: json['region'] as String,
      crop: json['crop'] as String,
      year: json['year'] as int,
      monthlyPerformance: Map<String, double>.from(json['monthlyPerformance']),
      seasonalTrends: Map<String, String>.from(json['seasonalTrends']),
      keyInsights: List<String>.from(json['keyInsights'] as List),
      analysisDate: DateTime.parse(json['analysisDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'crop': crop,
      'year': year,
      'monthlyPerformance': monthlyPerformance,
      'seasonalTrends': seasonalTrends,
      'keyInsights': keyInsights,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}

class MaintenancePattern extends BaseDocument {
  final String userCombineId;
  final String maintenanceType;
  final double averageInterval; // hours between maintenance
  final double predictedNextInterval;
  final double confidence;
  final List<String> triggerFactors;
  final Map<String, double> performanceImpact;
  final DateTime? nextPredictedDate;

  MaintenancePattern({
    required String id,
    required this.userCombineId,
    required this.maintenanceType,
    required this.averageInterval,
    required this.predictedNextInterval,
    required this.confidence,
    required this.triggerFactors,
    required this.performanceImpact,
    this.nextPredictedDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory MaintenancePattern.fromJson(Map<String, dynamic> json) {
    return MaintenancePattern(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      maintenanceType: json['maintenanceType'] as String,
      averageInterval: (json['averageInterval'] as num).toDouble(),
      predictedNextInterval: (json['predictedNextInterval'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      triggerFactors: List<String>.from(json['triggerFactors'] as List),
      performanceImpact: Map<String, double>.from(json['performanceImpact']),
      nextPredictedDate: json['nextPredictedDate'] != null
          ? DateTime.parse(json['nextPredictedDate'] as String)
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
      'maintenanceType': maintenanceType,
      'averageInterval': averageInterval,
      'predictedNextInterval': predictedNextInterval,
      'confidence': confidence,
      'triggerFactors': triggerFactors,
      'performanceImpact': performanceImpact,
      'nextPredictedDate': nextPredictedDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PredictiveMaintenance {
  final String userCombineId;
  final String maintenanceType;
  final String priority; // 'urgent', 'high', 'medium', 'low'
  final DateTime predictedDate;
  final double confidence;
  final List<String> warningSignals;
  final Map<String, double> riskFactors;
  final double costOfDelay;
  final List<String> recommendedActions;

  PredictiveMaintenance({
    required this.userCombineId,
    required this.maintenanceType,
    required this.priority,
    required this.predictedDate,
    required this.confidence,
    required this.warningSignals,
    required this.riskFactors,
    required this.costOfDelay,
    required this.recommendedActions,
  });

  factory PredictiveMaintenance.fromJson(Map<String, dynamic> json) {
    return PredictiveMaintenance(
      userCombineId: json['userCombineId'] as String,
      maintenanceType: json['maintenanceType'] as String,
      priority: json['priority'] as String,
      predictedDate: DateTime.parse(json['predictedDate'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      warningSignals: List<String>.from(json['warningSignals'] as List),
      riskFactors: Map<String, double>.from(json['riskFactors']),
      costOfDelay: (json['costOfDelay'] as num).toDouble(),
      recommendedActions: List<String>.from(json['recommendedActions'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'maintenanceType': maintenanceType,
      'priority': priority,
      'predictedDate': predictedDate.toIso8601String(),
      'confidence': confidence,
      'warningSignals': warningSignals,
      'riskFactors': riskFactors,
      'costOfDelay': costOfDelay,
      'recommendedActions': recommendedActions,
    };
  }
}

class MaintenanceOutcome extends BaseDocument {
  final String userCombineId;
  final String maintenanceType;
  final DateTime scheduledDate;
  final DateTime actualDate;
  final bool wasOnTime;
  final double cost;
  final List<String> workPerformed;
  final Map<String, double> performanceBeforeMaintenance;
  final Map<String, double>? performanceAfterMaintenance;
  final String? notes;
  final bool preventedFailure;

  MaintenanceOutcome({
    required String id,
    required this.userCombineId,
    required this.maintenanceType,
    required this.scheduledDate,
    required this.actualDate,
    required this.wasOnTime,
    required this.cost,
    required this.workPerformed,
    required this.performanceBeforeMaintenance,
    this.performanceAfterMaintenance,
    this.notes,
    required this.preventedFailure,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory MaintenanceOutcome.fromJson(Map<String, dynamic> json) {
    return MaintenanceOutcome(
      id: json['id'] as String,
      userCombineId: json['userCombineId'] as String,
      maintenanceType: json['maintenanceType'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      actualDate: DateTime.parse(json['actualDate'] as String),
      wasOnTime: json['wasOnTime'] as bool,
      cost: (json['cost'] as num).toDouble(),
      workPerformed: List<String>.from(json['workPerformed'] as List),
      performanceBeforeMaintenance: Map<String, double>.from(json['performanceBeforeMaintenance']),
      performanceAfterMaintenance: json['performanceAfterMaintenance'] != null
          ? Map<String, double>.from(json['performanceAfterMaintenance'])
          : null,
      notes: json['notes'] as String?,
      preventedFailure: json['preventedFailure'] as bool,
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
      'scheduledDate': scheduledDate.toIso8601String(),
      'actualDate': actualDate.toIso8601String(),
      'wasOnTime': wasOnTime,
      'cost': cost,
      'workPerformed': workPerformed,
      'performanceBeforeMaintenance': performanceBeforeMaintenance,
      'performanceAfterMaintenance': performanceAfterMaintenance,
      'notes': notes,
      'preventedFailure': preventedFailure,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Optimization data classes

class OptimizationConfig {
  final String userCombineId;
  final List<String> objectives; // 'fuel_efficiency', 'harvest_rate', 'grain_loss', etc.
  final Map<String, double> objectiveWeights;
  final Map<String, dynamic> constraints;
  final String optimizationAlgorithm;
  final Map<String, dynamic> algorithmParameters;
  final bool autoApplyRecommendations;

  OptimizationConfig({
    required this.userCombineId,
    required this.objectives,
    required this.objectiveWeights,
    required this.constraints,
    required this.optimizationAlgorithm,
    required this.algorithmParameters,
    required this.autoApplyRecommendations,
  });

  factory OptimizationConfig.fromJson(Map<String, dynamic> json) {
    return OptimizationConfig(
      userCombineId: json['userCombineId'] as String,
      objectives: List<String>.from(json['objectives'] as List),
      objectiveWeights: Map<String, double>.from(json['objectiveWeights']),
      constraints: Map<String, dynamic>.from(json['constraints']),
      optimizationAlgorithm: json['optimizationAlgorithm'] as String,
      algorithmParameters: Map<String, dynamic>.from(json['algorithmParameters']),
      autoApplyRecommendations: json['autoApplyRecommendations'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCombineId': userCombineId,
      'objectives': objectives,
      'objectiveWeights': objectiveWeights,
      'constraints': constraints,
      'optimizationAlgorithm': optimizationAlgorithm,
      'algorithmParameters': algorithmParameters,
      'autoApplyRecommendations': autoApplyRecommendations,
    };
  }
}

class OptimizationSuggestion {
  final String optimizationId;
  final Map<String, dynamic> suggestedSettings;
  final Map<String, double> expectedImprovement;
  final double confidence;
  final List<String> reasoning;
  final Map<String, dynamic> tradeoffs;
  final DateTime generatedAt;
  final String suggestionId;

  OptimizationSuggestion({
    required this.optimizationId,
    required this.suggestedSettings,
    required this.expectedImprovement,
    required this.confidence,
    required this.reasoning,
    required this.tradeoffs,
    required this.generatedAt,
    required this.suggestionId,
  });

  factory OptimizationSuggestion.fromJson(Map<String, dynamic> json) {
    return OptimizationSuggestion(
      optimizationId: json['optimizationId'] as String,
      suggestedSettings: Map<String, dynamic>.from(json['suggestedSettings']),
      expectedImprovement: Map<String, double>.from(json['expectedImprovement']),
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: List<String>.from(json['reasoning'] as List),
      tradeoffs: Map<String, dynamic>.from(json['tradeoffs']),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      suggestionId: json['suggestionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optimizationId': optimizationId,
      'suggestedSettings': suggestedSettings,
      'expectedImprovement': expectedImprovement,
      'confidence': confidence,
      'reasoning': reasoning,
      'tradeoffs': tradeoffs,
      'generatedAt': generatedAt.toIso8601String(),
      'suggestionId': suggestionId,
    };
  }
}

class OptimizationResult extends BaseDocument {
  final String optimizationId;
  final String suggestionId;
  final Map<String, dynamic> appliedSettings;
  final Map<String, double> actualImprovement;
  final Map<String, double> expectedImprovement;
  final double successScore; // How close actual was to expected
  final Map<String, dynamic> conditionsAtTime;
  final DateTime appliedAt;
  final double operationDuration; // hours
  final String? userFeedback;

  OptimizationResult({
    required String id,
    required this.optimizationId,
    required this.suggestionId,
    required this.appliedSettings,
    required this.actualImprovement,
    required this.expectedImprovement,
    required this.successScore,
    required this.conditionsAtTime,
    required this.appliedAt,
    required this.operationDuration,
    this.userFeedback,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    return OptimizationResult(
      id: json['id'] as String,
      optimizationId: json['optimizationId'] as String,
      suggestionId: json['suggestionId'] as String,
      appliedSettings: Map<String, dynamic>.from(json['appliedSettings']),
      actualImprovement: Map<String, double>.from(json['actualImprovement']),
      expectedImprovement: Map<String, double>.from(json['expectedImprovement']),
      successScore: (json['successScore'] as num).toDouble(),
      conditionsAtTime: Map<String, dynamic>.from(json['conditionsAtTime']),
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      operationDuration: (json['operationDuration'] as num).toDouble(),
      userFeedback: json['userFeedback'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'optimizationId': optimizationId,
      'suggestionId': suggestionId,
      'appliedSettings': appliedSettings,
      'actualImprovement': actualImprovement,
      'expectedImprovement': expectedImprovement,
      'successScore': successScore,
      'conditionsAtTime': conditionsAtTime,
      'appliedAt': appliedAt.toIso8601String(),
      'operationDuration': operationDuration,
      'userFeedback': userFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OptimizationHistory {
  final DateTime date;
  final Map<String, double> objectiveValues;
  final Map<String, dynamic> settings;
  final double overallScore;
  final String? notes;

  OptimizationHistory({
    required this.date,
    required this.objectiveValues,
    required this.settings,
    required this.overallScore,
    this.notes,
  });

  factory OptimizationHistory.fromJson(Map<String, dynamic> json) {
    return OptimizationHistory(
      date: DateTime.parse(json['date'] as String),
      objectiveValues: Map<String, double>.from(json['objectiveValues']),
      settings: Map<String, dynamic>.from(json['settings']),
      overallScore: (json['overallScore'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'objectiveValues': objectiveValues,
      'settings': settings,
      'overallScore': overallScore,
      'notes': notes,
    };
  }
}

class ConvergenceData {
  final String optimizationId;
  final List<double> objectiveHistory;
  final bool hasConverged;
  final double convergenceRate;
  final int iterationsToConvergence;
  final double currentBestScore;
  final DateTime lastImprovement;
  final Map<String, dynamic> bestSettings;

  ConvergenceData({
    required this.optimizationId,
    required this.objectiveHistory,
    required this.hasConverged,
    required this.convergenceRate,
    required this.iterationsToConvergence,
    required this.currentBestScore,
    required this.lastImprovement,
    required this.bestSettings,
  });

  factory ConvergenceData.fromJson(Map<String, dynamic> json) {
    return ConvergenceData(
      optimizationId: json['optimizationId'] as String,
      objectiveHistory: List<double>.from(json['objectiveHistory']),
      hasConverged: json['hasConverged'] as bool,
      convergenceRate: (json['convergenceRate'] as num).toDouble(),
      iterationsToConvergence: json['iterationsToConvergence'] as int,
      currentBestScore: (json['currentBestScore'] as num).toDouble(),
      lastImprovement: DateTime.parse(json['lastImprovement'] as String),
      bestSettings: Map<String, dynamic>.from(json['bestSettings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optimizationId': optimizationId,
      'objectiveHistory': objectiveHistory,
      'hasConverged': hasConverged,
      'convergenceRate': convergenceRate,
      'iterationsToConvergence': iterationsToConvergence,
      'currentBestScore': currentBestScore,
      'lastImprovement': lastImprovement.toIso8601String(),
      'bestSettings': bestSettings,
    };
  }
}

class MultiObjectiveResults {
  final String optimizationId;
  final List<Map<String, dynamic>> paretoFront;
  final Map<String, dynamic> recommendedSolution;
  final Map<String, double> tradeoffAnalysis;
  final List<String> solutionExplanation;
  final DateTime generatedAt;

  MultiObjectiveResults({
    required this.optimizationId,
    required this.paretoFront,
    required this.recommendedSolution,
    required this.tradeoffAnalysis,
    required this.solutionExplanation,
    required this.generatedAt,
  });

  factory MultiObjectiveResults.fromJson(Map<String, dynamic> json) {
    return MultiObjectiveResults(
      optimizationId: json['optimizationId'] as String,
      paretoFront: List<Map<String, dynamic>>.from(json['paretoFront']),
      recommendedSolution: Map<String, dynamic>.from(json['recommendedSolution']),
      tradeoffAnalysis: Map<String, double>.from(json['tradeoffAnalysis']),
      solutionExplanation: List<String>.from(json['solutionExplanation'] as List),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optimizationId': optimizationId,
      'paretoFront': paretoFront,
      'recommendedSolution': recommendedSolution,
      'tradeoffAnalysis': tradeoffAnalysis,
      'solutionExplanation': solutionExplanation,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

/// Knowledge base data classes

class KnowledgeRule extends BaseDocument {
  final String category; // 'settings', 'maintenance', 'troubleshooting', etc.
  final String ruleType; // 'if_then', 'lookup', 'calculation', etc.
  final String name;
  final String description;
  final Map<String, dynamic> conditions;
  final Map<String, dynamic> actions;
  final double confidence;
  final double effectiveness;
  final int usageCount;
  final List<String> tags;
  final String source; // 'expert', 'manufacturer', 'learned', 'community'
  final String? sourceReference;
  final bool isActive;
  final DateTime? lastUsed;

  KnowledgeRule({
    required String id,
    required this.category,
    required this.ruleType,
    required this.name,
    required this.description,
    required this.conditions,
    required this.actions,
    required this.confidence,
    required this.effectiveness,
    required this.usageCount,
    required this.tags,
    required this.source,
    this.sourceReference,
    required this.isActive,
    this.lastUsed,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory KnowledgeRule.fromJson(Map<String, dynamic> json) {
    return KnowledgeRule(
      id: json['id'] as String,
      category: json['category'] as String,
      ruleType: json['ruleType'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      conditions: Map<String, dynamic>.from(json['conditions']),
      actions: Map<String, dynamic>.from(json['actions']),
      confidence: (json['confidence'] as num).toDouble(),
      effectiveness: (json['effectiveness'] as num).toDouble(),
      usageCount: json['usageCount'] as int,
      tags: List<String>.from(json['tags'] as List),
      source: json['source'] as String,
      sourceReference: json['sourceReference'] as String?,
      isActive: json['isActive'] as bool,
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
      'category': category,
      'ruleType': ruleType,
      'name': name,
      'description': description,
      'conditions': conditions,
      'actions': actions,
      'confidence': confidence,
      'effectiveness': effectiveness,
      'usageCount': usageCount,
      'tags': tags,
      'source': source,
      'sourceReference': sourceReference,
      'isActive': isActive,
      'lastUsed': lastUsed?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ExpertRecommendation {
  final String ruleId;
  final String expertId;
  final String recommendation;
  final double confidence;
  final List<String> reasoning;
  final Map<String, dynamic>? supportingData;
  final List<String> alternativeApproaches;
  final DateTime providedAt;
  final bool isValidated;

  ExpertRecommendation({
    required this.ruleId,
    required this.expertId,
    required this.recommendation,
    required this.confidence,
    required this.reasoning,
    this.supportingData,
    required this.alternativeApproaches,
    required this.providedAt,
    required this.isValidated,
  });

  factory ExpertRecommendation.fromJson(Map<String, dynamic> json) {
    return ExpertRecommendation(
      ruleId: json['ruleId'] as String,
      expertId: json['expertId'] as String,
      recommendation: json['recommendation'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: List<String>.from(json['reasoning'] as List),
      supportingData: json['supportingData'] != null
          ? Map<String, dynamic>.from(json['supportingData'])
          : null,
      alternativeApproaches: List<String>.from(json['alternativeApproaches'] as List),
      providedAt: DateTime.parse(json['providedAt'] as String),
      isValidated: json['isValidated'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'expertId': expertId,
      'recommendation': recommendation,
      'confidence': confidence,
      'reasoning': reasoning,
      'supportingData': supportingData,
      'alternativeApproaches': alternativeApproaches,
      'providedAt': providedAt.toIso8601String(),
      'isValidated': isValidated,
    };
  }
}

class KnowledgeConflict extends BaseDocument {
  final List<String> conflictingRuleIds;
  final String conflictType; // 'contradiction', 'overlap', 'precedence'
  final String description;
  final Map<String, dynamic> conflictDetails;
  final double severity; // 0-10 scale
  final bool isResolved;
  final String? resolution;
  final String? resolverId;
  final DateTime? resolvedAt;

  KnowledgeConflict({
    required String id,
    required this.conflictingRuleIds,
    required this.conflictType,
    required this.description,
    required this.conflictDetails,
    required this.severity,
    required this.isResolved,
    this.resolution,
    this.resolverId,
    this.resolvedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory KnowledgeConflict.fromJson(Map<String, dynamic> json) {
    return KnowledgeConflict(
      id: json['id'] as String,
      conflictingRuleIds: List<String>.from(json['conflictingRuleIds'] as List),
      conflictType: json['conflictType'] as String,
      description: json['description'] as String,
      conflictDetails: Map<String, dynamic>.from(json['conflictDetails']),
      severity: (json['severity'] as num).toDouble(),
      isResolved: json['isResolved'] as bool,
      resolution: json['resolution'] as String?,
      resolverId: json['resolverId'] as String?,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conflictingRuleIds': conflictingRuleIds,
      'conflictType': conflictType,
      'description': description,
      'conflictDetails': conflictDetails,
      'severity': severity,
      'isResolved': isResolved,
      'resolution': resolution,
      'resolverId': resolverId,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class RuleEffectivenessStats {
  final String ruleId;
  final double overallEffectiveness;
  final int totalApplications;
  final int successfulApplications;
  final double averageUserRating;
  final Map<String, double> effectivenessByContext;
  final List<String> commonFailureReasons;
  final DateTime lastAnalysis;
  final bool recommendRetirement;

  RuleEffectivenessStats({
    required this.ruleId,
    required this.overallEffectiveness,
    required this.totalApplications,
    required this.successfulApplications,
    required this.averageUserRating,
    required this.effectivenessByContext,
    required this.commonFailureReasons,
    required this.lastAnalysis,
    required this.recommendRetirement,
  });

  factory RuleEffectivenessStats.fromJson(Map<String, dynamic> json) {
    return RuleEffectivenessStats(
      ruleId: json['ruleId'] as String,
      overallEffectiveness: (json['overallEffectiveness'] as num).toDouble(),
      totalApplications: json['totalApplications'] as int,
      successfulApplications: json['successfulApplications'] as int,
      averageUserRating: (json['averageUserRating'] as num).toDouble(),
      effectivenessByContext: Map<String, double>.from(json['effectivenessByContext']),
      commonFailureReasons: List<String>.from(json['commonFailureReasons'] as List),
      lastAnalysis: DateTime.parse(json['lastAnalysis'] as String),
      recommendRetirement: json['recommendRetirement'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'overallEffectiveness': overallEffectiveness,
      'totalApplications': totalApplications,
      'successfulApplications': successfulApplications,
      'averageUserRating': averageUserRating,
      'effectivenessByContext': effectivenessByContext,
      'commonFailureReasons': commonFailureReasons,
      'lastAnalysis': lastAnalysis.toIso8601String(),
      'recommendRetirement': recommendRetirement,
    };
  }
}

class KnowledgeCoverage {
  final String combineSpecId;
  final String crop;
  final Map<String, double> categoryCoerage; // percentage coverage by category
  final List<String> gapsIdentified;
  final List<String> wellCoveredAreas;
  final double overallCoverage;
  final List<String> recommendedExpansions;
  final DateTime analysisDate;

  KnowledgeCoverage({
    required this.combineSpecId,
    required this.crop,
    required this.categoryCoerage,
    required this.gapsIdentified,
    required this.wellCoveredAreas,
    required this.overallCoverage,
    required this.recommendedExpansions,
    required this.analysisDate,
  });

  factory KnowledgeCoverage.fromJson(Map<String, dynamic> json) {
    return KnowledgeCoverage(
      combineSpecId: json['combineSpecId'] as String,
      crop: json['crop'] as String,
      categoryCoerage: Map<String, double>.from(json['categoryCoerage']),
      gapsIdentified: List<String>.from(json['gapsIdentified'] as List),
      wellCoveredAreas: List<String>.from(json['wellCoveredAreas'] as List),
      overallCoverage: (json['overallCoverage'] as num).toDouble(),
      recommendedExpansions: List<String>.from(json['recommendedExpansions'] as List),
      analysisDate: DateTime.parse(json['analysisDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'crop': crop,
      'categoryCoerage': categoryCoerage,
      'gapsIdentified': gapsIdentified,
      'wellCoveredAreas': wellCoveredAreas,
      'overallCoverage': overallCoverage,
      'recommendedExpansions': recommendedExpansions,
      'analysisDate': analysisDate.toIso8601String(),
    };
  }
}