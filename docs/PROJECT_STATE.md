# PROJECT_STATE.md - FieldReady Architecture & Decision Log

## Last Updated: 2025-01-29

## Project Overview
FieldReady (formerly FieldFirst) is a precision agriculture platform providing hyperlocal weather intelligence for Canadian prairie farmers to optimize harvest timing and minimize crop loss.

## Current Architecture (As-Is)

### Technology Stack
- **Frontend**: Flutter with Dart
- **Backend**: Firebase Cloud Functions (TypeScript)
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Hosting**: Firebase Hosting
- **Storage**: Firebase Storage
- **Real-time Updates**: Firestore real-time listeners

## Target Architecture (To-Be)

### Technology Stack
- **Frontend**: Next.js 14 with TypeScript
- **Backend**: Node.js with Express
- **Database**: PostgreSQL with PostGIS extensions
- **Caching**: Redis for API response caching
- **Weather Data**: Tomorrow.io API (primary), MSC as fallback
- **Deployment**: Vercel (frontend), Railway/Render (backend)
- **Monitoring**: Sentry for error tracking, Mixpanel for analytics

## Current Core Components (Firebase/Flutter)

### Backend Components (Cloud Functions)

#### 1. Combine Normalization Service
**Location**: `/functions/src/services/combineNormalizer.ts`
- Fuzzy matching for combine model variants
- Brand standardization and normalization
- Confidence scoring for matches

#### 2. Type Definitions
**Location**: `/functions/src/types/combine.types.ts`
- TypeScript interfaces for combine data
- Normalization result types
- Brand and model mapping structures

### Frontend Components (Flutter/Dart)

#### 1. Domain Layer
**Location**: `/lib/domain/`
- **Models**: `combine_models.dart`, `harvest_models.dart`
- **Repositories**: `combine_repository.dart`
- **Services**: 
  - `combine_normalizer.dart` - Client-side normalization
  - `combine_examples.dart` - Example data for testing
  - `harvest_intelligence.dart` - Harvest decision logic
  - `harvest_cache_service.dart` - Local data caching
  - `sync_service.dart` - Offline/online synchronization
  - `weather_api_service.dart` - Weather data integration

#### 2. Presentation Layer
**Location**: `/lib/presentation/`
- **BLoC Pattern**: 
  - `combine_bloc.dart` - Business logic component
  - `combine_event.dart` - User actions
  - `combine_state.dart` - UI state management
  - `combine_error_handler.dart` - Error handling
  - `combine_sync_manager.dart` - Sync coordination
- **Pages**: `combine_setup_page.dart`
- **Widgets**: 
  - `combine_selection_widget.dart`
  - `combine_capability_card.dart`
  - `combine_confirmation_dialog.dart`

### Firebase Configuration
- **Firestore Rules**: `/firestore.rules` - Security rules
- **Firestore Indexes**: `/firestore.indexes.json` - Query optimization
- **Storage Rules**: `/storage.rules` - File storage security
- **Firebase Config**: `/firebase.json` - Project configuration

## Target Core Components (Next.js/Node.js)

### 1. Weather Intelligence Engine
**Target Location**: `/backend/src/services/weather/`
- `TomorrowIOClient.ts` - Primary weather data provider
- `MSCFallbackClient.ts` - Government weather data fallback
- `WeatherAggregator.ts` - Combines and normalizes data sources
- `LocationClusterer.ts` - Groups nearby locations to reduce API calls

### 2. Field Management System
**Target Location**: `/backend/src/services/fields/`
- `FieldRepository.ts` - Database operations for field data
- `FieldBoundaryService.ts` - Polygon management and geospatial queries
- `HarvestWindowCalculator.ts` - Core optimization algorithms

### 3. Alert System
**Target Location**: `/backend/src/services/alerts/`
- `AlertEngine.ts` - Real-time monitoring and alert generation
- `NotificationService.ts` - Multi-channel alert delivery
- `AlertRuleProcessor.ts` - Custom alert rule evaluation

