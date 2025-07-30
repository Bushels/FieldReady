/**
 * CombineBloc - Main BLoC for combine state management
 * Implements hydrated_bloc for offline persistence and handles:
 * - User combine management with fuzzy matching
 * - Progressive capability loading
 * - Offline sync with conflict resolution
 * - Real-time state updates with confidence tracking
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../../domain/models/combine_models.dart';
import '../../../domain/repositories/combine_repository.dart';
import '../../../domain/services/combine_normalizer.dart';
import '../../../domain/services/sync_service.dart';
import '../../../domain/services/harvest_intelligence.dart';
import 'combine_event.dart';
import 'combine_state.dart';

/// Main CombineBloc with offline persistence and sync capabilities
class CombineBloc extends HydratedBloc<CombineEvent, CombineState> {
  final CombineRepository _combineRepository;
  final UserCombineRepository _userCombineRepository;
  final NormalizationRepository _normalizationRepository;
  final SyncRepository _syncRepository;
  final CombineNormalizer _normalizer;
  final SyncService _syncService;
  final HarvestIntelligence _harvestIntelligence;

  // Stream subscriptions for cleanup
  StreamSubscription? _syncSubscription;
  
  // Cache for expensive operations
  final Map<String, DateTime> _lastFetchTimes = {};
  static const Duration _cacheValidDuration = Duration(hours: 1);

  CombineBloc({
    required CombineRepository combineRepository,
    required UserCombineRepository userCombineRepository,
    required NormalizationRepository normalizationRepository,
    required SyncRepository syncRepository,
    required CombineNormalizer normalizer,
    required SyncService syncService,
    required HarvestIntelligence harvestIntelligence,
  })  : _combineRepository = combineRepository,
        _userCombineRepository = userCombineRepository,
        _normalizationRepository = normalizationRepository,
        _syncRepository = syncRepository,
        _normalizer = normalizer,
        _syncService = syncService,
        _harvestIntelligence = harvestIntelligence,
        super(const CombineInitial()) {
    
    // Set up event transformers for different event types
    on<LoadUserCombines>(_onLoadUserCombines);
    on<AddCombine>(_onAddCombine, transformer: _debounceTransformer());
    on<ConfirmNormalizedModel>(_onConfirmNormalizedModel);
    on<RejectNormalizedModel>(_onRejectNormalizedModel);
    on<UpdateCombineCapabilities>(_onUpdateCombineCapabilities);
    on<UpdateCombineSettings>(_onUpdateCombineSettings);
    on<RemoveCombine>(_onRemoveCombine);
    on<SyncCombineData>(_onSyncCombineData, transformer: _throttleTransformer());
    on<SyncOperationCompleted>(_onSyncOperationCompleted);
    on<RetrySyncOperations>(_onRetrySyncOperations);
    on<LoadCombineSpecs>(_onLoadCombineSpecs);
    on<SearchCombines>(_onSearchCombines, transformer: _debounceTransformer());
    on<ClearSearchResults>(_onClearSearchResults);
    on<SelectActiveCombine>(_onSelectActiveCombine);
    on<LoadProgressiveCapabilities>(_onLoadProgressiveCapabilities);
    on<ResolveConflict>(_onResolveConflict);
    on<ResetCombineState>(_onResetCombineState);
    on<ClearCombineCache>(_onClearCombineCache);
    
    // Equipment factor events
    on<CalculateEquipmentFactors>(_onCalculateEquipmentFactors);
    on<UpdateEquipmentFactors>(_onUpdateEquipmentFactors);
    on<RefreshEquipmentFactors>(_onRefreshEquipmentFactors);
    on<ApplyEquipmentFactorsToCapabilities>(_onApplyEquipmentFactorsToCapabilities);

    // Listen to sync service events
    _initializeSyncListener();
  }

  /// Initialize sync service listener for background updates
  void _initializeSyncListener() {
    _syncSubscription = _syncService.syncStatusStream.listen((syncEvent) {
      add(SyncOperationCompleted(
        operationId: syncEvent.operationId,
        status: syncEvent.status,
        error: syncEvent.error,
      ));
    });
  }

  /// Load user combines from cache and remote
  Future<void> _onLoadUserCombines(
    LoadUserCombines event,
    Emitter<CombineState> emit,
  ) async {
    try {
      final cacheKey = 'user_combines_${event.userId}';
      final shouldRefresh = event.forceRefresh || 
          !_isDataFresh(cacheKey) ||
          state is CombineInitial;

      if (!shouldRefresh && state is CombineLoaded) {
        return; // Use existing state
      }

      emit(CombineLoading(
        loadingType: shouldRefresh ? CombineLoadingType.refreshing : CombineLoadingType.initialLoad,
        confidence: 0.8,
        lastUpdated: DateTime.now(),
      ));

      // Load from cache first for immediate UI feedback
      List<UserCombine> cachedCombines = [];
      try {
        cachedCombines = await _userCombineRepository.getByUserId(event.userId);
      } catch (e) {
        // Cache miss or error, continue with remote fetch
      }

      if (cachedCombines.isNotEmpty && !event.forceRefresh) {
        final availableSpecs = await _combineRepository.getAll();
        final activeCombine = cachedCombines.where((c) => c.isActive).firstOrNull;
        
        emit(CombineLoaded(
          userCombines: cachedCombines,
          availableSpecs: availableSpecs,
          activeCombine: activeCombine,
          confidence: 0.9,
          lastUpdated: DateTime.now(),
          isFromCache: true,
          syncStatus: SyncStatus.pending,
        ));
      }

      // Fetch fresh data
      if (shouldRefresh) {
        await _syncService.syncUserCombines(event.userId);
        final freshCombines = await _userCombineRepository.getByUserId(event.userId);
        final availableSpecs = await _combineRepository.getAll();
        final activeCombine = freshCombines.where((c) => c.isActive).firstOrNull;
        
        // Load progressive capabilities for each combine
        final capabilities = <String, ProgressiveCapabilities>{};
        for (final combine in freshCombines) {
          try {
            final capability = await _loadProgressiveCapabilityData(
              combine.combineSpecId,
              userId: event.userId,
            );
            if (capability != null) {
              capabilities[combine.combineSpecId] = capability;
            }
          } catch (e) {
            // Continue loading other capabilities
          }
        }

        _lastFetchTimes[cacheKey] = DateTime.now();

        emit(CombineLoaded(
          userCombines: freshCombines,
          availableSpecs: availableSpecs,
          activeCombine: activeCombine,
          progressiveCapabilities: capabilities,
          confidence: 1.0,
          lastUpdated: DateTime.now(),
          isFromCache: false,
          syncStatus: SyncStatus.completed,
        ));
      }

    } catch (error) {
      emit(CombineError(
        message: 'Failed to load combines',
        technicalDetails: error.toString(),
        recoveryActions: [
          const CombineErrorAction(
            label: 'Retry',
            description: 'Try loading combines again',
            type: CombineErrorActionType.retry,
          ),
          const CombineErrorAction(
            label: 'Use Cached Data',
            description: 'Continue with offline data',
            type: CombineErrorActionType.useCachedData,
          ),
        ],
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Add combine with fuzzy matching and normalization
  Future<void> _onAddCombine(
    AddCombine event,
    Emitter<CombineState> emit,
  ) async {
    try {
      emit(CombineLoading(
        loadingType: CombineLoadingType.normalizing,
        progressMessage: 'Normalizing combine model...',
        confidence: 0.7,
        lastUpdated: DateTime.now(),
      ));

      // Normalize the brand and model input
      final inputString = '${event.brand} ${event.model}'.trim();
      final normalizationResults = await _normalizer.normalize(
        inputString,
        year: event.year,
        userId: event.userId,
        maxResults: 3,
      );

      if (normalizationResults.isEmpty) {
        emit(CombineError(
          message: 'No matching combine found',
          technicalDetails: 'Could not normalize: $inputString',
          recoveryActions: [
            const CombineErrorAction(
              label: 'Try Different Spelling',
              description: 'Check the brand and model spelling',
              type: CombineErrorActionType.retry,
            ),
            const CombineErrorAction(
              label: 'Contact Support',
              description: 'Report missing combine model',
              type: CombineErrorActionType.contactSupport,
            ),
          ],
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        ));
        return;
      }

      final bestMatch = normalizationResults.first;

      // If confidence is high, auto-confirm
      if (!bestMatch.requiresConfirmation && bestMatch.confidence >= 0.95) {
        await _createCombineFromMatch(
          event.userId,
          bestMatch,
          event.nickname,
          event.customSettings,
          emit,
        );
        return;
      }

      // Require user confirmation for low confidence matches
      emit(CombineNormalizationRequired(
        originalInput: inputString,
        matchResults: normalizationResults,
        inputContext: CombineInputContext(
          userId: event.userId,
          brand: event.brand,
          model: event.model,
          year: event.year,
          nickname: event.nickname,
          customSettings: event.customSettings,
        ),
        confidence: bestMatch.confidence,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to add combine',
        technicalDetails: error.toString(),
        recoveryActions: [
          const CombineErrorAction(
            label: 'Retry',
            description: 'Try adding combine again',
            type: CombineErrorActionType.retry,
          ),
        ],
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Confirm normalized model and create combine
  Future<void> _onConfirmNormalizedModel(
    ConfirmNormalizedModel event,
    Emitter<CombineState> emit,
  ) async {
    try {
      await _createCombineFromMatch(
        event.userId,
        event.selectedMatch,
        event.nickname,
        event.customSettings,
        emit,
      );

      // Learn from confirmation to improve future matching
      await _normalizer.learnFromCorrection(
        event.originalInput,
        event.selectedMatch.canonical,
        event.selectedMatch.canonical,
      );

    } catch (error) {
      emit(CombineError(
        message: 'Failed to confirm combine model',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Reject normalized model and provide feedback
  Future<void> _onRejectNormalizedModel(
    RejectNormalizedModel event,
    Emitter<CombineState> emit,
  ) async {
    try {
      // Learn from rejection to improve future matching
      if (event.userProvidedCorrection != null) {
        await _normalizer.learnFromCorrection(
          event.originalInput,
          event.rejectedMatch.canonical,
          event.userProvidedCorrection!,
        );
      }

      // Return to loaded state or trigger new search
      if (state is CombineLoaded) {
        // Just return to previous state
        return;
      } else {
        // Trigger reload
        add(LoadUserCombines(userId: event.userId));
      }

    } catch (error) {
      emit(CombineError(
        message: 'Failed to process rejection',
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Update combine capabilities
  Future<void> _onUpdateCombineCapabilities(
    UpdateCombineCapabilities event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      emit(currentState.copyWith(
        syncStatus: SyncStatus.syncing,
        lastUpdated: DateTime.now(),
      ));

      // Update the combine spec with new capabilities
      final combineIndex = currentState.userCombines.indexWhere(
        (c) => c.id == event.combineId,
      );
      
      if (combineIndex == -1) {
        throw Exception('Combine not found');
      }

      final combine = currentState.userCombines[combineIndex];
      
      // Queue sync operation
      await _syncRepository.queueOperation(SyncOperation(
        id: _generateOperationId(),
        userId: combine.userId,
        operation: SyncOperationType.update,
        collection: 'user_combines',
        documentId: event.combineId,
        data: {
          'harvestCapabilities': event.harvestCapabilities?.toJson(),
          'moistureTolerance': event.moistureTolerance?.toJson(),
          'toughCropAbility': event.toughCropAbility?.toJson(),
        },
        status: SyncStatus.pending,
        retryCount: 0,
        priority: OperationPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      emit(currentState.copyWith(
        syncStatus: SyncStatus.completed,
        confidence: 0.95,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to update combine capabilities',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Update combine settings
  Future<void> _onUpdateCombineSettings(
    UpdateCombineSettings event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      final combineIndex = currentState.userCombines.indexWhere(
        (c) => c.id == event.combineId,
      );

      if (combineIndex == -1) return;

      final combine = currentState.userCombines[combineIndex];
      final updatedCombine = combine.copyWith(
        nickname: event.nickname ?? combine.nickname,
        customSettings: {...combine.customSettings, ...event.customSettings},
        isActive: event.isActive ?? combine.isActive,
        hoursOfOperation: event.hoursOfOperation ?? combine.hoursOfOperation,
        maintenanceNotes: event.maintenanceNotes ?? combine.maintenanceNotes,
        updatedAt: DateTime.now(),
      );

      final updatedCombines = List<UserCombine>.from(currentState.userCombines);
      updatedCombines[combineIndex] = updatedCombine;

      // Update active combine if this was the change
      UserCombine? newActiveCombine = currentState.activeCombine;
      if (event.isActive == true) {
        newActiveCombine = updatedCombine;
      } else if (currentState.activeCombine?.id == event.combineId && event.isActive == false) {
        newActiveCombine = null;
      }

      emit(currentState.copyWith(
        userCombines: updatedCombines,
        activeCombine: newActiveCombine,
        confidence: 0.98,
        lastUpdated: DateTime.now(),
        syncStatus: SyncStatus.pending,
      ));

      // Queue sync operation
      await _syncRepository.queueOperation(SyncOperation(
        id: _generateOperationId(),
        userId: combine.userId,
        operation: SyncOperationType.update,
        collection: 'user_combines',
        documentId: event.combineId,
        data: updatedCombine.toJson(),
        status: SyncStatus.pending,
        retryCount: 0,
        priority: OperationPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to update combine settings',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Remove combine from user's fleet
  Future<void> _onRemoveCombine(
    RemoveCombine event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      final updatedCombines = currentState.userCombines.where(
        (c) => c.id != event.combineId,
      ).toList();

      // Update active combine if it was removed
      UserCombine? newActiveCombine = currentState.activeCombine;
      if (currentState.activeCombine?.id == event.combineId) {
        newActiveCombine = updatedCombines.where((c) => c.isActive).firstOrNull;
      }

      emit(currentState.copyWith(
        userCombines: updatedCombines,
        activeCombine: newActiveCombine,
        confidence: 1.0,
        lastUpdated: DateTime.now(),
        syncStatus: SyncStatus.pending,
      ));

      // Queue delete operation
      await _syncRepository.queueOperation(SyncOperation(
        id: _generateOperationId(),
        userId: event.userId,
        operation: SyncOperationType.delete,
        collection: 'user_combines',
        documentId: event.combineId,
        data: null,
        status: SyncStatus.pending,
        retryCount: 0,
        priority: OperationPriority.high,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to remove combine',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Sync combine data with remote
  Future<void> _onSyncCombineData(
    SyncCombineData event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      emit(currentState.copyWith(
        syncStatus: SyncStatus.syncing,
        lastUpdated: DateTime.now(),
      ));

      // Execute sync operations
      await _syncService.syncUserCombines(
        event.userId,
        specificCombineIds: event.specificCombineIds,
      );

      // Reload data after sync
      add(LoadUserCombines(userId: event.userId, forceRefresh: true));

    } catch (error) {
      emit(CombineError(
        message: 'Sync failed',
        technicalDetails: error.toString(),
        recoveryActions: [
          const CombineErrorAction(
            label: 'Retry Sync',
            description: 'Try syncing again',
            type: CombineErrorActionType.syncManually,
          ),
          const CombineErrorAction(
            label: 'Continue Offline',
            description: 'Work with cached data',
            type: CombineErrorActionType.useCachedData,
          ),
        ],
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Handle sync operation completion
  Future<void> _onSyncOperationCompleted(
    SyncOperationCompleted event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    final currentState = state as CombineLoaded;
    
    if (event.status == SyncStatus.completed) {
      emit(currentState.copyWith(
        syncStatus: SyncStatus.completed,
        confidence: 1.0,
        lastUpdated: DateTime.now(),
      ));
    } else if (event.status == SyncStatus.failed && event.error != null) {
      // Add to failed operations for retry
      final failedOps = List<SyncOperation>.from(currentState.failedSyncOperations);
      
      emit(currentState.copyWith(
        failedSyncOperations: failedOps,
        syncStatus: SyncStatus.failed,
        error: event.error,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Retry failed sync operations
  Future<void> _onRetrySyncOperations(
    RetrySyncOperations event,
    Emitter<CombineState> emit,
  ) async {
    try {
      await _syncService.retryFailedOperations(
        event.userId,
        operationIds: event.specificOperationIds,
      );
    } catch (error) {
      emit(CombineError(
        message: 'Failed to retry sync operations',
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Load combine specifications
  Future<void> _onLoadCombineSpecs(
    LoadCombineSpecs event,
    Emitter<CombineState> emit,
  ) async {
    try {
      emit(CombineLoading(
        loadingType: CombineLoadingType.searchingSpecs,
        confidence: 0.8,
        lastUpdated: DateTime.now(),
      ));

      List<CombineSpec> specs;
      if (event.brand != null && event.model != null) {
        specs = await _combineRepository.getByModel(event.brand!, event.model!);
      } else if (event.brand != null) {
        specs = await _combineRepository.getByBrand(event.brand!);
      } else if (event.region != null) {
        specs = await _combineRepository.getByRegion(event.region!);
      } else {
        specs = await _combineRepository.getAll();
      }

      if (event.includePublicSpecs) {
        final publicSpecs = await _combineRepository.getPublicSpecs(
          region: event.region,
        );
        specs.addAll(publicSpecs);
      }

      if (state is CombineLoaded) {
        final currentState = state as CombineLoaded;
        emit(currentState.copyWith(
          availableSpecs: specs,
          confidence: 0.95,
          lastUpdated: DateTime.now(),
        ));
      } else {
        emit(CombineLoaded(
          userCombines: const [],
          availableSpecs: specs,
          confidence: 0.95,
          lastUpdated: DateTime.now(),
        ));
      }

    } catch (error) {
      emit(CombineError(
        message: 'Failed to load combine specifications',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Search combines with fuzzy matching
  Future<void> _onSearchCombines(
    SearchCombines event,
    Emitter<CombineState> emit,
  ) async {
    try {
      if (event.query.trim().isEmpty) {
        emit(const CombineSearchResults(
          query: '',
          results: [],
          confidence: 1.0,
          lastUpdated: DateTime.now(),
        ));
        return;
      }

      final specs = await _combineRepository.search(event.query);
      final results = specs.map((spec) => CombineSearchResult(
        spec: spec,
        relevanceScore: _calculateRelevanceScore(event.query, spec),
        matchedFields: _getMatchedFields(event.query, spec),
        matchType: MatchType.fuzzy,
      )).toList();

      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      emit(CombineSearchResults(
        query: event.query,
        results: results.take(event.maxResults).toList(),
        hasMoreResults: results.length > event.maxResults,
        confidence: 0.9,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Search failed',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Clear search results
  void _onClearSearchResults(
    ClearSearchResults event,
    Emitter<CombineState> emit,
  ) {
    if (state is CombineLoaded) {
      return; // Just return to loaded state
    }
  }

  /// Select active combine
  Future<void> _onSelectActiveCombine(
    SelectActiveCombine event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    final currentState = state as CombineLoaded;
    final selectedCombine = currentState.userCombines.firstWhere(
      (c) => c.id == event.combineId,
      orElse: () => throw Exception('Combine not found'),
    );

    // Update all combines to set only the selected one as active
    final updatedCombines = currentState.userCombines.map((combine) {
      return combine.copyWith(
        isActive: combine.id == event.combineId,
        updatedAt: DateTime.now(),
      );
    }).toList();

    emit(currentState.copyWith(
      userCombines: updatedCombines,
      activeCombine: selectedCombine.copyWith(isActive: true),
      confidence: 1.0,
      lastUpdated: DateTime.now(),
      syncStatus: SyncStatus.pending,
    ));

    // Queue sync operations for all updated combines
    for (final combine in updatedCombines) {
      await _syncRepository.queueOperation(SyncOperation(
        id: _generateOperationId(),
        userId: event.userId,
        operation: SyncOperationType.update,
        collection: 'user_combines',
        documentId: combine.id,
        data: combine.toJson(),
        status: SyncStatus.pending,
        retryCount: 0,
        priority: OperationPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Load progressive capabilities
  Future<void> _onLoadProgressiveCapabilities(
    LoadProgressiveCapabilities event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      final capability = await _loadProgressiveCapabilityData(
        event.combineSpecId,
        region: event.region,
        userId: event.userId,
      );

      if (capability != null) {
        final updatedCapabilities = Map<String, ProgressiveCapabilities>.from(
          currentState.progressiveCapabilities,
        );
        updatedCapabilities[event.combineSpecId] = capability;

        emit(currentState.copyWith(
          progressiveCapabilities: updatedCapabilities,
          confidence: 0.95,
          lastUpdated: DateTime.now(),
        ));
      }

    } catch (error) {
      // Don't emit error for capability loading failures
      // Just log and continue
    }
  }

  /// Resolve sync conflicts
  Future<void> _onResolveConflict(
    ResolveConflict event,
    Emitter<CombineState> emit,
  ) async {
    // Implementation depends on conflict resolution strategy
    // This would integrate with the sync service to resolve conflicts
    try {
      await _syncService.resolveConflict(
        event.conflictId,
        event.strategy,
        event.resolutionData,
      );

      // Trigger reload after conflict resolution
      if (state is CombineLoaded) {
        final currentState = state as CombineLoaded;
        final userCombine = currentState.userCombines.firstOrNull;
        if (userCombine != null) {
          add(LoadUserCombines(userId: userCombine.userId, forceRefresh: true));
        }
      }

    } catch (error) {
      emit(CombineError(
        message: 'Failed to resolve conflict',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Reset state to initial
  void _onResetCombineState(
    ResetCombineState event,
    Emitter<CombineState> emit,
  ) {
    emit(const CombineInitial());
  }

  /// Clear cached combine data
  Future<void> _onClearCombineCache(
    ClearCombineCache event,
    Emitter<CombineState> emit,
  ) async {
    try {
      if (event.clearAll) {
        _lastFetchTimes.clear();
        await _syncRepository.cleanupCompletedOperations();
      } else if (event.userId != null) {
        _lastFetchTimes.removeWhere((key, _) => key.contains(event.userId!));
      }

      emit(const CombineInitial());

    } catch (error) {
      emit(CombineError(
        message: 'Failed to clear cache',
        confidence: 0.0,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Helper methods

  /// Create combine from fuzzy match result
  Future<void> _createCombineFromMatch(
    String userId,
    FuzzyMatchResult match,
    String? nickname,
    Map<String, dynamic> customSettings,
    Emitter<CombineState> emit,
  ) async {
    emit(CombineLoading(
      loadingType: CombineLoadingType.addingCombine,
      progressMessage: 'Creating combine...',
      confidence: 0.8,
      lastUpdated: DateTime.now(),
    ));

    // Find or create combine spec
    final spec = await _findOrCreateCombineSpec(match.canonical);
    
    final newCombine = UserCombine(
      id: _generateCombineId(),
      userId: userId,
      combineSpecId: spec.id,
      nickname: nickname,
      customSettings: customSettings,
      isActive: true, // New combines are active by default
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to repository
    await _userCombineRepository.create(newCombine);

    // Queue sync operation
    await _syncRepository.queueOperation(SyncOperation(
      id: _generateOperationId(),
      userId: userId,
      operation: SyncOperationType.create,
      collection: 'user_combines',
      documentId: newCombine.id,
      data: newCombine.toJson(),
      status: SyncStatus.pending,
      retryCount: 0,
      priority: OperationPriority.high,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Reload user combines
    add(LoadUserCombines(userId: userId, forceRefresh: true));
  }

  /// Find or create combine specification
  Future<CombineSpec> _findOrCreateCombineSpec(String canonical) async {
    // Parse canonical name (e.g., "john_deere_x9_1100")
    final parts = canonical.split('_');
    if (parts.length < 2) throw Exception('Invalid canonical format');
    
    final brand = parts.first;
    final model = parts.skip(1).join('_');

    // Try to find existing spec
    final existingSpecs = await _combineRepository.getByModel(brand, model);
    if (existingSpecs.isNotEmpty) {
      return existingSpecs.first;
    }

    // Create new spec with default values
    final newSpec = CombineSpec(
      id: _generateSpecId(),
      brand: brand,
      model: model,
      modelVariants: [canonical],
      userId: 'system', // System-generated spec
      moistureTolerance: MoistureTolerance(
        min: 12.0,
        max: 18.0,
        optimal: 15.0,
        confidence: ConfidenceLevel.low,
      ),
      toughCropAbility: ToughCropAbility(
        rating: 7,
        crops: ['wheat', 'barley', 'canola'],
        limitations: ['Very high moisture conditions'],
        confidence: ConfidenceLevel.low,
      ),
      sourceData: SourceData(
        userReports: 0,
        manufacturerSpecs: false,
        expertValidation: false,
        lastUpdated: DateTime.now(),
      ),
      isPublic: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _combineRepository.create(newSpec);
    return newSpec;
  }

  /// Load progressive capability data based on user volume
  Future<ProgressiveCapabilities?> _loadProgressiveCapabilityData(
    String combineSpecId, {
    String? region,
    String? userId,
  }) async {
    try {
      final spec = await _combineRepository.getById(combineSpecId);
      if (spec == null) return null;

      // Get aggregated data from harvest intelligence
      final aggregatedData = await _harvestIntelligence.getCombineInsights(
        brand: spec.brand,
        model: spec.model,
        region: region,
      );

      // Determine capability level based on user count
      final userCount = aggregatedData['userCount'] as int? ?? 0;
      CapabilityLevel level;
      if (userCount >= 15) {
        level = CapabilityLevel.rich;
      } else if (userCount >= 5) {
        level = CapabilityLevel.moderate;
      } else {
        level = CapabilityLevel.minimal;
      }

      return ProgressiveCapabilities(
        level: level,
        userCount: userCount,
        basicCapabilities: spec.harvestCapabilities,
        brandCapabilities: level != CapabilityLevel.minimal
            ? BrandCapabilities(
                brand: spec.brand,
                moistureTolerance: spec.moistureTolerance,
                toughCropAbility: spec.toughCropAbility,
                performanceMetrics: Map<String, double>.from(
                  aggregatedData['brandMetrics'] ?? {},
                ),
                commonIssues: List<String>.from(
                  aggregatedData['commonIssues'] ?? [],
                ),
                recommendations: List<String>.from(
                  aggregatedData['brandRecommendations'] ?? [],
                ),
              )
            : null,
        modelCapabilities: level == CapabilityLevel.rich
            ? ModelCapabilities(
                brand: spec.brand,
                model: spec.model,
                harvestCapabilities: spec.harvestCapabilities ?? HarvestCapabilities(
                  operatingSpeedKmh: 8.0,
                  grainTankCapacityL: 15000,
                  unloadingRateLS: 120,
                  fuelConsumptionLh: 45,
                  dailyCapacityHa: 150,
                  reliabilityRating: 8,
                  maintenanceComplexity: 6,
                ),
                moistureTolerance: spec.moistureTolerance,
                toughCropAbility: spec.toughCropAbility,
                performanceData: Map<String, dynamic>.from(
                  aggregatedData['modelData'] ?? {},
                ),
                peerComparison: aggregatedData['peerComparison'] != null
                    ? PeerComparison(
                        betterThan: List<String>.from(
                          aggregatedData['peerComparison']['betterThan'] ?? [],
                        ),
                        similarTo: List<String>.from(
                          aggregatedData['peerComparison']['similarTo'] ?? [],
                        ),
                        challengedBy: List<String>.from(
                          aggregatedData['peerComparison']['challengedBy'] ?? [],
                        ),
                      )
                    : null,
                expertRecommendations: List<String>.from(
                  aggregatedData['expertRecommendations'] ?? [],
                ),
              )
            : null,
        dataConfidence: (aggregatedData['confidence'] as num?)?.toDouble() ?? 0.5,
        lastAggregated: DateTime.now(),
      );

    } catch (error) {
      return null; // Return null on error, don't crash the app
    }
  }

  /// Check if cached data is still fresh
  bool _isDataFresh(String cacheKey) {
    final lastFetch = _lastFetchTimes[cacheKey];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheValidDuration;
  }

  /// Calculate relevance score for search results
  double _calculateRelevanceScore(String query, CombineSpec spec) {
    final normalizedQuery = query.toLowerCase();
    double score = 0.0;

    // Brand match
    if (spec.brand.toLowerCase().contains(normalizedQuery)) {
      score += 0.4;
    }

    // Model match
    if (spec.model.toLowerCase().contains(normalizedQuery)) {
      score += 0.4;
    }

    // Variant match
    for (final variant in spec.modelVariants) {
      if (variant.toLowerCase().contains(normalizedQuery)) {
        score += 0.2;
        break;
      }
    }

    return score;
  }

  /// Get matched fields for search results
  List<String> _getMatchedFields(String query, CombineSpec spec) {
    final normalizedQuery = query.toLowerCase();
    final matchedFields = <String>[];

    if (spec.brand.toLowerCase().contains(normalizedQuery)) {
      matchedFields.add('brand');
    }
    if (spec.model.toLowerCase().contains(normalizedQuery)) {
      matchedFields.add('model');
    }
    for (final variant in spec.modelVariants) {
      if (variant.toLowerCase().contains(normalizedQuery)) {
        matchedFields.add('variant');
        break;
      }
    }

    return matchedFields;
  }

  /// Generate unique IDs
  String _generateCombineId() => 'combine_${DateTime.now().millisecondsSinceEpoch}';
  String _generateSpecId() => 'spec_${DateTime.now().millisecondsSinceEpoch}';
  String _generateOperationId() => 'op_${DateTime.now().millisecondsSinceEpoch}';

  /// Event transformers for performance optimization
  EventTransformer<T> _debounceTransformer<T>() {
    return (events, mapper) => events.debounce(const Duration(milliseconds: 300)).switchMap(mapper);
  }

  EventTransformer<T> _throttleTransformer<T>() {
    return (events, mapper) => events.throttle(const Duration(seconds: 1)).switchMap(mapper);
  }

  /// Hydrated bloc persistence
  @override
  CombineState? fromJson(Map<String, dynamic> json) {
    try {
      final stateType = json['type'] as String?;
      
      switch (stateType) {
        case 'CombineLoaded':
          return CombineLoaded(
            userCombines: (json['userCombines'] as List)
                .map((e) => UserCombine.fromJson(e))
                .toList(),
            availableSpecs: (json['availableSpecs'] as List)
                .map((e) => CombineSpec.fromJson(e))
                .toList(),
            activeCombine: json['activeCombine'] != null
                ? UserCombine.fromJson(json['activeCombine'])
                : null,
            progressiveCapabilities: {},  // Don't persist capabilities
            confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
            lastUpdated: DateTime.parse(json['lastUpdated'] as String),
            isFromCache: json['isFromCache'] as bool? ?? true,
            syncStatus: SyncStatus.values.firstWhere(
              (e) => e.name == json['syncStatus'],
              orElse: () => SyncStatus.pending,
            ),
            error: json['error'] as String?,
          );
        default:
          return const CombineInitial();
      }
    } catch (e) {
      return const CombineInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(CombineState state) {
    switch (state.runtimeType) {
      case CombineLoaded:
        final loadedState = state as CombineLoaded;
        return {
          'type': 'CombineLoaded',
          'userCombines': loadedState.userCombines.map((e) => e.toJson()).toList(),
          'availableSpecs': loadedState.availableSpecs.map((e) => e.toJson()).toList(),
          'activeCombine': loadedState.activeCombine?.toJson(),
          'confidence': loadedState.confidence,
          'lastUpdated': loadedState.lastUpdated.toIso8601String(),
          'isFromCache': loadedState.isFromCache,
          'syncStatus': loadedState.syncStatus.name,
          'error': loadedState.error,
        };
      default:
        return null; // Don't persist other states
    }
  }

  /// Calculate equipment factors for a combine
  Future<void> _onCalculateEquipmentFactors(
    CalculateEquipmentFactors event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      emit(CombineLoading(
        loadingType: CombineLoadingType.loadingCapabilities,
        progressMessage: 'Calculating equipment factors...',
        confidence: 0.8,
        lastUpdated: DateTime.now(),
      ));

      // Get combine spec
      final spec = await _combineRepository.getById(event.combineSpecId);
      if (spec == null) {
        throw Exception('Combine specification not found');
      }

      // Get weather data if location provided
      WeatherData? weatherData;
      if (event.weatherLocationId != null) {
        try {
          // This would need integration with weather service
          // For now, use mock data or skip weather integration
          weatherData = null;
        } catch (e) {
          // Continue without weather data
        }
      }

      // Perform equipment factor analysis
      final analysis = EquipmentFactorAnalysis.analyze(
        spec: spec,
        weather: weatherData,
        crop: event.crop,
        weatherLocationId: event.weatherLocationId,
        customWeights: event.customWeights,
      );

      // Update state with new analysis
      final updatedAnalyses = Map<String, EquipmentFactorAnalysis>.from(
        currentState.equipmentFactorAnalyses,
      );
      updatedAnalyses[event.combineSpecId] = analysis;

      emit(currentState.copyWith(
        equipmentFactorAnalyses: updatedAnalyses,
        confidence: 0.95,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to calculate equipment factors',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Update equipment factors for a combine
  Future<void> _onUpdateEquipmentFactors(
    UpdateEquipmentFactors event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      // Find existing analysis and update it
      final existingAnalysis = currentState.equipmentFactorAnalyses[event.combineSpecId];
      if (existingAnalysis == null) {
        throw Exception('Equipment factor analysis not found for combine');
      }

      // Create updated analysis
      final updatedAnalysis = EquipmentFactorAnalysis(
        combineSpecId: event.combineSpecId,
        factors: event.factors,
        overallPerformanceMultiplier: event.overallMultiplier,
        factorWeights: existingAnalysis.factorWeights,
        analyzedAt: DateTime.now(),
        weatherLocationId: existingAnalysis.weatherLocationId,
        crop: existingAnalysis.crop,
      );

      // Update state
      final updatedAnalyses = Map<String, EquipmentFactorAnalysis>.from(
        currentState.equipmentFactorAnalyses,
      );
      updatedAnalyses[event.combineSpecId] = updatedAnalysis;

      emit(currentState.copyWith(
        equipmentFactorAnalyses: updatedAnalyses,
        confidence: 0.95,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to update equipment factors',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Refresh equipment factors for all user combines
  Future<void> _onRefreshEquipmentFactors(
    RefreshEquipmentFactors event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      emit(CombineLoading(
        loadingType: CombineLoadingType.loadingCapabilities,
        progressMessage: 'Refreshing equipment factors for all combines...',
        confidence: 0.7,
        lastUpdated: DateTime.now(),
      ));

      final updatedAnalyses = <String, EquipmentFactorAnalysis>{};

      // Calculate factors for each user combine
      for (final combine in currentState.userCombines) {
        try {
          final spec = await _combineRepository.getById(combine.combineSpecId);
          if (spec != null) {
            // Get weather data if location provided
            WeatherData? weatherData;
            if (event.weatherLocationId != null) {
              try {
                // Integration with weather service would go here
                weatherData = null;
              } catch (e) {
                // Continue without weather data
              }
            }

            final analysis = EquipmentFactorAnalysis.analyze(
              spec: spec,
              weather: weatherData,
              crop: event.crop,
              weatherLocationId: event.weatherLocationId,
            );

            updatedAnalyses[combine.combineSpecId] = analysis;
          }
        } catch (e) {
          // Continue with other combines if one fails
          continue;
        }
      }

      emit(currentState.copyWith(
        equipmentFactorAnalyses: updatedAnalyses,
        confidence: 0.9,
        lastUpdated: DateTime.now(),
      ));

    } catch (error) {
      emit(CombineError(
        message: 'Failed to refresh equipment factors',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  /// Apply equipment factors to harvest capabilities
  Future<void> _onApplyEquipmentFactorsToCapabilities(
    ApplyEquipmentFactorsToCapabilities event,
    Emitter<CombineState> emit,
  ) async {
    if (state is! CombineLoaded) return;

    try {
      final currentState = state as CombineLoaded;
      
      // Find the combine spec to update
      final specIndex = currentState.availableSpecs.indexWhere(
        (spec) => spec.id == event.combineSpecId,
      );

      if (specIndex == -1) {
        throw Exception('Combine specification not found');
      }

      final spec = currentState.availableSpecs[specIndex];
      
      // Apply equipment factors to harvest capabilities
      if (spec.harvestCapabilities != null) {
        final updatedCapabilities = spec.harvestCapabilities!.applyEquipmentFactors(event.factors);
        
        final updatedSpec = spec.copyWith(
          harvestCapabilities: updatedCapabilities,
          updatedAt: DateTime.now(),
        );

        // Update the specs list
        final updatedSpecs = List<CombineSpec>.from(currentState.availableSpecs);
        updatedSpecs[specIndex] = updatedSpec;

        emit(currentState.copyWith(
          availableSpecs: updatedSpecs,
          confidence: 0.95,
          lastUpdated: DateTime.now(),
        ));

        // Queue sync operation for the updated capabilities
        await _syncRepository.queueOperation(SyncOperation(
          id: _generateOperationId(),
          userId: 'system',
          operation: SyncOperationType.update,
          collection: 'combine_specs',
          documentId: event.combineSpecId,
          data: updatedSpec.toJson(),
          status: SyncStatus.pending,
          retryCount: 0,
          priority: OperationPriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

    } catch (error) {
      emit(CombineError(
        message: 'Failed to apply equipment factors to capabilities',
        technicalDetails: error.toString(),
        confidence: 0.0,
        lastUpdated: DateTime.now(),
        previousState: state,
      ));
    }
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }
}