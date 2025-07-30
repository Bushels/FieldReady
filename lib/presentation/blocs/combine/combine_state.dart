/**
 * CombineState - Sealed classes for CombineBloc states
 * Handles all combine-related state management with confidence tracking
 * Includes offline support, sync status, and progressive data loading
 */

import 'package:equatable/equatable.dart';
import '../../../domain/models/combine_models.dart';
import '../../../domain/models/harvest_models.dart';

/// Base sealed class for all combine states
sealed class CombineState extends Equatable {
  /// Confidence level for the current state (0.0-1.0)
  final double confidence;
  
  /// When this state was last updated
  final DateTime lastUpdated;
  
  /// Whether this state represents cached/offline data
  final bool isFromCache;
  
  /// Current sync status
  final SyncStatus syncStatus;
  
  /// Any errors in the current state
  final String? error;

  const CombineState({
    required this.confidence,
    required this.lastUpdated,
    this.isFromCache = false,
    this.syncStatus = SyncStatus.completed,
    this.error,
  });

  @override
  List<Object?> get props => [confidence, lastUpdated, isFromCache, syncStatus, error];
}

/// Initial state when BLoC is created
final class CombineInitial extends CombineState {
  const CombineInitial()
      : super(
          confidence: 1.0,
          lastUpdated: const DateTime.now(),
        );
}

/// Loading state for various operations
final class CombineLoading extends CombineState {
  final CombineLoadingType loadingType;
  final String? progressMessage;
  final double? progressPercentage;

  const CombineLoading({
    required this.loadingType,
    this.progressMessage,
    this.progressPercentage,
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.syncing,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        loadingType,
        progressMessage,
        progressPercentage,
      ];
}

/// Successfully loaded combines with full data
final class CombineLoaded extends CombineState {
  /// User's personal combines
  final List<UserCombine> userCombines;
  
  /// Available combine specifications (public data)
  final List<CombineSpec> availableSpecs;
  
  /// Currently selected/active combine
  final UserCombine? activeCombine;
  
  /// Progressive capabilities data by spec ID
  final Map<String, ProgressiveCapabilities> progressiveCapabilities;
  
  /// Equipment factor analysis by combine spec ID
  final Map<String, EquipmentFactorAnalysis> equipmentFactorAnalyses;
  
  /// Pending sync operations
  final List<SyncOperation> pendingSyncOperations;
  
  /// Failed sync operations that need retry
  final List<SyncOperation> failedSyncOperations;

  const CombineLoaded({
    required this.userCombines,
    required this.availableSpecs,
    this.activeCombine,
    this.progressiveCapabilities = const {},
    this.equipmentFactorAnalyses = const {},
    this.pendingSyncOperations = const [],
    this.failedSyncOperations = const [],
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.completed,
    String? error,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
          error: error,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        userCombines,
        availableSpecs,
        activeCombine,
        progressiveCapabilities,
        equipmentFactorAnalyses,
        pendingSyncOperations,
        failedSyncOperations,
      ];

  /// Create a copy with updated values
  CombineLoaded copyWith({
    List<UserCombine>? userCombines,
    List<CombineSpec>? availableSpecs,
    UserCombine? activeCombine,
    Map<String, ProgressiveCapabilities>? progressiveCapabilities,
    Map<String, EquipmentFactorAnalysis>? equipmentFactorAnalyses,
    List<SyncOperation>? pendingSyncOperations,
    List<SyncOperation>? failedSyncOperations,
    double? confidence,
    DateTime? lastUpdated,
    bool? isFromCache,
    SyncStatus? syncStatus,
    String? error,
  }) {
    return CombineLoaded(
      userCombines: userCombines ?? this.userCombines,
      availableSpecs: availableSpecs ?? this.availableSpecs,
      activeCombine: activeCombine ?? this.activeCombine,
      progressiveCapabilities: progressiveCapabilities ?? this.progressiveCapabilities,
      equipmentFactorAnalyses: equipmentFactorAnalyses ?? this.equipmentFactorAnalyses,
      pendingSyncOperations: pendingSyncOperations ?? this.pendingSyncOperations,
      failedSyncOperations: failedSyncOperations ?? this.failedSyncOperations,
      confidence: confidence ?? this.confidence,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
      syncStatus: syncStatus ?? this.syncStatus,
      error: error ?? this.error,
    );
  }
}

/// State showing fuzzy match results for user confirmation
final class CombineNormalizationRequired extends CombineState {
  /// Original user input
  final String originalInput;
  
