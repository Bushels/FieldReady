# CombineBloc System Documentation

## Overview

The CombineBloc system is a comprehensive Flutter state management solution for FieldFirst's combine specifications and equipment management. It implements the BLoC pattern with hydrated_bloc for offline persistence, fuzzy matching for model normalization, and intelligent sync capabilities with conflict resolution.

## Architecture

### Core Components

1. **CombineBloc** - Main BLoC handling all combine-related state management
2. **CombineEvent** - Sealed classes defining all possible events
3. **CombineState** - Sealed classes with confidence tracking and offline support
4. **CombineErrorHandler** - Comprehensive error handling with recovery strategies
5. **CombineSyncManager** - Advanced sync queue and conflict resolution

### Key Features

- **Offline-First Architecture**: Full offline support with 48-hour persistence
- **Fuzzy Matching**: Intelligent combine model normalization with confidence scoring
- **Progressive Data Loading**: Capability insights based on user volume (minimal/moderate/rich)
- **Conflict Resolution**: Automatic and manual conflict resolution strategies
- **Error Recovery**: Structured error handling with suggested recovery actions
- **Real-time Sync**: Priority-based sync queue with exponential backoff retry

## Usage Examples

### Basic Setup

```dart
// Initialize dependencies
final combineRepository = CombineRepositoryImpl();
final userCombineRepository = UserCombineRepositoryImpl();
final normalizationRepository = NormalizationRepositoryImpl();
final syncRepository = SyncRepositoryImpl();
final normalizer = CombineNormalizer();
final syncService = SyncService();
final harvestIntelligence = HarvestIntelligence();

// Create BLoC
final combineBloc = CombineBloc(
  combineRepository: combineRepository,
  userCombineRepository: userCombineRepository,
  normalizationRepository: normalizationRepository,
  syncRepository: syncRepository,
  normalizer: normalizer,
  syncService: syncService,
  harvestIntelligence: harvestIntelligence,
);
```

### Loading User Combines

```dart
// Load combines with force refresh
combineBloc.add(LoadUserCombines(
  userId: 'user123',
  forceRefresh: true,
));

// Listen to state changes
BlocListener<CombineBloc, CombineState>(
  listener: (context, state) {
    switch (state) {
      case CombineLoaded(:final userCombines, :final confidence):
        print('Loaded ${userCombines.length} combines with confidence: $confidence');
        break;
      case CombineError(:final message, :final recoveryActions):
        print('Error: $message');
        // Show recovery options to user
        break;
    }
  },
)
```

### Adding a Combine with Fuzzy Matching

```dart
// Add combine - triggers fuzzy matching
combineBloc.add(AddCombine(
  userId: 'user123',
  brand: 'John Deere',
  model: 'X9 1100',
  year: 2023,
  nickname: 'Big Red',
  customSettings: {
    'preferredOperatingSpeed': 8.5,
    'grainTankAlert': 95,
  },
));

// Handle normalization requirement
BlocListener<CombineBloc, CombineState>(
  listener: (context, state) {
    if (state is CombineNormalizationRequired) {
      // Show confirmation dialog to user
      showDialog(
        context: context,
        builder: (context) => NormalizationConfirmationDialog(
          originalInput: state.originalInput,
          matches: state.matchResults,
          onConfirm: (selectedMatch) {
            combineBloc.add(ConfirmNormalizedModel(
              userId: 'user123',
              originalInput: state.originalInput,
              selectedMatch: selectedMatch,
              nickname: 'Big Red',
            ));
          },
          onReject: (rejectedMatch) {
            combineBloc.add(RejectNormalizedModel(
              userId: 'user123',
              originalInput: state.originalInput,
              rejectedMatch: rejectedMatch,
            ));
          },
        ),
      );
    }
  },
)
```

### Progressive Capability Loading

```dart
BlocBuilder<CombineBloc, CombineState>(
  builder: (context, state) {
    if (state is CombineLoaded) {
      return ListView.builder(
        itemCount: state.userCombines.length,
        itemBuilder: (context, index) {
          final combine = state.userCombines[index];
          final capabilities = state.progressiveCapabilities[combine.combineSpecId];
          
          return CombineCard(
            combine: combine,
            capabilities: capabilities,
            onTap: () {
              // Load detailed capabilities if not loaded
              if (capabilities == null) {
                combineBloc.add(LoadProgressiveCapabilities(
                  combineSpecId: combine.combineSpecId,
                  region: 'prairie_canada',
                  userId: combine.userId,
                ));
              }
            },
          );
        },
      );
    }
    return const LoadingWidget();
  },
)
```

