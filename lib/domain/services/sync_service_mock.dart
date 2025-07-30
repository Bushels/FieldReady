/**
 * Mock Sync Service Implementation
 * Provides basic sync functionality for development and testing
 */

import 'dart:async';
import '../repositories/combine_repository.dart';
import '../models/combine_models.dart';

/// Mock sync service for development
class SyncService {
  final CombineRepository _combineRepository;
  
  bool _isSyncing = false;
  bool _isOnline = true; // Assume online for mock

  StreamController<SyncEvent>? _syncEventsController;
  Stream<SyncEvent>? _syncEventsStream;

  SyncService({
    required CombineRepository combineRepository,
  }) : _combineRepository = combineRepository;

  /// Initialize sync service
  Future<void> initialize() async {
    _syncEventsController = StreamController<SyncEvent>.broadcast();
    _syncEventsStream = _syncEventsController!.stream;
    
    _emitEvent(SyncEvent.initialized());
  }

  /// Get sync events stream for UI updates
  Stream<SyncEvent> get syncEvents => _syncEventsStream!;

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Queue a sync operation (mock implementation)
  Future<String> queueOperation({
    required String userId,
    required SyncOperationType operation,
    required String collection,
    required String documentId,
    Map<String, dynamic>? data,
    OperationPriority priority = OperationPriority.medium,
  }) async {
    final operationId = 'sync_${DateTime.now().millisecondsSinceEpoch}';
    
    // Emit queued event
    _emitEvent(SyncEvent.operationQueued(operationId, operation, collection));
    
    return operationId;
  }

  /// Manually trigger sync
  Future<void> sync({String? userId}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    _emitEvent(SyncEvent.syncStarted());

    try {
      // Mock sync delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, would sync with remote
      await _combineRepository.syncWithRemote();
      
      _emitEvent(SyncEvent.syncCompleted());
    } catch (e) {
      _emitEvent(SyncEvent.syncFailed(e.toString()));
    } finally {
      _isSyncing = false;
    }
  }

  /// Get sync status for a user
  Future<MockSyncStatus> getSyncStatus(String userId) async {
    return MockSyncStatus(
      userId: userId,
      lastSync: DateTime.now().subtract(const Duration(minutes: 30)),
      pendingOperations: 0,
      isOnline: _isOnline,
      isSyncing: _isSyncing,
    );
  }

  void _emitEvent(SyncEvent event) {
    _syncEventsController?.add(event);
  }

  /// Dispose resources
  void dispose() {
    _syncEventsController?.close();
  }
}

/// Mock sync status
class MockSyncStatus {
  final String userId;
  final DateTime lastSync;
  final int pendingOperations;
  final bool isOnline;
  final bool isSyncing;

  MockSyncStatus({
    required this.userId,
    required this.lastSync,
    required this.pendingOperations,
    required this.isOnline,
    required this.isSyncing,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'lastSync': lastSync.toIso8601String(),
      'pendingOperations': pendingOperations,
      'isOnline': isOnline,
      'isSyncing': isSyncing,
    };
  }
}

/// Sync events for UI updates
class SyncEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncEvent._(
    this.type,
    this.data,
  ) : timestamp = DateTime.now();

  factory SyncEvent.initialized() => SyncEvent._('initialized', {});
  
  factory SyncEvent.syncStarted() => SyncEvent._('sync_started', {});
  
  factory SyncEvent.syncCompleted() => SyncEvent._('sync_completed', {});
  
  factory SyncEvent.syncFailed(String error) => SyncEvent._('sync_failed', {'error': error});
  
  factory SyncEvent.operationQueued(
    String operationId,
    SyncOperationType operation,
    String collection,
  ) => SyncEvent._('operation_queued', {
    'operationId': operationId,
    'operation': operation.name,
    'collection': collection,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}