  /// Fuzzy match results (top 3)
  final List<FuzzyMatchResult> matchResults;
  
  /// Additional context from user input
  final CombineInputContext inputContext;

  const CombineNormalizationRequired({
    required this.originalInput,
    required this.matchResults,
    required this.inputContext,
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.completed,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        originalInput,
        matchResults,
        inputContext,
      ];
}

/// State when sync conflicts need resolution
final class CombineConflictResolution extends CombineState {
  /// Conflicted data items
  final List<CombineConflict> conflicts;
  
  /// Suggested resolution strategies
  final Map<String, ConflictResolutionStrategy> suggestedStrategies;

  const CombineConflictResolution({
    required this.conflicts,
    required this.suggestedStrategies,
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.failed,
    String? error,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
          error: error,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        conflicts,
        suggestedStrategies,
      ];
}

/// State showing search results
final class CombineSearchResults extends CombineState {
  /// Search query
  final String query;
  
  /// Search results with relevance scores
  final List<CombineSearchResult> results;
  
  /// Whether more results are available
  final bool hasMoreResults;

  const CombineSearchResults({
    required this.query,
    required this.results,
    this.hasMoreResults = false,
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.completed,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        query,
        results,
        hasMoreResults,
      ];
}

/// Error state with recovery options
final class CombineError extends CombineState {
  /// Error message for user display
  final String message;
  
  /// Technical error details for debugging
  final String? technicalDetails;
  
  /// Suggested recovery actions
  final List<CombineErrorAction> recoveryActions;
  
  /// Whether this error is recoverable
  final bool isRecoverable;
  
  /// Previous state before error (for recovery)
  final CombineState? previousState;

  const CombineError({
    required this.message,
    this.technicalDetails,
    this.recoveryActions = const [],
    this.isRecoverable = true,
    this.previousState,
    required double confidence,
    required DateTime lastUpdated,
    bool isFromCache = false,
    SyncStatus syncStatus = SyncStatus.failed,
  }) : super(
          confidence: confidence,
          lastUpdated: lastUpdated,
          isFromCache: isFromCache,
          syncStatus: syncStatus,
          error: message,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        message,
        technicalDetails,
        recoveryActions,
        isRecoverable,
        previousState,
      ];
}

/// Supporting classes and enums

/// Types of loading operations
enum CombineLoadingType {
  initialLoad,
  refreshing,
  syncing,
  normalizing,
  searchingSpecs,
  loadingCapabilities,
  addingCombine,
  updatingCombine,
  removingCombine,
}

/// Context from user input during combine addition
class CombineInputContext extends Equatable {
  final String userId;
  final String? brand;
  final String? model;
  final int? year;
  final String? nickname;
  final Map<String, dynamic> customSettings;
  final String? region;

  const CombineInputContext({
    required this.userId,
    this.brand,
    this.model,
    this.year,
    this.nickname,  
    this.customSettings = const {},
    this.region,
  });

  @override
  List<Object?> get props => [userId, brand, model, year, nickname, customSettings, region];
}

/// Progressive capabilities based on available data volume
class ProgressiveCapabilities extends Equatable {
  /// Data aggregation level achieved
  final CapabilityLevel level;
  
  /// Number of users contributing data
  final int userCount;
  
  /// Basic capabilities (always available)
  final HarvestCapabilities? basicCapabilities;
  
  /// Brand-specific insights (5-15 users)
  final BrandCapabilities? brandCapabilities;
  
  /// Model-specific insights (15+ users)
  final ModelCapabilities? modelCapabilities;
  
  /// Confidence in the data quality
  final double dataConfidence;
  
  /// When this data was last aggregated
  final DateTime lastAggregated;

