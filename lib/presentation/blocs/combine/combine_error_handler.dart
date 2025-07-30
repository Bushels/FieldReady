/**
 * CombineErrorHandler - Comprehensive error handling and recovery system
 * Provides structured error handling with recovery actions and fallback strategies
 * Integrates with offline capabilities and sync retry logic
 */

import 'dart:async';
import 'dart:io';
import '../../../domain/models/combine_models.dart';
import 'combine_state.dart';

/// Error handling extension for CombineBloc
class CombineErrorHandler {
  /// Map error types to user-friendly messages and recovery actions
  static CombineError handleError(
    Exception error, {
    String context = 'operation',
    CombineState? previousState,
    Map<String, dynamic>? errorContext,
  }) {
    
    if (error is CombineBusinessException) {
      return _handleBusinessError(error, previousState);
    } else if (error is NetworkException) {
      return _handleNetworkError(error, previousState);
    } else if (error is SyncException) {
      return _handleSyncError(error, previousState);
    } else if (error is NormalizationException) {
      return _handleNormalizationError(error, previousState);
    } else if (error is ValidationException) {
      return _handleValidationError(error, previousState);
    } else if (error is CacheException) {
      return _handleCacheError(error, previousState);
    } else {
      return _handleGenericError(error, context, previousState, errorContext);
    }
  }