### 4. Community Features
**Target Location**: `/backend/src/services/community/`
- `ObservationService.ts` - User-reported field conditions
- `CommunityInsights.ts` - Aggregated local intelligence
- `DataValidation.ts` - Community data quality control

### 5. Combine Intelligence System
**Target Location**: `/backend/src/services/combines/`
- `CombineSpecsRepository.ts` - Database operations for combine specifications
- `ModelNormalizationService.ts` - Fuzzy matching and brand standardization
- `CombineInsightsAggregator.ts` - Progressive data aggregation by user volume
- `CapabilityAnalyzer.ts` - Moisture tolerance and tough crop ability analysis

## Current File Structure (Firebase/Flutter)
```
FieldReady/
├── docs/                    # Documentation
│   ├── PROJECT_STATE.md    # This file
│   ├── API_CONTRACTS.md    # API specifications
│   ├── COMBINE_NORMALIZATION.md
│   ├── CROP_THRESHOLDS.md
│   ├── FIREBASE_ARCHITECTURE.md
│   └── TROUBLESHOOTING.md
├── functions/              # Firebase Cloud Functions
│   ├── src/
│   │   ├── index.ts       # Function exports
│   │   ├── services/      # Business logic
│   │   │   └── combineNormalizer.ts
│   │   └── types/         # TypeScript types
│   │       └── combine.types.ts
│   ├── package.json
│   └── tsconfig.json
├── lib/                    # Flutter application
│   ├── domain/            # Business logic layer
│   │   ├── models/
│   │   ├── repositories/
│   │   └── services/
│   └── presentation/      # UI layer
│       ├── blocs/         # State management
│       ├── pages/         # Screen components
│       └── widgets/       # Reusable widgets
├── public/                 # Web hosting files
├── scripts/               # Build and deployment scripts
├── firebase.json          # Firebase configuration
├── firestore.rules        # Security rules
├── firestore.indexes.json # Database indexes
├── storage.rules          # Storage security
└── pubspec.yaml           # Flutter dependencies
```

## Target File Structure (Next.js/Node.js)
```
FieldReady/
├── frontend/              # Next.js application
│   ├── src/
│   │   ├── app/          # App router pages
│   │   ├── components/   # React components
│   │   ├── services/     # API clients
│   │   ├── hooks/        # Custom hooks
│   │   └── types/        # TypeScript types
│   └── public/           # Static assets
├── backend/               # Node.js API
│   ├── src/
│   │   ├── api/          # API routes
│   │   ├── services/     # Business logic
│   │   ├── models/       # Database models
│   │   ├── middleware/   # Express middleware
│   │   └── config/       # Configuration
│   └── tests/            # Test suites
└── docs/                  # Documentation
```

## API Contracts

### Internal API Endpoints
- `POST /api/fields` - Create new field
- `GET /api/fields/:id/harvest-windows` - Get optimal harvest times
- `POST /api/fields/:id/observations` - Submit field observation
- `GET /api/weather/forecast/:lat/:lng` - Get weather forecast
- `POST /api/alerts/subscribe` - Subscribe to alerts

### External Integrations
- Tomorrow.io API v4 - 500 calls/day free tier
- MSC Datamart - Unlimited government weather data
- SendGrid - Email notifications
- Twilio - SMS alerts (premium only)

## Data Models

### CombineSpecs Schema
```typescript
interface CombineSpecs {
  id: string;
  brand: string;                    // Normalized brand (john_deere, case_ih, new_holland, etc.)
  model: string;                    // Normalized model (x9_1100, s790, etc.)
  modelVariants: string[];          // Alternative spellings/formats
  year: number | null;              // Manufacturing year if known
  moistureTolerance: {
    min: number;                    // Minimum safe moisture %
    max: number;                    // Maximum safe moisture %
    optimal: number;                // Optimal moisture %
    confidence: 'high' | 'medium' | 'low';
  };
  toughCropAbility: {
    rating: number;                 // 1-10 scale
    crops: string[];                // Supported tough crops
    limitations: string[];          // Known limitations
    confidence: 'high' | 'medium' | 'low';
  };
  sourceData: {
    userReports: number;            // Number of user data points
    manufacturerSpecs: boolean;     // Has official specs
    expertValidation: boolean;      // Validated by experts
    lastUpdated: Date;
  };
  createdAt: Date;
  updatedAt: Date;
}
```

