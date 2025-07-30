/**
 * CombineEvent - Sealed classes for CombineBloc events
 * Handles all combine-related user actions and system events
 * Includes fuzzy matching, confirmation flows, and sync operations
 */

import 'package:equatable/equatable.dart';
import '../../../domain/models/combine_models.dart';
import '../../../domain/models/harvest_models.dart';

/// Base sealed class for all combine events
sealed class CombineEvent extends Equatable {
  const CombineEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's combines from cache and remote
final class LoadUserCombines extends CombineEvent {
  final String userId;
  final bool forceRefresh;

  const LoadUserCombines({
    required this.userId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [userId, forceRefresh];
}

/// Add a new combine with fuzzy matching
final class AddCombine extends CombineEvent {
  final String userId;
  final String brand;
  final String model;
  final int? year;
  final String? nickname;
  final Map<String, dynamic> customSettings;

  const AddCombine({
    required this.userId,
    required this.brand,
    required this.model,
    this.year,
    this.nickname,
    this.customSettings = const {},
  });

  @override
  List<Object?> get props => [userId, brand, model, year, nickname, customSettings];
}

/// Confirm a fuzzy matched model normalization
final class ConfirmNormalizedModel extends CombineEvent {
  final String userId;
  final String originalInput;
  final FuzzyMatchResult selectedMatch;
  final String? nickname;
  final Map<String, dynamic> customSettings;

  const ConfirmNormalizedModel({
    required this.userId,
    required this.originalInput,
    required this.selectedMatch,
    this.nickname,
    this.customSettings = const {},
  });

  @override
  List<Object?> get props => [userId, originalInput, selectedMatch, nickname, customSettings];
}

/// Reject fuzzy match suggestion and request manual entry
final class RejectNormalizedModel extends CombineEvent {
  final String userId;
  final String originalInput;
  final FuzzyMatchResult rejectedMatch;
  final String? userProvidedCorrection;

  const RejectNormalizedModel({
    required this.userId,
    required this.originalInput,
    required this.rejectedMatch,
    this.userProvidedCorrection,
  });

  @override
  List<Object?> get props => [userId, originalInput, rejectedMatch, userProvidedCorrection];
}

/// Update combine capabilities (harvest specs, moisture tolerance, etc.)
final class UpdateCombineCapabilities extends CombineEvent {
  final String combineId;
  final HarvestCapabilities? harvestCapabilities;
  final MoistureTolerance? moistureTolerance;
  final ToughCropAbility? toughCropAbility;

  const UpdateCombineCapabilities({
    required this.combineId,
    this.harvestCapabilities,
    this.moistureTolerance,
    this.toughCropAbility,
  });

  @override
  List<Object?> get props => [combineId, harvestCapabilities, moistureTolerance, toughCropAbility];
}

/// Update user combine settings and preferences
final class UpdateCombineSettings extends CombineEvent {
  final String combineId;
  final String? nickname;
  final Map<String, dynamic> customSettings;
  final bool? isActive;
  final int? hoursOfOperation;
  final List<String>? maintenanceNotes;

  const UpdateCombineSettings({
    required this.combineId,
    this.nickname,
    this.customSettings = const {},
    this.isActive,
    this.hoursOfOperation,
    this.maintenanceNotes,
  });

  @override
  List<Object?> get props => [combineId, nickname, customSettings, isActive, hoursOfOperation, maintenanceNotes];
}

/// Remove a combine from user's fleet
final class RemoveCombine extends CombineEvent {
  final String combineId;
  final String userId;

  const RemoveCombine({
    required this.combineId,
    required this.userId,
  });

  @override
  List<Object?> get props => [combineId, userId];
}

/// Sync combine data with remote server
final class SyncCombineData extends CombineEvent {
  final String userId;
  final List<String>? specificCombineIds; // null means sync all
  final bool isManualSync;

  const SyncCombineData({
    required this.userId,
    this.specificCombineIds,
    this.isManualSync = false,
  });

  @override
  List<Object?> get props => [userId, specificCombineIds, isManualSync];
}

/// Handle sync operation completion
final class SyncOperationCompleted extends CombineEvent {
  final String operationId;
  final SyncStatus status;
  final String? error;

  const SyncOperationCompleted({
    required this.operationId,
    required this.status,
    this.error,
  });

  @override
  List<Object?> get props => [operationId, status, error];
}

/// Retry failed sync operations
final class RetrySyncOperations extends CombineEvent {
  final String userId;
  final List<String>? specificOperationIds;

  const RetrySyncOperations({
    required this.userId,
    this.specificOperationIds,
  });

  @override
  List<Object?> get props => [userId, specificOperationIds];
}

/// Load combine specifications from cache/remote
final class LoadCombineSpecs extends CombineEvent {
  final String? brand;
  final String? model;
  final String? region;
  final bool includePublicSpecs;

  const LoadCombineSpecs({
    this.brand,
    this.model,
    this.region,
    this.includePublicSpecs = true,
  });

  @override
  List<Object?> get props => [brand, model, region, includePublicSpecs];
}

/// Search combines with fuzzy matching
final class SearchCombines extends CombineEvent {
  final String query;
  final String? userId;
  final int maxResults;

  const SearchCombines({
    required this.query,
    this.userId,
    this.maxResults = 10,
  });

  @override
  List<Object?> get props => [query, userId, maxResults];
}

/// Clear search results
final class ClearSearchResults extends CombineEvent {
  const ClearSearchResults();
}

/// Select a combine as active/primary
final class SelectActiveCombine extends CombineEvent {
  final String combineId;
  final String userId;

  const SelectActiveCombine({
    required this.combineId,
    required this.userId,
  });

  @override
  List<Object?> get props => [combineId, userId];
}

/// Load progressive capabilities based on available data
final class LoadProgressiveCapabilities extends CombineEvent {
  final String combineSpecId;
  final String? region;
  final String? userId;

  const LoadProgressiveCapabilities({
    required this.combineSpecId,
    this.region,
    this.userId,
  });

  @override
  List<Object?> get props => [combineSpecId, region, userId];
}

/// Handle conflict resolution during sync
final class ResolveConflict extends CombineEvent {
  final String conflictId;
  final ConflictResolutionStrategy strategy;
  final dynamic resolutionData;

  const ResolveConflict({
    required this.conflictId,
    required this.strategy,
    this.resolutionData,
  });

  @override
  List<Object?> get props => [conflictId, strategy, resolutionData];
}

/// Reset combine state to initial
final class ResetCombineState extends CombineEvent {
  const ResetCombineState();
}

/// Clear cached combine data
final class ClearCombineCache extends CombineEvent {
  final String? userId;
  final bool clearAll;

  const ClearCombineCache({
    this.userId,
    this.clearAll = false,
  });

  @override
  List<Object?> get props => [userId, clearAll];
}

/// Calculate equipment factors for a combine
final class CalculateEquipmentFactors extends CombineEvent {
  final String combineSpecId;
  final String? weatherLocationId;
  final CropType crop;
  final Map<EquipmentFactorType, double>? customWeights;

  const CalculateEquipmentFactors({
    required this.combineSpecId,
    this.weatherLocationId,
    required this.crop,
    this.customWeights,
  });

  @override
  List<Object?> get props => [combineSpecId, weatherLocationId, crop, customWeights];
}

/// Update equipment factors for a combine
final class UpdateEquipmentFactors extends CombineEvent {
  final String combineSpecId;
  final List<EquipmentFactor> factors;
  final double overallMultiplier;

  const UpdateEquipmentFactors({
    required this.combineSpecId,
    required this.factors,
    required this.overallMultiplier,
  });

  @override
  List<Object?> get props => [combineSpecId, factors, overallMultiplier];
}

/// Refresh equipment factors for all user combines
final class RefreshEquipmentFactors extends CombineEvent {
  final String userId;
  final CropType crop;
  final String? weatherLocationId;

  const RefreshEquipmentFactors({
    required this.userId,
    required this.crop,
    this.weatherLocationId,
  });

  @override
  List<Object?> get props => [userId, crop, weatherLocationId];
}

/// Apply equipment factors to harvest capabilities
final class ApplyEquipmentFactorsToCapabilities extends CombineEvent {
  final String combineSpecId;
  final List<EquipmentFactor> factors;

  const ApplyEquipmentFactorsToCapabilities({
    required this.combineSpecId,
    required this.factors,
  });

  @override
  List<Object?> get props => [combineSpecId, factors];
}

/// Supporting enums for events
enum ConflictResolutionStrategy {
  useLocal,
  useRemote,
  merge,
  useHigherConfidence,
  manualResolve,
}