  /// Handle business logic errors
    static CombineError _handleBusinessError(
    CombineBusinessException error,
    CombineState? previousState,
  ) {
    switch (error.type) {
      case BusinessErrorType.combineNotFound:
        return CombineError(
          message: 'Combine not found',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Refresh List',
              description: 'Reload your combines',
              type: CombineErrorActionType.refresh,
            ),
            const CombineErrorAction(
              label: 'Add New Combine',
              description: 'Add a new combine to your fleet',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'add_combine'},
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case BusinessErrorType.duplicateCombine:
        return CombineError(
          message: 'This combine is already in your fleet',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'View Existing',
              description: 'Go to your existing combine',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'view_existing'},
            ),
            const CombineErrorAction(
              label: 'Add Anyway',
              description: 'Add as a second unit',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'force_add'},
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case BusinessErrorType.invalidCapabilities:
        return CombineError(
          message: 'Invalid combine capabilities data',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Reset to Defaults',
              description: 'Use default capability values',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'reset_capabilities'},
            ),
            const CombineErrorAction(
              label: 'Manual Entry',
              description: 'Enter capabilities manually',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'manual_entry'},
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case BusinessErrorType.insufficientData:
        return CombineError(
          message: 'Insufficient data for this operation',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Use Basic Data',
              description: 'Continue with limited information',
              type: CombineErrorActionType.useCachedData,
            ),
            const CombineErrorAction(
              label: 'Contact Support',
              description: 'Get help from our team',
              type: CombineErrorActionType.contactSupport,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );
    }
  }

  /// Handle network-related errors
  static CombineError _handleNetworkError(
    NetworkException error,
    CombineState? previousState,
  ) {
    switch (error.type) {
      case NetworkErrorType.noConnection:
        return CombineError(
          message: 'No internet connection',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Work Offline',
              description: 'Continue with cached data',
              type: CombineErrorActionType.useCachedData,
            ),
            const CombineErrorAction(
              label: 'Retry',
              description: 'Try connecting again',
              type: CombineErrorActionType.retry,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.5, // Partial confidence with cached data
          lastUpdated: DateTime.now(),
        );

      case NetworkErrorType.timeout:
        return CombineError(
          message: 'Connection timed out',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Retry',
              description: 'Try again with longer timeout',
              type: CombineErrorActionType.retry,
            ),
            const CombineErrorAction(
              label: 'Use Cached Data',
              description: 'Work with offline data',
              type: CombineErrorActionType.useCachedData,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case NetworkErrorType.serverError:
        return CombineError(
          message: 'Server temporarily unavailable',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Retry Later',
              description: 'Try again in a few minutes',
              type: CombineErrorActionType.retry,
            ),
            const CombineErrorAction(
              label: 'Work Offline',
              description: 'Continue with cached data',
              type: CombineErrorActionType.useCachedData,
            ),
            const CombineErrorAction(
              label: 'Contact Support',
              description: 'Report the issue',
              type: CombineErrorActionType.contactSupport,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case NetworkErrorType.rateLimited:
        return CombineError(
          message: 'Too many requests. Please wait.',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Wait and Retry',
              description: 'Automatically retry in 30 seconds',
              type: CombineErrorActionType.retry,
              actionData: {'delay': 30},
            ),
            const CombineErrorAction(
              label: 'Use Cached Data',
              description: 'Work with offline data',
              type: CombineErrorActionType.useCachedData,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );
    }
  }

  /// Handle sync-related errors
  static CombineError _handleSyncError(
    SyncException error,
    CombineState? previousState,
  ) {
    switch (error.type) {
      case SyncErrorType.conflictDetected:
        return CombineError(
          message: 'Data conflict detected',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Resolve Conflicts',
              description: 'Choose which data to keep',
              type: CombineErrorActionType.retry,
              actionData: {'action': 'resolve_conflicts'},
            ),
            const CombineErrorAction(
              label: 'Use Local Data',
              description: 'Keep your local changes',
              type: CombineErrorActionType.retry,
              actionData: {'strategy': 'use_local'},
            ),
            const CombineErrorAction(
              label: 'Use Server Data',
              description: 'Accept server changes',
              type: CombineErrorActionType.retry,
              actionData: {'strategy': 'use_remote'},
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );

      case SyncErrorType.syncFailed:
        return CombineError(
          message: 'Sync failed',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Retry Sync',
              description: 'Try syncing again',
              type: CombineErrorActionType.syncManually,
            ),
            const CombineErrorAction(
              label: 'Clear Sync Queue',
              description: 'Clear pending sync operations',
              type: CombineErrorActionType.clearCache,
              actionData: {'clear_sync_queue': true},
            ),
            const CombineErrorAction(
              label: 'Work Offline',
              description: 'Continue without syncing',
              type: CombineErrorActionType.useCachedData,
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.7, // Local data still valid
          lastUpdated: DateTime.now(),
        );

      case SyncErrorType.operationTimeout:
        return CombineError(
          message: 'Sync operation timed out',
          technicalDetails: error.toString(),
          recoveryActions: [
            const CombineErrorAction(
              label: 'Retry with Longer Timeout',
              description: 'Try again with more time',
              type: CombineErrorActionType.retry,
              actionData: {'timeout_multiplier': 2},
            ),
            const CombineErrorAction(
              label: 'Sync Later',
              description: 'Queue for background sync',
              type: CombineErrorActionType.retry,
              actionData: {'background_sync': true},
            ),
          ],
          isRecoverable: true,
          previousState: previousState,
          confidence: 0.0,
          lastUpdated: DateTime.now(),
        );
    }
  }

  /// Handle normalization errors
  static CombineError _handleNormalizationError(
    NormalizationException error,
    CombineState? previousState,
  ) {
    return CombineError(
      message: error.message,
      technicalDetails: error.toString(),
      recoveryActions: [
        const CombineErrorAction(
          label: 'Try Different Spelling',
          description: 'Check brand and model spelling',
          type: CombineErrorActionType.retry,
          actionData: {'action': 'retry_input'},
        ),
        const CombineErrorAction(
          label: 'Manual Entry',
          description: 'Enter combine details manually',
          type: CombineErrorActionType.retry,
          actionData: {'action': 'manual_entry'},
        ),
        const CombineErrorAction(
          label: 'Contact Support',
          description: 'Report missing combine model',
          type: CombineErrorActionType.contactSupport,
        ),
      ],
      isRecoverable: true,
      previousState: previousState,
      confidence: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Handle validation errors
  static CombineError _handleValidationError(
    ValidationException error,
    CombineState? previousState,
  ) {
    return CombineError(
      message: 'Invalid input: ${error.field}',
      technicalDetails: error.toString(),
      recoveryActions: [
        CombineErrorAction(
          label: 'Fix Input',
          description: error.suggestion ?? 'Please correct the input and try again',
          type: CombineErrorActionType.retry,
          actionData: {'field': error.field, 'error': error.message},
        ),
        const CombineErrorAction(
          label: 'Use Defaults',
          description: 'Use default values',
          type: CombineErrorActionType.retry,
          actionData: {'action': 'use_defaults'},
        ),
      ],
      isRecoverable: true,
      previousState: previousState,
      confidence: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Handle cache-related errors
  static CombineError _handleCacheError(
    CacheException error,
    CombineState? previousState,
  ) {
    return CombineError(
      message: 'Cache error occurred',
      technicalDetails: error.toString(),
      recoveryActions: [
        const CombineErrorAction(
          label: 'Clear Cache',
          description: 'Clear cached data and reload',
          type: CombineErrorActionType.clearCache,
        ),
        const CombineErrorAction(
          label: 'Fetch Fresh Data',
          description: 'Load data from server',
          type: CombineErrorActionType.refresh,
        ),
        const CombineErrorAction(
          label: 'Reset App State',
          description: 'Restart the app section',
          type: CombineErrorActionType.resetState,
        ),
      ],
      isRecoverable: true,
      previousState: previousState,
      confidence: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Handle generic/unknown errors
  static CombineError _handleGenericError(
    Exception error,
    String context,
    CombineState? previousState,
    Map<String, dynamic>? errorContext,
  ) {
    // Try to extract meaningful information from the error
    String message = 'An unexpected error occurred';
    List<CombineErrorAction> actions = [];

    if (error is SocketException) {
      message = 'Network connection failed';
      actions = [
        const CombineErrorAction(
          label: 'Check Connection',
          description: 'Verify your internet connection',
          type: CombineErrorActionType.retry,
        ),
        const CombineErrorAction(
          label: 'Work Offline',
          description: 'Continue with cached data',
          type: CombineErrorActionType.useCachedData,
        ),
      ];
    } else if (error is TimeoutException) {
      message = 'Operation timed out';
      actions = [
        const CombineErrorAction(
          label: 'Retry',
          description: 'Try the operation again',
          type: CombineErrorActionType.retry,
        ),
        const CombineErrorAction(
          label: 'Reduce Load',
          description: 'Try with less data',
          type: CombineErrorActionType.retry,
          actionData: {'reduce_scope': true},
        ),
      ];
    } else if (error is FormatException) {
      message = 'Data format error';
      actions = [
        const CombineErrorAction(
          label: 'Refresh Data',
          description: 'Reload data from server',
          type: CombineErrorActionType.refresh,
        ),
        const CombineErrorAction(
          label: 'Clear Cache',
          description: 'Clear corrupted cache',
          type: CombineErrorActionType.clearCache,
        ),
      ];
    } else {
      // Generic fallback actions
      actions = [
        const CombineErrorAction(
          label: 'Retry',
          description: 'Try the operation again',
          type: CombineErrorActionType.retry,
        ),
        const CombineErrorAction(
          label: 'Refresh',
          description: 'Reload data',
          type: CombineErrorActionType.refresh,
        ),
        const CombineErrorAction(
          label: 'Contact Support',
          description: 'Report this issue',
          type: CombineErrorActionType.contactSupport,
          actionData: {
            'context': context,
            'errorType': error.runtimeType.toString(),
            'errorContext': errorContext,
          },
        ),
      ];
    }

    return CombineError(
      message: message,
      technicalDetails: error.toString(),
      recoveryActions: actions,
      isRecoverable: true,
      previousState: previousState,
      confidence: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create recovery strategy based on error type and user preferences
  static RecoveryStrategy createRecoveryStrategy(
    CombineError error, {
    bool preferOffline = false,
    bool autoRetry = false,
    int maxRetries = 3,
  }) {
    return RecoveryStrategy(
      primaryAction: _selectPrimaryAction(error, preferOffline, autoRetry),
      fallbackActions: error.recoveryActions.where(
        (action) => action != _selectPrimaryAction(error, preferOffline, autoRetry),
      ).toList(),
      maxRetries: maxRetries,
      retryDelay: _calculateRetryDelay(error),
      shouldAutoRetry: _shouldAutoRetry(error, autoRetry),
    );
  }

  /// Select the best primary recovery action
  static CombineErrorAction _selectPrimaryAction(
    CombineError error,
    bool preferOffline,
    bool autoRetry,
  ) {
    if (preferOffline) {
      final offlineAction = error.recoveryActions.where(
        (action) => action.type == CombineErrorActionType.useCachedData,
      ).firstOrNull;
      if (offlineAction != null) return offlineAction;
    }

    if (autoRetry) {
      final retryAction = error.recoveryActions.where(
        (action) => action.type == CombineErrorActionType.retry,
      ).firstOrNull;
      if (retryAction != null) return retryAction;
    }

    return error.recoveryActions.isNotEmpty 
        ? error.recoveryActions.first 
        : const CombineErrorAction(
            label: 'Retry',
            description: 'Try again',
            type: CombineErrorActionType.retry,
          );
  }

  /// Calculate appropriate retry delay based on error type
  static Duration _calculateRetryDelay(CombineError error) {
    if (error.technicalDetails?.contains('rate limit') == true) {
      return const Duration(seconds: 30);
    } else if (error.technicalDetails?.contains('timeout') == true) {
      return const Duration(seconds: 5);
    } else if (error.technicalDetails?.contains('network') == true) {
      return const Duration(seconds: 3);
    } else {
      return const Duration(seconds: 2);
    }
  }

  /// Determine if error should be auto-retried
  static bool _shouldAutoRetry(CombineError error, bool autoRetry) {
    if (!autoRetry) return false;

    // Auto-retry network errors and timeouts
    return error.technicalDetails?.contains('network') == true ||
           error.technicalDetails?.contains('timeout') == true ||
           error.technicalDetails?.contains('connection') == true;
  }
}

/// Recovery strategy for handling errors
class RecoveryStrategy {
  final CombineErrorAction primaryAction;
  final List<CombineErrorAction> fallbackActions;
  final int maxRetries;
  final Duration retryDelay;
  final bool shouldAutoRetry;

  const RecoveryStrategy({
    required this.primaryAction,
    this.fallbackActions = const [],
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.shouldAutoRetry = false,
  });
}

/// Custom exception types for structured error handling

class CombineBusinessException implements Exception {
  final BusinessErrorType type;
  final String message;
  final Map<String, dynamic>? context;

  const CombineBusinessException(this.type, this.message, [this.context]);

  @override
  String toString() => 'CombineBusinessException($type): $message';
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;

  const NetworkException(this.type, this.message, [this.statusCode]);

  @override
  String toString() => 'NetworkException($type): $message';
}

class SyncException implements Exception {
  final SyncErrorType type;
  final String message;
  final String? operationId;

  const SyncException(this.type, this.message, [this.operationId]);

  @override
  String toString() => 'SyncException($type): $message';
}

class ValidationException implements Exception {
  final String field;
  final String message;
  final String? suggestion;

  const ValidationException(this.field, this.message, [this.suggestion]);

  @override
  String toString() => 'ValidationException($field): $message';
}

class CacheException implements Exception {
  final String message;
  final String? cacheKey;

  const CacheException(this.message, [this.cacheKey]);

  @override
  String toString() => 'CacheException: $message';
}

/// Error type enums
enum BusinessErrorType {
  combineNotFound,
  duplicateCombine,
  invalidCapabilities,
  insufficientData,
}

enum NetworkErrorType {
  noConnection,
  timeout,
  serverError,
  rateLimited,
}

enum SyncErrorType {
  conflictDetected,
  syncFailed,
  operationTimeout,
}

/// Extension helper for first-or-null
extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}