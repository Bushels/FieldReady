/**
 * CombineSyncManager - Advanced sync queue and conflict resolution system
 * Handles priority-based sync operations, conflict detection, and resolution strategies
 * Integrates with CombineBloc for seamless offline-first experience
 */

import 'dart:async';
import 'dart:math';
import '../../../domain/models/combine_models.dart';
import '../../../domain/repositories/combine_repository.dart';
import '../../../domain/services/sync_service.dart';
import 'combine_state.dart';
import 'combine_event.dart';

/// Advanced sync manager for combine data with intelligent conflict resolution
class CombineSyncManager {
  final SyncRepository _syncRepository;
  final UserCombineRepository _userCombineRepository;
  final CombineRepository _combineRepository;
  final SyncService _syncService;

  // Sync configuration
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  static const int _batchSize = 10;

  // Active sync operations tracking
  final Map<String, StreamController<SyncProgress>> _activeSyncs = {};
  final Map<String, Timer> _retryTimers = {};

  CombineSyncManager({
    required SyncRepository syncRepository,
    required UserCombineRepository userCombineRepository,
    required CombineRepository combineRepository,
    required SyncService syncService,
  })  : _syncRepository = syncRepository,
        _userCombineRepository = userCombineRepository,
        _combineRepository = combineRepository,
        _syncService = syncService;

  /// Start comprehensive sync for user combines
  Future<SyncResult> syncUserCombines(
    String userId, {
    List<String>? specificCombineIds,
    SyncPriority priority = SyncPriority.normal,
    bool resolveConflictsAutomatically = true,
  }) async {
    final syncId = _generateSyncId();
    final progressController = StreamController<SyncProgress>.broadcast();
    _activeSyncs[syncId] = progressController;

    try {
      // Step 1: Queue pending operations
      await _queuePendingOperations(userId, specificCombineIds, priority);
      
      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.queueing,
        progress: 0.1,
        message: 'Queueing operations...',
      ));