  const ProgressiveCapabilities({
    required this.level,
    required this.userCount,
    this.basicCapabilities,
    this.brandCapabilities,
    this.modelCapabilities,
    required this.dataConfidence,
    required this.lastAggregated,
  });

  @override
  List<Object?> get props => [
        level,
        userCount,
        basicCapabilities,
        brandCapabilities,
        modelCapabilities,
        dataConfidence,
        lastAggregated,
      ];
}

/// Capability levels based on data availability
enum CapabilityLevel {
  minimal,  // < 5 users
  moderate, // 5-15 users  
  rich,     // 15+ users
}

/// Brand-specific capabilities
class BrandCapabilities extends Equatable {
  final String brand;
  final MoistureTolerance moistureTolerance;
  final ToughCropAbility toughCropAbility;
  final Map<String, double> performanceMetrics;
  final List<String> commonIssues;
  final List<String> recommendations;

  const BrandCapabilities({
    required this.brand,
    required this.moistureTolerance,
    required this.toughCropAbility,
    this.performanceMetrics = const {},
    this.commonIssues = const [],
    this.recommendations = const [],
  });

  @override
  List<Object?> get props => [
        brand,
        moistureTolerance,
        toughCropAbility,
        performanceMetrics,
        commonIssues,
        recommendations,
      ];
}

/// Model-specific capabilities
class ModelCapabilities extends Equatable {
  final String brand;
  final String model;
  final HarvestCapabilities harvestCapabilities;
  final MoistureTolerance moistureTolerance;
  final ToughCropAbility toughCropAbility;
  final Map<String, dynamic> performanceData;
  final PeerComparison? peerComparison;
  final List<String> expertRecommendations;

  const ModelCapabilities({
    required this.brand,
    required this.model,
    required this.harvestCapabilities,
    required this.moistureTolerance,
    required this.toughCropAbility,
    this.performanceData = const {},
    this.peerComparison,
    this.expertRecommendations = const [],
  });

  @override
  List<Object?> get props => [
        brand,
        model,
        harvestCapabilities,
        moistureTolerance,
        toughCropAbility,
        performanceData,
        peerComparison,
        expertRecommendations,
      ];
}

/// Data conflict during sync
class CombineConflict extends Equatable {
  final String id;
  final String combineId;
  final ConflictType type;
  final dynamic localData;
  final dynamic remoteData;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final double localConfidence;
  final double remoteConfidence;

  const CombineConflict({
    required this.id,
    required this.combineId,
    required this.type,
    required this.localData,
    required this.remoteData,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.localConfidence,
    required this.remoteConfidence,
  });

  @override
  List<Object?> get props => [
        id,
        combineId,
        type,
        localData,
        remoteData,
        localTimestamp,
        remoteTimestamp,
        localConfidence,
        remoteConfidence,
      ];
}

/// Types of conflicts that can occur
enum ConflictType {
  combineSettings,
  capabilities,
  moistureTolerance,
  toughCropAbility,
  customSettings,
  maintenanceNotes,
}

/// Search result with relevance scoring
class CombineSearchResult extends Equatable {
  final CombineSpec spec;
  final double relevanceScore;
  final List<String> matchedFields;
  final MatchType matchType;

  const CombineSearchResult({
    required this.spec,
    required this.relevanceScore,
    this.matchedFields = const [],
    required this.matchType,
  });

  @override
  List<Object?> get props => [spec, relevanceScore, matchedFields, matchType];
}

/// Recovery actions for error states
class CombineErrorAction extends Equatable {
  final String label;
  final String description;
  final CombineErrorActionType type;
  final Map<String, dynamic>? actionData;

  const CombineErrorAction({
    required this.label,
    required this.description,
    required this.type,
    this.actionData,
  });

  @override
  List<Object?> get props => [label, description, type, actionData];
}

/// Types of error recovery actions
enum CombineErrorActionType {
  retry,
  refresh,
  clearCache,
  syncManually,
  contactSupport,
  useCachedData,
  resetState,
}

/// Import required enums from combine_event.dart
enum ConflictResolutionStrategy {
  useLocal,
  useRemote,
  merge,
  useHigherConfidence,
  manualResolve,
}