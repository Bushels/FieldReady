/**
 * Offline-First Sync Service for FieldFirst Combine System
 * Implements robust sync queue with conflict resolution and exponential backoff
 * Handles intermittent connectivity typical in rural agricultural settings
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repositories/combine_repository.dart';
import '../repositories/base_repositories.dart';
import '../models/combine_models.dart';
import '../models/common_types.dart';

class SyncService {
  final SyncRepository _syncRepository;
  final CombineRepository _combineRepository;
  final UserCombineRepository _userCombineRepository;
  final CacheRepository _cacheRepository;
  final AuditRepository _auditRepository;
  
  bool _isSyncing = false;
  bool _isOnline = false;
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxRetries = 5;
  static const int _baseDelaySeconds = 2;
  
  StreamController<SyncEvent>? _syncEventsController;
  Stream<SyncEvent>? _syncEventsStream;

  SyncService({
    required SyncRepository syncRepository,
    required CombineRepository combineRepository,
    required UserCombineRepository userCombineRepository,
    required CacheRepository cacheRepository,
    required AuditRepository auditRepository,
  }) : _syncRepository = syncRepository,
       _combineRepository = combineRepository,
       _userCombineRepository = userCombineRepository,
       _cacheRepository = cacheRepository,
       _auditRepository = auditRepository;

  /// Initialize sync service and start monitoring connectivity
  Future<void> initialize() async {
    _syncEventsController = StreamController<SyncEvent>.broadcast();
    _syncEventsStream = _syncEventsController!.stream;
    
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Start periodic sync timer
    _startSyncTimer();
    
    // Start network heartbeat
    _startHeartbeat();
    
    _emitEvent(SyncEvent.initialized());
  }

  /// Get sync events stream for UI updates
  Stream<SyncEvent> get syncEvents => _syncEventsStream!;

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Queue a sync operation for later processing
  Future<String> queueOperation({
    required String userId,
    required SyncOperationType operation,
    required String collection,
    required String documentId,
    Map<String, dynamic>? data,
    OperationPriority priority = OperationPriority.medium,
  }) async {
    final syncOperation = SyncOperation(
      id: _generateOperationId(),
      userId: userId,
      operation: operation,
      collection: collection,
      documentId: documentId,
      data: data,
      status: SyncStatus.pending,
      retryCount: 0,
      priority: priority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final operationId = await _syncRepository.queueOperation(syncOperation);
    
    // Log the queued operation
    await _auditRepository.logEvent(AuditLog(
      id: _generateAuditId(),
      userId: userId,
      action: 'queue_sync_operation',
      collection: 'syncOperations',
      documentId: operationId,
      changes: {
        'operation': operation.toString(),
        'collection': collection,
        'documentId': documentId,
        'priority': priority.toString(),
      },
      timestamp: DateTime.now(),
      complianceLevel: ComplianceLevel.system,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    _emitEvent(SyncEvent.operationQueued(operationId, operation, collection));

    // Try immediate sync if online
    if (_isOnline && !_isSyncing) {
      unawaited(_performSync(userId));
    }

    return operationId;
  }

  /// Force immediate sync for a user
  Future<void> forceSyncUser(String userId) async {
    if (_isSyncing) {
      _emitEvent(SyncEvent.syncSkipped('Sync already in progress'));
      return;
    }

    await _performSync(userId);
  }

  /// Sync all pending operations
  Future<void> syncAll() async {
    if (_isSyncing) {
      _emitEvent(SyncEvent.syncSkipped('Sync already in progress'));
      return;
    }

    // Get all users with pending operations
    final pendingOps = await _syncRepository.getPendingOperations(''); // All users
    final userIds = pendingOps.map((op) => op.userId).toSet();

    for (final userId in userIds) {
      await _performSync(userId);
    }
  }

  /// Get sync status for a user
  Future<UserSyncStatus> getUserSyncStatus(String userId) async {
    final syncStatus = await _syncRepository.getSyncStatus(userId);
    final pendingOps = await _syncRepository.getPendingOperations(userId);
    final failedOps = await _syncRepository.getFailedOperations(userId);

    return UserSyncStatus(
      userId: userId,
      isOnline: _isOnline,
      isSyncing: _isSyncing,
      lastFullSync: syncStatus.lastFullSync,
      pendingOperations: pendingOps.length,
      failedOperations: failedOps.length,
      lastError: failedOps.isNotEmpty ? failedOps.first.error : null,
    );
  }

  /// Retry failed operations
  Future<void> retryFailedOperations(String userId) async {
    final failedOps = await _syncRepository.getFailedOperations(userId);
    
    _emitEvent(SyncEvent.retryStarted(failedOps.length));

    for (final operation in failedOps) {
      if (operation.retryCount < _maxRetries) {
        // Reset status to pending for retry
        operation.status = SyncStatus.pending;
        operation.error = null;
        operation.updatedAt = DateTime.now();
        
        await _syncRepository.queueOperation(operation);
      }
    }

    if (_isOnline) {
      await _performSync(userId);
    }
  }

  /// Clear completed operations older than specified days
  Future<void> cleanupOldOperations({int daysOld = 7}) async {
    await _syncRepository.cleanupCompletedOperations(daysOld: daysOld);
    _emitEvent(SyncEvent.cleanupCompleted());
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _syncEventsController?.close();
  }

  /// Private methods

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncInterval, (_) async {
      if (_isOnline && !_isSyncing) {
        await syncAll();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      await _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final wasOnline = _isOnline;
    
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    if (_isOnline && !wasOnline) {
      _emitEvent(SyncEvent.connectivityChanged(true));
      // Trigger sync when coming back online
      unawaited(syncAll());
    } else if (!_isOnline && wasOnline) {
      _emitEvent(SyncEvent.connectivityChanged(false));
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (_isOnline && !wasOnline) {
      _emitEvent(SyncEvent.connectivityChanged(true));
      unawaited(syncAll());
    } else if (!_isOnline && wasOnline) {
      _emitEvent(SyncEvent.connectivityChanged(false));
    }
  }

  Future<void> _performSync(String userId) async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    _emitEvent(SyncEvent.syncStarted(userId));

    try {
      final pendingOps = await _syncRepository.getPendingOperations(userId);
      
      if (pendingOps.isEmpty) {
        _emitEvent(SyncEvent.syncCompleted(userId, 0, 0));
        return;
      }

      // Sort by priority and creation time
      pendingOps.sort((a, b) {
        final priorityComparison = _comparePriority(a.priority, b.priority);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      int successful = 0;
      int failed = 0;

      for (final operation in pendingOps) {
        if (!_isOnline) break; // Stop if we went offline

        final success = await _processOperation(operation);
        if (success) {
          successful++;
        } else {
          failed++;
        }

        // Small delay between operations to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Update sync status
      await _updateSyncStatus(userId, successful, failed);
      
      _emitEvent(SyncEvent.syncCompleted(userId, successful, failed));

    } catch (e) {
      _emitEvent(SyncEvent.syncError(userId, e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _processOperation(SyncOperation operation) async {
    try {
      _emitEvent(SyncEvent.operationStarted(operation.id, operation.operation, operation.collection));

      switch (operation.collection) {
        case 'combineSpecs':
          return await _processCombineSpecOperation(operation);
        case 'userCombines':
          return await _processUserCombineOperation(operation);
        default:
          throw UnsupportedError('Unknown collection: ${operation.collection}');
      }
    } catch (e) {
      await _handleOperationError(operation, e.toString());
      return false;
    }
  }

  Future<bool> _processCombineSpecOperation(SyncOperation operation) async {
    switch (operation.operation) {
      case SyncOperationType.create:
        final spec = CombineSpec.fromJson(operation.data!);
        await _combineRepository.create(spec);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      case SyncOperationType.update:
        final spec = CombineSpec.fromJson(operation.data!);
        await _combineRepository.update(operation.documentId, spec);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      case SyncOperationType.delete:
        await _combineRepository.delete(operation.documentId);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      default:
        throw UnsupportedError('Unknown operation: ${operation.operation}');
    }
  }

  Future<bool> _processUserCombineOperation(SyncOperation operation) async {
    switch (operation.operation) {
      case SyncOperationType.create:
        final userCombine = UserCombine.fromJson(operation.data!);
        await _userCombineRepository.create(userCombine);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      case SyncOperationType.update:
        final userCombine = UserCombine.fromJson(operation.data!);
        await _userCombineRepository.update(operation.documentId, userCombine);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      case SyncOperationType.delete:
        await _userCombineRepository.delete(operation.documentId);
        await _syncRepository.markOperationComplete(operation.id);
        return true;

      default:
        throw UnsupportedError('Unknown operation: ${operation.operation}');
    }
  }

  Future<void> _handleOperationError(SyncOperation operation, String error) async {
    operation.retryCount++;
    operation.error = error;
    operation.lastAttempt = DateTime.now();
    operation.updatedAt = DateTime.now();

    if (operation.retryCount >= _maxRetries) {
      operation.status = SyncStatus.failed;
      _emitEvent(SyncEvent.operationFailed(operation.id, operation.operation, error));
    } else {
      // Calculate exponential backoff delay
      final delaySeconds = _baseDelaySeconds * pow(2, operation.retryCount - 1);
      
      // Schedule retry
      Future.delayed(Duration(seconds: delaySeconds.toInt()), () {
        if (_isOnline) {
          _processOperation(operation);
        }
      });
      
      _emitEvent(SyncEvent.operationRetried(operation.id, operation.retryCount, delaySeconds.toInt()));
    }

    await _syncRepository.markOperationFailed(operation.id, error);
  }

  Future<void> _updateSyncStatus(String userId, int successful, int failed) async {
    final status = UserSyncStatus(
      userId: userId,
      isOnline: _isOnline,
      isSyncing: false,
      lastFullSync: successful > 0 ? DateTime.now() : null,
      pendingOperations: await _syncRepository.getPendingOperations(userId).then((ops) => ops.length),
      failedOperations: failed,
      lastError: null,
    );

    await _syncRepository.updateSyncStatus(SyncStatusData(
      id: userId,
      userId: userId,
      lastFullSync: status.lastFullSync,
      pendingOperations: status.pendingOperations,
      failedOperations: status.failedOperations,
      isOnline: status.isOnline,
      lastOnline: _isOnline ? DateTime.now() : null,
      syncInProgress: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  int _comparePriority(OperationPriority a, OperationPriority b) {
    const priorities = {
      OperationPriority.high: 3,
      OperationPriority.medium: 2,
      OperationPriority.low: 1,
    };
    return priorities[b]!.compareTo(priorities[a]!);
  }

  String _generateOperationId() {
    return 'sync_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  String _generateAuditId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void _emitEvent(SyncEvent event) {
    _syncEventsController?.add(event);
  }
}

/// Conflict Resolution Service
class ConflictResolver {
  /// Resolve conflicts between local and remote data
  static T resolveConflict<T extends BaseDocument>(T local, T remote) {
    // Last-write-wins strategy with timestamp comparison
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    } else if (remote.updatedAt.isAfter(local.updatedAt)) {
      return remote;
    } else {
      // If timestamps are equal, prefer remote (server authoritative)
      return remote;
    }
  }

  /// Merge combine spec conflicts intelligently
  static CombineSpec resolveCombineSpecConflict(CombineSpec local, CombineSpec remote) {
    // For combine specs, we want to preserve user-specific data
    // but use the most recent system data
    
    final resolved = remote.copyWith();
    
    // Keep user-specific moisture settings if local is newer
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      resolved.moistureTolerance = local.moistureTolerance;
      resolved.toughCropAbility = local.toughCropAbility;
    }
    
    // Always use the highest source data counts
    resolved.sourceData = SourceData(
      userReports: max(local.sourceData.userReports, remote.sourceData.userReports),
      manufacturerSpecs: local.sourceData.manufacturerSpecs || remote.sourceData.manufacturerSpecs,
      expertValidation: local.sourceData.expertValidation || remote.sourceData.expertValidation,
      lastUpdated: local.sourceData.lastUpdated.isAfter(remote.sourceData.lastUpdated) 
          ? local.sourceData.lastUpdated 
          : remote.sourceData.lastUpdated,
    );
    
    return resolved;
  }

  /// Merge user combine conflicts
  static UserCombine resolveUserCombineConflict(UserCombine local, UserCombine remote) {
    // For user combines, local data should generally take precedence
    // as it represents the user's current usage
    
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    }
    
    // Merge custom settings intelligently
    final mergedSettings = <String, dynamic>{
      ...remote.customSettings,
      ...local.customSettings, // Local overrides remote
    };
    
    return remote.copyWith(customSettings: mergedSettings);
  }
}

/// Event classes for sync status updates

abstract class SyncEvent {
  final DateTime timestamp;

  SyncEvent() : timestamp = DateTime.now();

  factory SyncEvent.initialized() = SyncInitializedEvent;
  factory SyncEvent.connectivityChanged(bool isOnline) = ConnectivityChangedEvent;
  factory SyncEvent.syncStarted(String userId) = SyncStartedEvent;
  factory SyncEvent.syncCompleted(String userId, int successful, int failed) = SyncCompletedEvent;
  factory SyncEvent.syncSkipped(String reason) = SyncSkippedEvent;
  factory SyncEvent.syncError(String userId, String error) = SyncErrorEvent;
  factory SyncEvent.operationQueued(String operationId, SyncOperationType operation, String collection) = OperationQueuedEvent;
  factory SyncEvent.operationStarted(String operationId, SyncOperationType operation, String collection) = OperationStartedEvent;
  factory SyncEvent.operationCompleted(String operationId, SyncOperationType operation) = OperationCompletedEvent;
  factory SyncEvent.operationFailed(String operationId, SyncOperationType operation, String error) = OperationFailedEvent;
  factory SyncEvent.operationRetried(String operationId, int retryCount, int delaySeconds) = OperationRetriedEvent;
  factory SyncEvent.retryStarted(int operationCount) = RetryStartedEvent;
  factory SyncEvent.cleanupCompleted() = CleanupCompletedEvent;
}

class SyncInitializedEvent extends SyncEvent {}

class ConnectivityChangedEvent extends SyncEvent {
  final bool isOnline;
  ConnectivityChangedEvent(this.isOnline);
}

class SyncStartedEvent extends SyncEvent {
  final String userId;
  SyncStartedEvent(this.userId);
}

class SyncCompletedEvent extends SyncEvent {
  final String userId;
  final int successful;
  final int failed;
  SyncCompletedEvent(this.userId, this.successful, this.failed);
}

class SyncSkippedEvent extends SyncEvent {
  final String reason;
  SyncSkippedEvent(this.reason);
}

class SyncErrorEvent extends SyncEvent {
  final String userId;
  final String error;
  SyncErrorEvent(this.userId, this.error);
}

class OperationQueuedEvent extends SyncEvent {
  final String operationId;
  final SyncOperationType operation;
  final String collection;
  OperationQueuedEvent(this.operationId, this.operation, this.collection);
}

class OperationStartedEvent extends SyncEvent {
  final String operationId;
  final SyncOperationType operation;
  final String collection;
  OperationStartedEvent(this.operationId, this.operation, this.collection);
}

class OperationCompletedEvent extends SyncEvent {
  final String operationId;
  final SyncOperationType operation;
  OperationCompletedEvent(this.operationId, this.operation);
}

class OperationFailedEvent extends SyncEvent {
  final String operationId;
  final SyncOperationType operation;
  final String error;
  OperationFailedEvent(this.operationId, this.operation, this.error);
}

class OperationRetriedEvent extends SyncEvent {
  final String operationId;
  final int retryCount;
  final int delaySeconds;
  OperationRetriedEvent(this.operationId, this.retryCount, this.delaySeconds);
}

class RetryStartedEvent extends SyncEvent {
  final int operationCount;
  RetryStartedEvent(this.operationCount);
}

class CleanupCompletedEvent extends SyncEvent {}

/// Sync status data model for repository
class SyncStatusData extends BaseDocument {
  final String userId;
  final DateTime? lastFullSync;
  final int pendingOperations;
  final int failedOperations;
  final bool isOnline;
  final DateTime? lastOnline;
  final bool syncInProgress;

  SyncStatusData({
    required String id,
    required this.userId,
    this.lastFullSync,
    required this.pendingOperations,
    required this.failedOperations,
    required this.isOnline,
    this.lastOnline,
    required this.syncInProgress,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lastFullSync': lastFullSync?.toIso8601String(),
      'pendingOperations': pendingOperations,
      'failedOperations': failedOperations,
      'isOnline': isOnline,
      'lastOnline': lastOnline?.toIso8601String(),
      'syncInProgress': syncInProgress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SyncStatusData.fromJson(Map<String, dynamic> json) {
    return SyncStatusData(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lastFullSync: json['lastFullSync'] != null
          ? DateTime.parse(json['lastFullSync'] as String)
          : null,
      pendingOperations: json['pendingOperations'] as int,
      failedOperations: json['failedOperations'] as int,
      isOnline: json['isOnline'] as bool,
      lastOnline: json['lastOnline'] != null
          ? DateTime.parse(json['lastOnline'] as String)
          : null,
      syncInProgress: json['syncInProgress'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// User sync status model
class UserSyncStatus {
  final String userId;
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastFullSync;
  final int pendingOperations;
  final int failedOperations;
  final String? lastError;

  UserSyncStatus({
    required this.userId,
    required this.isOnline,
    required this.isSyncing,
    this.lastFullSync,
    required this.pendingOperations,
    required this.failedOperations,
    this.lastError,
  });
}

/// Sync status data model for repository
class SyncStatusData extends BaseDocument {
  final String userId;
  final DateTime? lastFullSync;
  final int pendingOperations;
  final int failedOperations;
  final bool isOnline;
  final DateTime? lastOnline;
  final bool syncInProgress;

  SyncStatusData({
    required String id,
    required this.userId,
    this.lastFullSync,
    required this.pendingOperations,
    required this.failedOperations,
    required this.isOnline,
    this.lastOnline,
    required this.syncInProgress,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);
}

/// Utility function to handle unawaited futures
void unawaited(Future<void> future) {
  future.catchError((error) {
    // Log error but don't crash
    print('Unawaited future error: $error');
  });
}