      // Step 2: Process sync queue with priority ordering
      final queuedOperations = await _getQueuedOperations(userId, priority);
      
      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.processing,
        progress: 0.2,
        message: 'Processing ${queuedOperations.length} operations...',
      ));

      // Step 3: Execute operations in batches
      final results = await _executeSyncOperations(
        queuedOperations,
        progressController,
        syncId,
      );

      // Step 4: Detect and handle conflicts
      final conflicts = await _detectConflicts(results, userId);
      
      if (conflicts.isNotEmpty) {
        progressController.add(SyncProgress(
          syncId: syncId,
          phase: SyncPhase.conflictResolution,
          progress: 0.8,
          message: 'Resolving ${conflicts.length} conflicts...',
        ));

        if (resolveConflictsAutomatically) {
          await _resolveConflictsAutomatically(conflicts);
        } else {
          // Return conflicts for manual resolution
          return SyncResult(
            syncId: syncId,
            status: SyncResultStatus.conflictsDetected,
            conflicts: conflicts,
            processedOperations: results.length,
            message: 'Manual conflict resolution required',
          );
        }
      }

      // Step 5: Finalize sync
      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.finalizing,
        progress: 0.95,
        message: 'Finalizing sync...',
      ));

      await _finalizeSyncOperations(results);

      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.completed,
        progress: 1.0,
        message: 'Sync completed successfully',
      ));

      return SyncResult(
        syncId: syncId,
        status: SyncResultStatus.success,
        processedOperations: results.length,
        resolvedConflicts: conflicts.length,
        message: 'Sync completed successfully',
      );

    } catch (error) {
      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.failed,
        progress: 0.0,
        message: 'Sync failed: ${error.toString()}',
        error: error.toString(),
      ));

      return SyncResult(
        syncId: syncId,
        status: SyncResultStatus.failed,
        error: error.toString(),
        message: 'Sync failed',
      );
    } finally {
      await progressController.close();
      _activeSyncs.remove(syncId);
    }
  }

  /// Queue pending operations with intelligent batching
  Future<void> _queuePendingOperations(
    String userId,
    List<String>? specificCombineIds,
    SyncPriority priority,
  ) async {
    // Get user combines that need syncing
    final userCombines = specificCombineIds != null
        ? (await _userCombineRepository.getByUserId(userId))
            .where((c) => specificCombineIds.contains(c.id))
            .toList()
        : await _userCombineRepository.getPendingSync();

    // Queue create/update operations for each combine
    for (final combine in userCombines) {
      final operationType = combine.createdAt == combine.updatedAt
          ? SyncOperationType.create
          : SyncOperationType.update;

      await _syncRepository.queueOperation(SyncOperation(
        id: _generateOperationId(),
        userId: userId,
        operation: operationType,
        collection: 'user_combines',
        documentId: combine.id,
        data: combine.toJson(),
        status: SyncStatus.pending,
        retryCount: 0,
        priority: _mapSyncPriorityToOperationPriority(priority),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Get queued operations sorted by priority
  Future<List<SyncOperation>> _getQueuedOperations(
    String userId,
    SyncPriority priority,
  ) async {
    final pendingOps = await _syncRepository.getPendingOperations(userId);
    final failedOps = await _syncRepository.getFailedOperations(userId);
    
    final allOps = [...pendingOps, ...failedOps];
    
    // Sort by priority and creation time
    allOps.sort((a, b) {
      final priorityComparison = _getPriorityWeight(b.priority)
          .compareTo(_getPriorityWeight(a.priority));
      if (priorityComparison != 0) return priorityComparison;
      
      return a.createdAt.compareTo(b.createdAt);
    });

    return allOps;
  }

  /// Execute sync operations in batches with retry logic
  Future<List<SyncOperationResult>> _executeSyncOperations(
    List<SyncOperation> operations,
    StreamController<SyncProgress> progressController,
    String syncId,
  ) async {
    final results = <SyncOperationResult>[];
    final totalOperations = operations.length;
    
    for (int i = 0; i < operations.length; i += _batchSize) {
      final batch = operations.skip(i).take(_batchSize).toList();
      
      // Update progress
      final progress = 0.2 + (i / totalOperations) * 0.6;
      progressController.add(SyncProgress(
        syncId: syncId,
        phase: SyncPhase.processing,
        progress: progress,
        message: 'Processing batch ${(i / _batchSize).floor() + 1}...',
      ));

      // Execute batch
      final batchResults = await _executeBatch(batch);
      results.addAll(batchResults);

      // Small delay between batches to prevent overwhelming the server
      if (i + _batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Execute a batch of sync operations
  Future<List<SyncOperationResult>> _executeBatch(
    List<SyncOperation> batch,
  ) async {
    final results = <SyncOperationResult>[];

    await Future.wait(batch.map((operation) async {
      try {
        final result = await _executeSingleOperation(operation);
        results.add(result);
        
        // Mark operation as completed
        await _syncRepository.markOperationComplete(operation.id);
        
      } catch (error) {
        // Handle operation failure
        results.add(SyncOperationResult(
          operation: operation,
          success: false,
          error: error.toString(),
        ));

        // Implement exponential backoff retry
        await _scheduleRetry(operation, error);
      }
    }));

    return results;
  }

  /// Execute a single sync operation
  Future<SyncOperationResult> _executeSingleOperation(
    SyncOperation operation,
  ) async {
    switch (operation.operation) {
      case SyncOperationType.create:
        return await _executeCreateOperation(operation);
      case SyncOperationType.update:
        return await _executeUpdateOperation(operation);
      case SyncOperationType.delete:
        return await _executeDeleteOperation(operation);
    }
  }

  /// Execute create operation
  Future<SyncOperationResult> _executeCreateOperation(
    SyncOperation operation,
  ) async {
    try {
      if (operation.collection == 'user_combines' && operation.data != null) {
        final combine = UserCombine.fromJson(operation.data!);
        await _syncService.createUserCombine(combine);
        
        return SyncOperationResult(
          operation: operation,
          success: true,
          resultData: combine.toJson(),
        );
      }
      
      throw Exception('Invalid create operation data');
    } catch (error) {
      return SyncOperationResult(
        operation: operation,
        success: false,
        error: error.toString(),
      );
    }
  }

  /// Execute update operation
  Future<SyncOperationResult> _executeUpdateOperation(
    SyncOperation operation,
  ) async {
    try {
      if (operation.collection == 'user_combines' && operation.data != null) {
        final combine = UserCombine.fromJson(operation.data!);
        await _syncService.updateUserCombine(combine);
        
        return SyncOperationResult(
          operation: operation,
          success: true,
          resultData: combine.toJson(),
        );
      }
      
      throw Exception('Invalid update operation data');
    } catch (error) {
      return SyncOperationResult(
        operation: operation,
        success: false,
        error: error.toString(),
      );
    }
  }

  /// Execute delete operation
  Future<SyncOperationResult> _executeDeleteOperation(
    SyncOperation operation,
  ) async {
    try {
      await _syncService.deleteUserCombine(operation.documentId);
      
      return SyncOperationResult(
        operation: operation,
        success: true,
      );
    } catch (error) {
      return SyncOperationResult(
        operation: operation,
        success: false,
        error: error.toString(),
      );
    }
  }

  /// Detect conflicts between local and remote data
  Future<List<CombineConflict>> _detectConflicts(
    List<SyncOperationResult> results,
    String userId,
  ) async {
    final conflicts = <CombineConflict>[];

    for (final result in results.where((r) => !r.success)) {
      if (result.error?.contains('conflict') == true ||
          result.error?.contains('version') == true) {
        
        // Fetch remote data for comparison
        final remoteData = await _fetchRemoteData(
          result.operation.collection,
          result.operation.documentId,
        );

        if (remoteData != null) {
          final conflict = CombineConflict(
            id: _generateConflictId(),
            combineId: result.operation.documentId,
            type: _determineConflictType(result.operation),
            localData: result.operation.data,
            remoteData: remoteData,
            localTimestamp: result.operation.updatedAt,
            remoteTimestamp: remoteData['updatedAt'] != null
                ? DateTime.parse(remoteData['updatedAt'])
                : DateTime.now(),
            localConfidence: _calculateDataConfidence(result.operation.data),
            remoteConfidence: _calculateDataConfidence(remoteData),
          );

          conflicts.add(conflict);
        }
      }
    }

    return conflicts;
  }

  /// Automatically resolve conflicts using intelligent strategies
  Future<void> _resolveConflictsAutomatically(
    List<CombineConflict> conflicts,
  ) async {
    for (final conflict in conflicts) {
      final strategy = _determineAutoResolutionStrategy(conflict);
      await _applyConflictResolution(conflict, strategy);
    }
  }

  /// Determine the best automatic resolution strategy
  ConflictResolutionStrategy _determineAutoResolutionStrategy(
    CombineConflict conflict,
  ) {
    // Strategy 1: Use higher confidence data
    if ((conflict.localConfidence - conflict.remoteConfidence).abs() > 0.2) {
      return conflict.localConfidence > conflict.remoteConfidence
          ? ConflictResolutionStrategy.useLocal
          : ConflictResolutionStrategy.useRemote;
    }

    // Strategy 2: Use more recent data
    if (conflict.localTimestamp.isAfter(conflict.remoteTimestamp)) {
      return ConflictResolutionStrategy.useLocal;
    } else if (conflict.remoteTimestamp.isAfter(conflict.localTimestamp)) {
      return ConflictResolutionStrategy.useRemote;
    }

    // Strategy 3: Attempt intelligent merge for compatible data
    if (_canMergeData(conflict)) {
      return ConflictResolutionStrategy.merge;
    }

    // Default: Use local data (last-write-wins with local preference)
    return ConflictResolutionStrategy.useLocal;
  }

  /// Apply conflict resolution strategy
  Future<void> _applyConflictResolution(
    CombineConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        await _applyLocalData(conflict);
        break;
      case ConflictResolutionStrategy.useRemote:
        await _applyRemoteData(conflict);
        break;
      case ConflictResolutionStrategy.merge:
        await _applyMergedData(conflict);
        break;
      case ConflictResolutionStrategy.useHigherConfidence:
        await _applyHigherConfidenceData(conflict);
        break;
      case ConflictResolutionStrategy.manualResolve:
        // This should be handled by the UI
        break;
    }
  }

  /// Apply local data resolution
  Future<void> _applyLocalData(CombineConflict conflict) async {
    if (conflict.localData != null) {
      final combine = UserCombine.fromJson(conflict.localData);
      await _syncService.forceUpdateUserCombine(combine);
    }
  }

  /// Apply remote data resolution
  Future<void> _applyRemoteData(CombineConflict conflict) async {
    final remoteData = conflict.remoteData as Map<String, dynamic>;
    final combine = UserCombine.fromJson(remoteData);
    await _userCombineRepository.update(conflict.combineId, combine);
  }

  /// Apply merged data resolution
  Future<void> _applyMergedData(CombineConflict conflict) async {
    final localData = conflict.localData as Map<String, dynamic>;
    final remoteData = conflict.remoteData as Map<String, dynamic>;
    
    final mergedData = _mergeUserCombineData(localData, remoteData);
    final combine = UserCombine.fromJson(mergedData);
    
    await _syncService.forceUpdateUserCombine(combine);
  }

  /// Apply higher confidence data resolution
  Future<void> _applyHigherConfidenceData(CombineConflict conflict) async {
    if (conflict.localConfidence > conflict.remoteConfidence) {
      await _applyLocalData(conflict);
    } else {
      await _applyRemoteData(conflict);
    }
  }

  /// Intelligent merge of user combine data
  Map<String, dynamic> _mergeUserCombineData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(remote);

    // Merge custom settings (combine both)
    if (local['customSettings'] != null && remote['customSettings'] != null) {
      merged['customSettings'] = {
        ...remote['customSettings'],
        ...local['customSettings'], // Local takes precedence
      };
    } else if (local['customSettings'] != null) {
      merged['customSettings'] = local['customSettings'];
    }

    // Merge maintenance notes (combine arrays)
    if (local['maintenanceNotes'] != null && remote['maintenanceNotes'] != null) {
      final localNotes = List<String>.from(local['maintenanceNotes']);
      final remoteNotes = List<String>.from(remote['maintenanceNotes']);
      merged['maintenanceNotes'] = [...remoteNotes, ...localNotes].toSet().toList();
    } else if (local['maintenanceNotes'] != null) {
      merged['maintenanceNotes'] = local['maintenanceNotes'];
    }

    // Use more recent timestamp
    final localTime = DateTime.parse(local['updatedAt']);
    final remoteTime = DateTime.parse(remote['updatedAt']);
    if (localTime.isAfter(remoteTime)) {
      merged['updatedAt'] = local['updatedAt'];
    }

    // Prefer local nickname if set
    if (local['nickname'] != null && local['nickname'].toString().trim().isNotEmpty) {
      merged['nickname'] = local['nickname'];
    }

    // Use higher hours of operation
    if (local['hoursOfOperation'] != null && remote['hoursOfOperation'] != null) {
      merged['hoursOfOperation'] = max(
        local['hoursOfOperation'] as int,
        remote['hoursOfOperation'] as int,
      );
    } else if (local['hoursOfOperation'] != null) {
      merged['hoursOfOperation'] = local['hoursOfOperation'];
    }

    return merged;
  }

  /// Schedule retry with exponential backoff
  Future<void> _scheduleRetry(SyncOperation operation, dynamic error) async {
    final retryCount = operation.retryCount + 1;
    
    if (retryCount >= _maxRetries) {
      await _syncRepository.markOperationFailed(operation.id, error.toString());
      return;
    }

    // Calculate delay with exponential backoff and jitter
    final baseDelay = _baseRetryDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(2, retryCount);
    final jitter = Random().nextInt(1000); // 0-1000ms jitter
    final totalDelayMs = min(
      exponentialDelay + jitter,
      _maxRetryDelay.inMilliseconds,
    );

    // Update retry count
    await _syncRepository.incrementRetryCount(operation.id);

    // Schedule retry
    _retryTimers[operation.id] = Timer(
      Duration(milliseconds: totalDelayMs.toInt()),
      () async {
        _retryTimers.remove(operation.id);
        // Re-queue the operation
        final updatedOperation = operation.copyWith(
          status: SyncStatus.pending,
          retryCount: retryCount,
          updatedAt: DateTime.now(),
        );
        await _syncRepository.queueOperation(updatedOperation);
      },
    );
  }

  /// Finalize sync operations
  Future<void> _finalizeSyncOperations(List<SyncOperationResult> results) async {
    // Clean up completed operations
    await _syncRepository.cleanupCompletedOperations();
    
    // Update sync timestamps
    for (final result in results.where((r) => r.success)) {
      if (result.operation.collection == 'user_combines') {
        final combine = await _userCombineRepository.getById(
          result.operation.documentId,
        );
        if (combine != null) {
          await _userCombineRepository.update(
            result.operation.documentId,
            combine.copyWith(lastSyncAt: DateTime.now()),
          );
        }
      }
    }
  }

  /// Helper methods

  /// Fetch remote data for conflict detection
  Future<Map<String, dynamic>?> _fetchRemoteData(
    String collection,
    String documentId,
  ) async {
    try {
      if (collection == 'user_combines') {
        final combine = await _syncService.fetchUserCombine(documentId);
        return combine?.toJson();
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  /// Determine conflict type from operation
  ConflictType _determineConflictType(SyncOperation operation) {
    if (operation.data != null) {
      final data = operation.data!;
      if (data.containsKey('customSettings')) {
        return ConflictType.customSettings;
      } else if (data.containsKey('maintenanceNotes')) {
        return ConflictType.maintenanceNotes;
      } else if (data.containsKey('harvestCapabilities')) {
        return ConflictType.capabilities;
      }
    }
    return ConflictType.combineSettings;
  }

  /// Calculate data confidence based on completeness and recency
  double _calculateDataConfidence(dynamic data) {
    if (data == null) return 0.0;
    
    final map = data as Map<String, dynamic>;
    double confidence = 0.5; // Base confidence
    
    // Boost confidence for complete data
    if (map['nickname'] != null && map['nickname'].toString().trim().isNotEmpty) {
      confidence += 0.1;
    }
    if (map['customSettings'] != null && (map['customSettings'] as Map).isNotEmpty) {
      confidence += 0.15;
    }
    if (map['maintenanceNotes'] != null && (map['maintenanceNotes'] as List).isNotEmpty) {
      confidence += 0.1;
    }
    if (map['hoursOfOperation'] != null) {
      confidence += 0.1;
    }
    
    // Boost confidence for recent data
    if (map['updatedAt'] != null) {
      final updatedAt = DateTime.parse(map['updatedAt']);
      final age = DateTime.now().difference(updatedAt);
      if (age.inDays < 1) {
        confidence += 0.15;
      } else if (age.inDays < 7) {
        confidence += 0.1;
      } else if (age.inDays < 30) {
        confidence += 0.05;
      }
    }
    
    return min(confidence, 1.0);
  }

  /// Check if data can be merged intelligently
  bool _canMergeData(CombineConflict conflict) {
    // Can merge if both have different non-conflicting fields
    return conflict.type == ConflictType.customSettings ||
           conflict.type == ConflictType.maintenanceNotes;
  }

  /// Map sync priority to operation priority
  OperationPriority _mapSyncPriorityToOperationPriority(SyncPriority priority) {
    switch (priority) {
      case SyncPriority.high:
        return OperationPriority.high;
      case SyncPriority.normal:
        return OperationPriority.medium;
      case SyncPriority.low:
        return OperationPriority.low;
    }
  }

  /// Get priority weight for sorting
  int _getPriorityWeight(OperationPriority priority) {
    switch (priority) {
      case OperationPriority.high:
        return 3;
      case OperationPriority.medium:
        return 2;
      case OperationPriority.low:
        return 1;
    }
  }

  /// Generate unique IDs
  String _generateSyncId() => 'sync_${DateTime.now().millisecondsSinceEpoch}';
  String _generateOperationId() => 'op_${DateTime.now().millisecondsSinceEpoch}';
  String _generateConflictId() => 'conflict_${DateTime.now().millisecondsSinceEpoch}';

  /// Get sync progress stream
  Stream<SyncProgress>? getSyncProgress(String syncId) {
    return _activeSyncs[syncId]?.stream;
  }

  /// Cancel active sync
  Future<void> cancelSync(String syncId) async {
    final controller = _activeSyncs[syncId];
    if (controller != null) {
      await controller.close();
      _activeSyncs.remove(syncId);
    }
  }

  /// Clean up resources
  void dispose() {
    for (final controller in _activeSyncs.values) {
      controller.close();
    }
    _activeSyncs.clear();
    
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
  }
}

/// Supporting classes and enums

/// Sync priority levels
enum SyncPriority { high, normal, low }

/// Sync result status
enum SyncResultStatus {
  success,
  failed,
  conflictsDetected,
  partialSuccess,
}

/// Sync phases
enum SyncPhase {
  queueing,
  processing,
  conflictResolution,
  finalizing,
  completed,
  failed,
}

/// Sync progress information
class SyncProgress {
  final String syncId;
  final SyncPhase phase;
  final double progress; // 0.0 to 1.0
  final String message;
  final String? error;

  const SyncProgress({
    required this.syncId,
    required this.phase,
    required this.progress,
    required this.message,
    this.error,
  });
}

/// Sync operation result
class SyncOperationResult {
  final SyncOperation operation;
  final bool success;
  final String? error;
  final Map<String, dynamic>? resultData;

  const SyncOperationResult({
    required this.operation,
    required this.success,
    this.error,
    this.resultData,
  });
}

/// Overall sync result
class SyncResult {
  final String syncId;
  final SyncResultStatus status;
  final int processedOperations;
  final int resolvedConflicts;
  final List<CombineConflict> conflicts;
  final String message;
  final String? error;

  const SyncResult({
    required this.syncId,
    required this.status,
    this.processedOperations = 0,
    this.resolvedConflicts = 0,
    this.conflicts = const [],
    required this.message,
    this.error,
  });
}

/// Extension for SyncOperation copyWith
extension SyncOperationExtension on SyncOperation {
  SyncOperation copyWith({
    String? id,
    String? userId,
    SyncOperationType? operation,
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
    SyncStatus? status,
    int? retryCount,
    DateTime? lastAttempt,
    String? error,
    OperationPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      operation: operation ?? this.operation,
      collection: collection ?? this.collection,
      documentId: documentId ?? this.documentId,
      data: data ?? this.data,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      error: error ?? this.error,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}