### Syncing Data

```dart
// Manual sync
combineBloc.add(SyncCombineData(
  userId: 'user123',
  isManualSync: true,
));

// Sync specific combines
combineBloc.add(SyncCombineData(
  userId: 'user123',
  specificCombineIds: ['combine1', 'combine2'],
));

// Handle sync progress
BlocListener<CombineBloc, CombineState>(
  listener: (context, state) {
    if (state is CombineLoaded) {
      if (state.syncStatus == SyncStatus.syncing) {
        // Show sync progress
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Syncing combines...')),
        );
      } else if (state.syncStatus == SyncStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed')),
        );
      }
    }
  },
)
```

### Error Handling

```dart
BlocListener<CombineBloc, CombineState>(
  listener: (context, state) {
    if (state is CombineError) {
      showDialog(
        context: context,
        builder: (context) => ErrorRecoveryDialog(
          error: state,
          onRecoveryAction: (action) {
            switch (action.type) {
              case CombineErrorActionType.retry:
                if (state.previousState is CombineLoaded) {
                  combineBloc.add(LoadUserCombines(
                    userId: 'user123',
                    forceRefresh: true,
                  ));
                }
                break;
              case CombineErrorActionType.useCachedData:
                if (state.previousState != null) {
                  // Restore previous state or show cached data
                }
                break;
              case CombineErrorActionType.clearCache:
                combineBloc.add(const ClearCombineCache(clearAll: true));
                break;
              case CombineErrorActionType.contactSupport:
                // Open support contact
                break;
            }
          },
        ),
      );
    }
  },
)
```

### Conflict Resolution

```dart
BlocListener<CombineBloc, CombineState>(
  listener: (context, state) {
    if (state is CombineConflictResolution) {
      showDialog(
        context: context,
        builder: (context) => ConflictResolutionDialog(
          conflicts: state.conflicts,
          suggestedStrategies: state.suggestedStrategies,
          onResolve: (conflictId, strategy, data) {
            combineBloc.add(ResolveConflict(
              conflictId: conflictId,
              strategy: strategy,
              resolutionData: data,
            ));
          },
        ),
      );
    }
  },
)
```

### Search Functionality

```dart
// Search combines
combineBloc.add(SearchCombines(
  query: 'John Deere X9',
  userId: 'user123',
  maxResults: 10,
));

// Display search results
BlocBuilder<CombineBloc, CombineState>(
  builder: (context, state) {
    if (state is CombineSearchResults) {
      return SearchResultsList(
        query: state.query,
        results: state.results,
        hasMore: state.hasMoreResults,
        onSelectResult: (result) {
          // Add selected combine
          combineBloc.add(ConfirmNormalizedModel(
            userId: 'user123',
            originalInput: state.query,
            selectedMatch: FuzzyMatchResult(
              canonical: '${result.spec.brand}_${result.spec.model}',
              confidence: result.relevanceScore,
              distance: 0,
              matchType: result.matchType,
              requiresConfirmation: false,
            ),
          ));
        },
      );
    }
    return const EmptySearchWidget();
  },
)
```

## State Confidence System

The CombineBloc implements a confidence scoring system (0.0-1.0) for all states:

- **1.0**: Fresh data from server, exact matches
- **0.95**: High-confidence fuzzy matches, recent cache
- **0.9**: Cached data, brand matches
- **0.8**: Loading states, moderate confidence matches
- **0.7**: Partial data, sync pending
- **0.5**: Basic fallback data
- **0.0**: Error states, no data

```dart
// Use confidence in UI
BlocBuilder<CombineBloc, CombineState>(
  builder: (context, state) {
    return Column(
      children: [
        if (state.confidence < 0.8)
          ConfidenceWarningBanner(
            confidence: state.confidence,
            isFromCache: state.isFromCache,
            lastUpdated: state.lastUpdated,
          ),
        // Main content
        CombineListView(state: state),
      ],
    );
  },
)
```

## Progressive Data Levels

The system provides different levels of combine insights based on user volume:

### Minimal Level (< 5 users)
```dart
ProgressiveCapabilities(
  level: CapabilityLevel.minimal,
  userCount: 3,
  basicCapabilities: HarvestCapabilities(...),
  dataConfidence: 0.6,
)
```