### Progressive Data Aggregation Strategy
The system displays increasingly specific insights based on available data volume:

**Level 1 - Minimal Data (< 5 users per model)**:
- "15/237 farmers started harvest"
- Generic moisture recommendations
- Basic weather alerts

**Level 2 - Moderate Data (5-15 users per model)**:
- "8/43 with John Deere combines started"
- Brand-specific moisture tolerances
- Equipment-aware alerts

**Level 3 - Rich Data (15+ users per model)**:
- "5/12 with X9 1100 at 14.2% avg moisture"
- Model-specific capabilities
- Precise harvest window recommendations
- Tough crop handling insights

### Model Normalization Strategy
```typescript
interface ModelNormalization {
  canonical: string;               // Standardized model name
  variants: string[];              // All known variations
  brandAliases: Record<string, string>; // Brand name mappings
  fuzzyThreshold: number;          // Similarity threshold (0.8)
  confidenceScore: number;         // Match confidence (0-1)
  requiresConfirmation: boolean;   // User confirmation needed
}
```

## Migration Status

### Current State
- **Platform**: Firebase + Flutter mobile/web application
- **Features Implemented**:
  - Basic combine management with data fetched from Firestore
  - Firebase integration (Core, Auth, Firestore)
  - BLoC state management pattern
  - Fuzzy search for combines

### Migration Progress
- **Planning**: Complete (EXECUTION_PLAN.md created)
- **Infrastructure**: Not started
- **Data Migration**: Not started
- **Feature Parity**: Not started
- **Testing**: Not started
- **Deployment**: Not started

## Decision Log

### 2025-07-29: Firebase and Flutter Web App Initialization
**Decision**: Corrected the Flutter web app initialization process and integrated Firebase.
**Rationale**:
- The app was stuck on a loading screen due to an outdated web initialization script in `web/index.html`.
- The project was missing Firebase dependencies in `pubspec.yaml` and the Firebase initialization call in `lib/main.dart`.
- The app was using hardcoded data instead of fetching data from Firestore.
**Implementation Details**:
- Replaced the old `_flutter.loader.load()` with the modern `_flutter.loader.loadEntrypoint()` in `web/index.html`.
- Added `firebase_core`, `firebase_auth`, and `cloud_firestore` to `pubspec.yaml`.
- Initialized Firebase in `lib/main.dart`.
- Replaced the hardcoded `CombineDataSource` with a `FirestoreService` to fetch data from the `combineSpecs` collection.
- Refactored `combine_selection_modal.dart` and `fuzzy_search.dart` to use the new `FirestoreService`.

### 2025-01-29: Architecture Documentation Update
**Decision**: Update PROJECT_STATE.md to reflect actual current architecture
**Rationale**:
- Documentation was describing target state as current state
- Need clear distinction between as-is and to-be architecture
- Helps track migration progress accurately

### 2025-01-28: Technology Stack Migration Decision
**Decision**: Migrate from Firebase/Flutter to Next.js/Node.js/PostgreSQL
**Rationale**:
- Better suited for web-first precision agriculture platform
- PostgreSQL with PostGIS provides superior geospatial capabilities
- Node.js backend allows more flexible integrations
- Next.js provides better SEO and performance for web

### 2025-01-28: Combine Intelligence System Architecture
**Decision**: Implement progressive data aggregation with fuzzy model matching
**Rationale**:
- User-entered combine data is inconsistent (X9 1100 vs 1100x9 vs X9-1100)
- Need to balance data granularity with statistical significance
- Progressive disclosure prevents overwhelming users with sparse data
- Fuzzy matching improves data consolidation without sacrificing accuracy

