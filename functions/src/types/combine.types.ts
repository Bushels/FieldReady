/**
 * TypeScript interfaces for the Firebase combine specifications and normalization system
 * Implements offline-first architecture with proper typing for all collections
 */

import { Timestamp, FieldValue } from 'firebase-admin/firestore';

// Core data confidence levels
export type ConfidenceLevel = 'high' | 'medium' | 'low';
export type MatchType = 'exact' | 'variant' | 'fuzzy' | 'brand_alias';
export type SyncStatus = 'pending' | 'syncing' | 'completed' | 'failed';

// Base interface for all documents
export interface BaseDocument {
  id: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Moisture tolerance specifications
export interface MoistureTolerance {
  min: number;              // Minimum safe moisture %
  max: number;              // Maximum safe moisture %
  optimal: number;          // Optimal moisture %
  confidence: ConfidenceLevel;
}

// Tough crop ability ratings
export interface ToughCropAbility {
  rating: number;           // 1-10 scale
  crops: string[];          // Supported tough crops
  limitations: string[];    // Known limitations
  confidence: ConfidenceLevel;
}

// Source data tracking for transparency
export interface SourceData {
  userReports: number;      // Number of user data points
  manufacturerSpecs: boolean; // Has official specs
  expertValidation: boolean;  // Validated by experts
  lastUpdated: Timestamp;
}

// Main combine specifications document
export interface CombineSpec extends BaseDocument {
  brand: string;                    // Normalized brand (john_deere, case_ih, etc.)
  model: string;                    // Normalized model (x9_1100, s790, etc.)
  modelVariants: string[];          // Alternative spellings/formats
  year?: number;                    // Manufacturing year if known
  userId: string;                   // User who created the spec
  moistureTolerance: MoistureTolerance;
  toughCropAbility: ToughCropAbility;
  sourceData: SourceData;
  region?: string;                  // Geographic region for relevance
  isPublic: boolean;               // Whether to include in aggregations
}

// User's personal combine equipment
export interface UserCombine extends BaseDocument {
  userId: string;
  combineSpecId: string;           // Reference to CombineSpec
  nickname?: string;               // User's name for their combine
  purchaseYear?: number;           // When user acquired it
  hoursOfOperation?: number;       // Operating hours
  maintenanceNotes?: string[];     // User maintenance history
  customSettings: {
    moistureSettings?: {
      typical: number;
      minimum: number;
      maximum: number;
    };
    cropExperience?: Record<string, {
      rating: number;
      notes: string;
    }>;
  };
  isActive: boolean;               // Currently in use
  lastSyncAt?: Timestamp;          // For offline sync
}

// Fuzzy matching results
export interface FuzzyMatchResult {
  canonical: string;
  confidence: number;              // 0-1 score
  distance: number;                // Edit distance
  matchType: MatchType;
  requiresConfirmation: boolean;
  alternativeMatches?: Array<{
    canonical: string;
    confidence: number;
    matchType: MatchType;
  }>;
  cachedAt?: number;              // For caching strategy
}

// Model normalization rules
export interface ModelNormalizationRule extends BaseDocument {
  pattern: string;                 // Pattern to match
  canonical: string;               // Standardized result
  brand: string;                   // Associated brand
  confidence: number;              // Rule confidence
  isActive: boolean;               // Rule enabled
  source: 'manual' | 'learned' | 'fuzzy';
  usageCount: number;              // How often used
  lastUsed?: Timestamp;
}

// Brand aliases for normalization
export interface BrandAlias extends BaseDocument {
  alias: string;                   // Alternative brand name
  canonical: string;               // Standard brand name
  confidence: number;              // Alias confidence
  isActive: boolean;
  source: 'manual' | 'learned';
}

// Model variants for matching
export interface ModelVariant extends BaseDocument {
  variant: string;                 // Variant spelling
  canonicalBrand: string;         // Standard brand
  canonicalModel: string;         // Standard model
  confidence: number;
  source: 'manual' | 'learned' | 'fuzzy';
  usageCount: number;
}

// User confirmation for uncertain matches
export interface ConfirmationRequest extends BaseDocument {
  userId: string;
  originalInput: string;
  suggestedMatch: {
    brand: string;
    model: string;
    confidence: number;
  };
  alternatives: Array<{
    brand: string;
    model: string;
    confidence: number;
  }>;
  userFeedback?: {
    accepted: boolean;
    correctedBrand?: string;
    correctedModel?: string;
    timestamp: Timestamp;
  };
  status: 'pending' | 'confirmed' | 'corrected' | 'expired';
}

// Learning data for improving matching
export interface NormalizationLearning extends BaseDocument {
  originalInput: string;
  incorrectSuggestion?: string;
  correctAnswer: string;
  confidenceScore: number;
  userId: string;
  improved: boolean;               // Whether this improved the system
}

// Progressive insights based on data volume
export interface CombineInsight extends BaseDocument {
  region: string;
  level: 'basic' | 'brand' | 'model';
  totalFarmers: number;
  dataPoints: number;
  insights: {
    basic?: {
      startedHarvest: number;
      averageMoisture: number;
      weatherConditions: string;
      recommendation: string;
    };
    brand?: Array<{
      brand: string;
      farmers: number;
      started: number;
      averageMoisture: number;
      moistureRange: string;
      recommendation: string;
    }>;
    model?: Array<{
      brand: string;
      model: string;
      farmers: number;
      started: number;
      averageMoisture: number;
      moistureRange: string;
      toughCropRating: number;
      recommendations: string[];
      peerComparison?: {
        betterThan: string[];
        similarTo: string[];
        challengedBy: string[];
      };
    }>;
  };
  generatedAt: Timestamp;
  expiresAt: Timestamp;           // Cache expiry
}

// Regional aggregation data
export interface RegionalInsight extends BaseDocument {
  region: string;
  crop?: string;
  moistureRange?: string;
  totalUsers: number;
  activeUsers: number;
  dataQuality: ConfidenceLevel;
  lastUpdated: Timestamp;
}

// Offline sync queue for pending operations
export interface SyncOperation extends BaseDocument {
  userId: string;
  operation: 'create' | 'update' | 'delete';
  collection: string;
  documentId: string;
  data?: any;                     // The data to sync
  status: SyncStatus;
  retryCount: number;
  lastAttempt?: Timestamp;
  error?: string;
  priority: 'high' | 'medium' | 'low';
}

// Sync status tracking
export interface SyncStatus extends BaseDocument {
  userId: string;
  lastFullSync?: Timestamp;
  pendingOperations: number;
  failedOperations: number;
  isOnline: boolean;
  lastOnline?: Timestamp;
  syncInProgress: boolean;
}

// Cache management for offline access
export interface OfflineCache extends BaseDocument {
  userId: string;
  cacheKey: string;               // Unique cache identifier
  data: any;                      // Cached data
  collection: string;             // Source collection
  documentId?: string;            // Source document
  expiresAt: Timestamp;
  size: number;                   // Cache size in bytes
  accessCount: number;
  lastAccessed: Timestamp;
}

// User preferences for combine data
export interface UserPreferences extends BaseDocument {
  userId: string;
  defaultRegion?: string;
  preferredUnits: 'metric' | 'imperial';
  dataSharing: {
    allowAggregation: boolean;    // Include in community insights
    allowResearch: boolean;       // Include in research data
    shareLocation: boolean;       // Share regional data
  };
  notifications: {
    combineUpdates: boolean;
    communityInsights: boolean;
    systemAlerts: boolean;
  };
  privacySettings: {
    dataRetentionDays: number;    // How long to keep data
    deleteOnInactive: boolean;    // Auto-delete when inactive
    shareAnonymized: boolean;     // Share anonymized data
  };
}

// Audit log for PIPEDA compliance
export interface AuditLog extends BaseDocument {
  userId?: string;
  action: string;                 // Action performed
  collection: string;             // Collection affected
  documentId?: string;            // Document affected
  changes?: Record<string, any>;  // What changed
  ipAddress?: string;             // User IP
  userAgent?: string;             // User agent
  timestamp: Timestamp;
  complianceLevel: 'required' | 'optional' | 'system';
}

// Data retention policy
export interface DataRetentionPolicy extends BaseDocument {
  collection: string;
  retentionDays: number;
  autoDelete: boolean;
  backupBeforeDelete: boolean;
  exemptions: string[];           // User IDs exempt from policy
  lastCleanup?: Timestamp;
  nextCleanup: Timestamp;
}

// Request/Response types for API endpoints

export interface NormalizeRequest {
  input: string;
  context?: {
    year?: number;
    userId: string;
    region?: string;
  };
}

export interface NormalizeResponse {
  success: boolean;
  data?: {
    matches: FuzzyMatchResult[];
    bestMatch: {
      brand: string;
      model: string;
      confidence: number;
    };
  };
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export interface InsightsRequest {
  region: string;
  level?: 'progressive' | 'basic' | 'brand' | 'model';
  crop?: string;
  moistureRange?: string;
  userId: string;
}

export interface InsightsResponse {
  success: boolean;
  data?: CombineInsight;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
}

export interface ConfirmMatchRequest {
  originalInput: string;
  suggestedMatch: {
    brand: string;
    model: string;
  };
  userConfirmation: {
    accepted: boolean;
    correctedBrand?: string;
    correctedModel?: string;
  };
  userId: string;
}

export interface ConfirmMatchResponse {
  success: boolean;
  data?: {
    learned: boolean;
    improvedMatching: boolean;
    thanksMessage: string;
  };
  error?: {
    code: string;
    message: string;
  };
}

// Cloud Function context types
export interface CloudFunctionContext {
  timestamp: Timestamp;
  userId?: string;
  region?: string;
  requestId: string;
}

// Repository interface types for dependency injection
export interface CombineRepository {
  getCombineSpec(id: string): Promise<CombineSpec | null>;
  createCombineSpec(spec: Omit<CombineSpec, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  updateCombineSpec(id: string, updates: Partial<CombineSpec>): Promise<void>;
  getUserCombines(userId: string): Promise<UserCombine[]>;
  getNormalizationRules(): Promise<ModelNormalizationRule[]>;
  getBrandAliases(): Promise<BrandAlias[]>;
  getModelVariants(): Promise<ModelVariant[]>;
}

export interface InsightRepository {
  getRegionalInsights(region: string): Promise<RegionalInsight[]>;
  getCombineInsights(region: string, level: string): Promise<CombineInsight | null>;
  updateInsights(insight: CombineInsight): Promise<void>;
}

export interface SyncRepository {
  queueOperation(operation: Omit<SyncOperation, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  getPendingOperations(userId: string): Promise<SyncOperation[]>;
  markOperationComplete(operationId: string): Promise<void>;
  markOperationFailed(operationId: string, error: string): Promise<void>;
}

// Utility types for collection references
export type CombineCollections = 
  | 'combineSpecs'
  | 'userCombines' 
  | 'modelNormalization'
  | 'combineInsights'
  | 'brandAliases'
  | 'modelVariants'
  | 'normalizationLearning'
  | 'regionalInsights'
  | 'syncOperations'
  | 'offlineCache'
  | 'auditLogs';

// Error types for better error handling
export class CombineError extends Error {
  constructor(
    public code: string,
    message: string,
    public details?: any
  ) {
    super(message);
    this.name = 'CombineError';
  }
}

export class NormalizationError extends CombineError {
  constructor(message: string, input?: string, suggestions?: string[]) {
    super('NORMALIZATION_FAILED', message, { input, suggestions });
    this.name = 'NormalizationError';
  }
}

export class InsufficientDataError extends CombineError {
  constructor(
    currentLevel: string,
    requiredUsers: number,
    actualUsers: number
  ) {
    super(
      'INSUFFICIENT_DATA',
      'Not enough data for requested insight level',
      { currentLevel, requiredUsers, actualUsers }
    );
    this.name = 'InsufficientDataError';
  }
}

// Export all types for use in other modules
export type {
  BaseDocument,
  MoistureTolerance,
  ToughCropAbility,
  SourceData,
  CombineSpec,
  UserCombine,
  FuzzyMatchResult,
  ModelNormalizationRule,
  BrandAlias,
  ModelVariant,
  ConfirmationRequest,
  NormalizationLearning,
  CombineInsight,
  RegionalInsight,
  SyncOperation,
  OfflineCache,
  UserPreferences,
  AuditLog,
  DataRetentionPolicy
};