### Moderate Level (5-15 users)
```dart
ProgressiveCapabilities(
  level: CapabilityLevel.moderate,
  userCount: 12,
  basicCapabilities: HarvestCapabilities(...),
  brandCapabilities: BrandCapabilities(
    brand: 'john_deere',
    moistureTolerance: MoistureTolerance(...),
    performanceMetrics: {'avgEfficiency': 0.87},
    recommendations: ['Works well in tough canola conditions'],
  ),
  dataConfidence: 0.8,
)
```

### Rich Level (15+ users)
```dart
ProgressiveCapabilities(
  level: CapabilityLevel.rich,
  userCount: 23,
  basicCapabilities: HarvestCapabilities(...),
  brandCapabilities: BrandCapabilities(...),
  modelCapabilities: ModelCapabilities(
    brand: 'john_deere',
    model: 'x9_1100',
    harvestCapabilities: HarvestCapabilities(...),
    peerComparison: PeerComparison(
      betterThan: ['case_ih_af_8250'],
      similarTo: ['new_holland_cr_10_90'],
      challengedBy: ['claas_lexion_8900'],
    ),
    expertRecommendations: [
      'Excellent for high-moisture wheat',
      'Consider additional cleaning for canola',
    ],
  ),
  dataConfidence: 0.95,
)
```

## Offline Persistence

The BLoC automatically persists state using hydrated_bloc:

```dart
// Automatically persisted
CombineLoaded(
  userCombines: [...],
  availableSpecs: [...],
  confidence: 0.9,
  isFromCache: true,
  lastUpdated: DateTime.now(),
)

// Restored on app restart
final restoredState = combineBloc.state;
if (restoredState is CombineLoaded && restoredState.isFromCache) {
  // Trigger background refresh
  combineBloc.add(LoadUserCombines(
    userId: userId,
    forceRefresh: false, // Will use cache but also refresh
  ));
}
```

## Testing

```dart
// Unit test example
void main() {
  group('CombineBloc', () {
    late CombineBloc combineBloc;
    late MockCombineRepository mockRepository;

    setUp(() {
      mockRepository = MockCombineRepository();
      combineBloc = CombineBloc(
        combineRepository: mockRepository,
        // ... other dependencies
      );
    });

    blocTest<CombineBloc, CombineState>(
      'emits [CombineLoading, CombineLoaded] when LoadUserCombines succeeds',
      build: () {
        when(() => mockRepository.getByUserId('user123'))
            .thenAnswer((_) async => [mockUserCombine]);
        return combineBloc;
      },
      act: (bloc) => bloc.add(LoadUserCombines(userId: 'user123')),
      expect: () => [
        isA<CombineLoading>(),
        isA<CombineLoaded>()
            .having((s) => s.userCombines.length, 'combine count', 1)
            .having((s) => s.confidence, 'confidence', 1.0),
      ],
    );
  });
}
```

## Performance Considerations

1. **Debounced Events**: Search and add events are debounced to prevent excessive API calls
2. **Throttled Sync**: Sync operations are throttled to prevent overwhelming the server
3. **Batch Processing**: Sync operations are processed in batches for efficiency
4. **Smart Caching**: Intelligent cache invalidation based on data freshness
5. **Progressive Loading**: Capabilities loaded on-demand to reduce initial load time

## Integration with UI

The CombineBloc is designed to work seamlessly with Flutter widgets:

```dart
class CombineManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<CombineBloc>()
        ..add(LoadUserCombines(userId: getCurrentUserId())),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Combines'),
          actions: [
            BlocBuilder<CombineBloc, CombineState>(
              builder: (context, state) {
                if (state is CombineLoaded && state.syncStatus == SyncStatus.syncing) {
                  return const CircularProgressIndicator();
                }
                return IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () {
                    context.read<CombineBloc>().add(SyncCombineData(
                      userId: getCurrentUserId(),
                      isManualSync: true,
                    ));
                  },
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<CombineBloc, CombineState>(
          listener: (context, state) {
            // Handle side effects (errors, navigation, etc.)
          },
          builder: (context, state) {
            return switch (state) {
              CombineInitial() => const WelcomeWidget(),
              CombineLoading() => const LoadingWidget(),
              CombineLoaded() => CombineListWidget(state: state),
              CombineNormalizationRequired() => NormalizationWidget(state: state),
              CombineConflictResolution() => ConflictResolutionWidget(state: state),
              CombineSearchResults() => SearchResultsWidget(state: state),
              CombineError() => ErrorWidget(error: state),
            };
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddCombineDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

This comprehensive CombineBloc system provides a robust, offline-first solution for combine management with intelligent normalization, progressive data loading, and advanced sync capabilities.