**Implementation Details**:
- Levenshtein distance algorithm for model variant matching
- Confidence scoring system for uncertain matches
- User confirmation flow for low-confidence matches
- Minimum 5 users per model before showing specific insights

### 2025-01-28: Location Clustering Algorithm
**Decision**: Implement hexagonal grid clustering with 5km radius
**Rationale**: 
- Reduces API calls by 60-80% for dense farming areas
- 5km provides sufficient accuracy for microclimate variations
- Hexagonal grid ensures even coverage without gaps

### 2025-01-27: Weather Data Caching Strategy
**Decision**: 6-hour cache for forecast data, 24-hour for historical
**Rationale**:
- Balances API cost with data freshness
- Weather patterns change slowly enough for 6-hour windows
- Historical data is immutable

### 2025-01-26: Free Tier Limitations
**Decision**: Limit free users to 3 fields, 1km resolution
**Rationale**:
- Sustainable within Tomorrow.io free tier limits
- Encourages upgrades for larger operations
- Still provides significant value for small farms

### 2025-01-25: Database Schema Design
**Decision**: Separate tables for fields, observations, and forecasts
**Rationale**:
- Optimizes query performance for time-series data
- Allows independent scaling of components
- Simplifies data retention policies

## Technical Debt & Future Considerations

### Current System (Firebase/Flutter)

#### High Priority
1. Complete weather API integration
2. Implement comprehensive error handling
3. Add unit and integration tests
4. Optimize Firestore queries with proper indexes
5. Implement proper offline queue management

#### Medium Priority
1. Enhance combine normalization accuracy
2. Add user analytics tracking
3. Implement push notifications
4. Optimize Flutter web performance

### Target System (Next.js/Node.js)

#### High Priority
1. Implement request queuing for API rate limit management
2. Add database connection pooling for scale
3. Optimize location clustering algorithm for sparse areas

#### Medium Priority
1. Implement WebSocket for real-time alerts
2. Add GraphQL API for mobile app
3. Enhance caching with edge CDN

#### Low Priority
1. Machine learning for harvest prediction
2. Satellite imagery integration
3. Blockchain for community data verification

## Environment Variables

### Current System (Firebase)
```
# Firebase Configuration (auto-configured in Firebase Functions)
# No manual environment variables needed for basic Firebase services

# Weather APIs (if implemented)
WEATHER_API_KEY=
WEATHER_API_URL=
```

### Target System (Next.js/Node.js)
```
# Weather APIs
TOMORROW_IO_API_KEY=
TOMORROW_IO_BASE_URL=https://api.tomorrow.io/v4

# Database
DATABASE_URL=postgresql://user:password@host:5432/fieldready
REDIS_URL=redis://localhost:6379

# Services
SENDGRID_API_KEY=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=

# Feature Flags
ENABLE_MSC_FALLBACK=true
ENABLE_COMMUNITY_FEATURES=true
ENABLE_PREMIUM_FEATURES=true
```

## Deployment Configuration

### Current Deployment (Firebase)
- **Hosting**: Firebase Hosting
- **Functions**: Firebase Cloud Functions
- **Database**: Cloud Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Domain**: Configured through Firebase Hosting

### Target Deployment (Next.js/Node.js)
- **Frontend**: Vercel (auto-deploy from main branch)
- **Backend**: Railway with PostgreSQL and Redis add-ons
- **Domain**: fieldready.ca with SSL

### Staging Environment (Target)
- **Frontend**: Vercel preview deployments
- **Backend**: Separate Railway project
- **Database**: Separate PostgreSQL instance

## Performance Benchmarks
- API response time: < 200ms (p95)
- Weather data freshness: < 6 hours
- Alert delivery: < 30 seconds
- Page load time: < 2 seconds

## Security Considerations
- API keys stored in environment variables
- Database credentials encrypted at rest
- HTTPS enforced for all endpoints
- Rate limiting on all public APIs
- Input validation and sanitization