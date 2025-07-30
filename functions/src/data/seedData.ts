/**
 * Initial seed data for the FieldFirst combine specifications system
 * Contains base combine specifications, normalization rules, and brand aliases
 */

import { 
  CombineSpec, 
  BrandAlias, 
  ModelVariant, 
  ModelNormalizationRule,
  DataRetentionPolicy
} from '../types/combine.types';
import { Timestamp } from 'firebase-admin/firestore';

// Base combine specifications for popular models
export const seedCombineSpecs: Omit<CombineSpec, 'id' | 'createdAt' | 'updatedAt'>[] = [
  // John Deere X9 Series
  {
    brand: 'john_deere',
    model: 'x9_1100',
    modelVariants: [
      'x9 1100', 'x91100', 'x9-1100', '1100x9', 
      'x 9 1100', 'x.9.1100', 'john deere x9 1100', 'jd x9 1100'
    ],
    year: 2024,
    userId: 'system',
    moistureTolerance: {
      min: 12.0,
      max: 25.0,
      optimal: 15.0,
      confidence: 'high'
    },
    toughCropAbility: {
      rating: 9,
      crops: ['wheat', 'canola', 'barley', 'oats', 'soybeans', 'corn'],
      limitations: ['extremely high moisture conditions'],
      confidence: 'high'
    },
    sourceData: {
      userReports: 25,
      manufacturerSpecs: true,
      expertValidation: true,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },
  {
    brand: 'john_deere',
    model: 'x9_1000',
    modelVariants: [
      'x9 1000', 'x91000', 'x9-1000', '1000x9',
      'x 9 1000', 'x.9.1000', 'john deere x9 1000', 'jd x9 1000'
    ],
    year: 2024,
    userId: 'system',
    moistureTolerance: {
      min: 12.0,
      max: 24.0,
      optimal: 15.0,
      confidence: 'high'
    },
    toughCropAbility: {
      rating: 8,
      crops: ['wheat', 'canola', 'barley', 'oats', 'soybeans'],
      limitations: ['extremely high moisture conditions', 'very heavy straw conditions'],
      confidence: 'high'
    },
    sourceData: {
      userReports: 18,
      manufacturerSpecs: true,
      expertValidation: true,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },
  {
    brand: 'john_deere',
    model: 's790',
    modelVariants: [
      's 790', 's-790', 'deere s790', 'jd s790',
      '790s', 's.790', 'john deere s790'
    ],
    year: 2023,
    userId: 'system',
    moistureTolerance: {
      min: 13.0,
      max: 23.0,  
      optimal: 16.0,
      confidence: 'high'
    },
    toughCropAbility: {
      rating: 7,
      crops: ['wheat', 'canola', 'barley', 'soybeans'],
      limitations: ['very high moisture conditions', 'heavy straw loads'],
      confidence: 'high'
    },
    sourceData: {
      userReports: 45,
      manufacturerSpecs: true,
      expertValidation: true,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },

  // Case IH Axial Flow Series
  {
    brand: 'case_ih',
    model: 'af_8250',
    modelVariants: [
      'axial flow 8250', 'af8250', 'af-8250',
      '8250 af', 'axialflow 8250', 'case 8250', 'case ih 8250'
    ],
    year: 2024,
    userId: 'system',
    moistureTolerance: {
      min: 12.5,
      max: 24.0,
      optimal: 15.5,
      confidence: 'high'
    },
    toughCropAbility: {
      rating: 8,
      crops: ['wheat', 'canola', 'barley', 'oats', 'soybeans', 'corn'],
      limitations: ['extremely wet conditions'],
      confidence: 'high'
    },
    sourceData: {
      userReports: 32,
      manufacturerSpecs: true,
      expertValidation: true,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },
  {
    brand: 'case_ih',
    model: 'af_9250',
    modelVariants: [
      'axial flow 9250', 'af9250', 'af-9250',
      '9250 af', 'axialflow 9250', 'case 9250', 'case ih 9250'
    ],
    year: 2024,
    userId: 'system',
    moistureTolerance: {
      min: 12.0,
      max: 25.0,
      optimal: 15.0,
      confidence: 'high'
    },
    toughCropAbility: {
      rating: 9,
      crops: ['wheat', 'canola', 'barley', 'oats', 'soybeans', 'corn', 'sunflowers'],
      limitations: ['extreme weather conditions only'],
      confidence: 'high'
    },
    sourceData: {
      userReports: 28,
      manufacturerSpecs: true,
      expertValidation: true,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },

  // New Holland CR Series
  {
    brand: 'new_holland',
    model: 'cr_10.90',
    modelVariants: [
      'cr10.90', 'cr 10.90', 'cr-10.90', 'cr1090',
      'new holland cr10.90', 'nh cr10.90', 'cr 1090'
    ],
    year: 2023,
    userId: 'system',
    moistureTolerance: {
      min: 13.0,
      max: 23.0,
      optimal: 16.0,
      confidence: 'medium'
    },
    toughCropAbility: {
      rating: 7,
      crops: ['wheat', 'canola', 'barley', 'soybeans'],
      limitations: ['high moisture conditions', 'very heavy straw'],
      confidence: 'medium'
    },
    sourceData: {
      userReports: 15,
      manufacturerSpecs: true,
      expertValidation: false,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },

  // Claas Lexion Series
  {
    brand: 'claas',
    model: 'lexion_8900',
    modelVariants: [
      'lexion 8900', 'lex8900', 'lex-8900',
      '8900 lexion', 'claas 8900', 'claas lexion8900'
    ],
    year: 2024,
    userId: 'system',
    moistureTolerance: {
      min: 12.0,
      max: 24.0,
      optimal: 15.0,
      confidence: 'medium'
    },
    toughCropAbility: {
      rating: 8,
      crops: ['wheat', 'canola', 'barley', 'oats'],
      limitations: ['very high moisture conditions'],
      confidence: 'medium'
    },
    sourceData: {
      userReports: 12,
      manufacturerSpecs: true,
      expertValidation: false,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  },

  // Massey Ferguson IDEAL Series
  {
    brand: 'massey_ferguson',
    model: 'ideal_9t',
    modelVariants: [
      'ideal 9t', 'ideal9t', 'ideal-9t',
      '9t ideal', 'massey 9t', 'mf 9t', 'mf ideal 9t'
    ],
    year: 2023,
    userId: 'system',
    moistureTolerance: {
      min: 13.0,
      max: 22.0,
      optimal: 16.0,
      confidence: 'medium'
    },
    toughCropAbility: {
      rating: 6,
      crops: ['wheat', 'canola', 'barley'],
      limitations: ['high moisture conditions', 'heavy straw loads', 'tough crop conditions'],
      confidence: 'medium'
    },
    sourceData: {
      userReports: 8,
      manufacturerSpecs: true,
      expertValidation: false,
      lastUpdated: Timestamp.now()
    },
    region: 'western_canada',
    isPublic: true
  }
];

// Brand aliases for normalization
export const seedBrandAliases: Omit<BrandAlias, 'id' | 'createdAt' | 'updatedAt'>[] = [
  // John Deere variants
  { alias: 'jd', canonical: 'john_deere', confidence: 0.95, isActive: true, source: 'manual' },
  { alias: 'johndeere', canonical: 'john_deere', confidence: 0.98, isActive: true, source: 'manual' },
  { alias: 'john-deere', canonical: 'john_deere', confidence: 0.95, isActive: true, source: 'manual' },
  { alias: 'deere', canonical: 'john_deere', confidence: 0.90, isActive: true, source: 'manual' },
  { alias: 'john deer', canonical: 'john_deere', confidence: 0.85, isActive: true, source: 'manual' },
  
  // Case IH variants
  { alias: 'caseih', canonical: 'case_ih', confidence: 0.98, isActive: true, source: 'manual' },
  { alias: 'case-ih', canonical: 'case_ih', confidence: 0.95, isActive: true, source: 'manual' },
  { alias: 'case ih', canonical: 'case_ih', confidence: 0.98, isActive: true, source: 'manual' },
  { alias: 'cnh', canonical: 'case_ih', confidence: 0.80, isActive: true, source: 'manual' },
  { alias: 'case', canonical: 'case_ih', confidence: 0.75, isActive: true, source: 'manual' },
  
  // New Holland variants
  { alias: 'newholland', canonical: 'new_holland', confidence: 0.98, isActive: true, source: 'manual' },
  { alias: 'new-holland', canonical: 'new_holland', confidence: 0.95, isActive: true, source: 'manual' },
  { alias: 'nh', canonical: 'new_holland', confidence: 0.90, isActive: true, source: 'manual' },
  { alias: 'new holland', canonical: 'new_holland', confidence: 0.98, isActive: true, source: 'manual' },
  
  // Claas variants
  { alias: 'class', canonical: 'claas', confidence: 0.80, isActive: true, source: 'manual' },
  { alias: 'clas', canonical: 'claas', confidence: 0.75, isActive: true, source: 'manual' },
  { alias: 'klaus', canonical: 'claas', confidence: 0.70, isActive: true, source: 'manual' },
  
  // Massey Ferguson variants
  { alias: 'mf', canonical: 'massey_ferguson', confidence: 0.95, isActive: true, source: 'manual' },
  { alias: 'massey', canonical: 'massey_ferguson', confidence: 0.85, isActive: true, source: 'manual' },
  { alias: 'ferguson', canonical: 'massey_ferguson', confidence: 0.70, isActive: true, source: 'manual' },
  { alias: 'massey ferguson', canonical: 'massey_ferguson', confidence: 0.98, isActive: true, source: 'manual' },
  
  // Gleaner variants
  { alias: 'agco', canonical: 'gleaner', confidence: 0.75, isActive: true, source: 'manual' },
  
  // Fendt variants
  { alias: 'fent', canonical: 'fendt', confidence: 0.80, isActive: true, source: 'manual' },
  { alias: 'fendit', canonical: 'fendt', confidence: 0.75, isActive: true, source: 'manual' }
]; 

// Model variants for fuzzy matching
export const seedModelVariants: Omit<ModelVariant, 'id' | 'createdAt' | 'updatedAt'>[] = [
  // John Deere X9 Series variants
  { variant: 'x9 1100', canonicalBrand: 'john_deere', canonicalModel: 'x9_1100', confidence: 0.98, source: 'manual', usageCount: 45 },
  { variant: 'x91100', canonicalBrand: 'john_deere', canonicalModel: 'x9_1100', confidence: 0.95, source: 'manual', usageCount: 23 },
  { variant: 'x9-1100', canonicalBrand: 'john_deere', canonicalModel: 'x9_1100', confidence: 0.95, source: 'manual', usageCount: 18 },
  { variant: '1100x9', canonicalBrand: 'john_deere', canonicalModel: 'x9_1100', confidence: 0.90, source: 'manual', usageCount: 12 },
  { variant: 'x 9 1100', canonicalBrand: 'john_deere', canonicalModel: 'x9_1100', confidence: 0.92, source: 'manual', usageCount: 8 },
  
  { variant: 'x9 1000', canonicalBrand: 'john_deere', canonicalModel: 'x9_1000', confidence: 0.98, source: 'manual', usageCount: 38 },
  { variant: 'x91000', canonicalBrand: 'john_deere', canonicalModel: 'x9_1000', confidence: 0.95, source: 'manual', usageCount: 19 },
  { variant: 'x9-1000', canonicalBrand: 'john_deere', canonicalModel: 'x9_1000', confidence: 0.95, source: 'manual', usageCount: 15 },
  
  // John Deere S Series variants
  { variant: 's 790', canonicalBrand: 'john_deere', canonicalModel: 's790', confidence: 0.98, source: 'manual', usageCount: 67 },
  { variant: 's-790', canonicalBrand: 'john_deere', canonicalModel: 's790', confidence: 0.95, source: 'manual', usageCount: 34 },
  { variant: '790s', canonicalBrand: 'john_deere', canonicalModel: 's790', confidence: 0.90, source: 'manual', usageCount: 28 },
  { variant: 's.790', canonicalBrand: 'john_deere', canonicalModel: 's790', confidence: 0.92, source: 'manual', usageCount: 15 },
  
  // Case IH Axial Flow variants
  { variant: 'axial flow 8250', canonicalBrand: 'case_ih', canonicalModel: 'af_8250', confidence: 0.98, source: 'manual', usageCount: 52 },
  { variant: 'af8250', canonicalBrand: 'case_ih', canonicalModel: 'af_8250', confidence: 0.95, source: 'manual', usageCount: 31 },
  { variant: 'af-8250', canonicalBrand: 'case_ih', canonicalModel: 'af_8250', confidence: 0.95, source: 'manual', usageCount: 24 },
  { variant: '8250 af', canonicalBrand: 'case_ih', canonicalModel: 'af_8250', confidence: 0.90, source: 'manual', usageCount: 18 },
  { variant: 'axialflow 8250', canonicalBrand: 'case_ih', canonicalModel: 'af_8250', confidence: 0.92, source: 'manual', usageCount: 16 },
  
  { variant: 'axial flow 9250', canonicalBrand: 'case_ih', canonicalModel: 'af_9250', confidence: 0.98, source: 'manual', usageCount: 43 },
  { variant: 'af9250', canonicalBrand: 'case_ih', canonicalModel: 'af_9250', confidence: 0.95, source: 'manual', usageCount: 26 },
  { variant: 'af-9250', canonicalBrand: 'case_ih', canonicalModel: 'af_9250', confidence: 0.95, source: 'manual', usageCount: 21 },
  
  // New Holland CR Series variants
  { variant: 'cr10.90', canonicalBrand: 'new_holland', canonicalModel: 'cr_10.90', confidence: 0.98, source: 'manual', usageCount: 29 },
  { variant: 'cr 10.90', canonicalBrand: 'new_holland', canonicalModel: 'cr_10.90', confidence: 0.98, source: 'manual', usageCount: 24 },
  { variant: 'cr-10.90', canonicalBrand: 'new_holland', canonicalModel: 'cr_10.90', confidence: 0.95, source: 'manual', usageCount: 18 },
  { variant: 'cr1090', canonicalBrand: 'new_holland', canonicalModel: 'cr_10.90', confidence: 0.90, source: 'manual', usageCount: 15 },
  
  // Claas Lexion variants
  { variant: 'lexion 8900', canonicalBrand: 'claas', canonicalModel: 'lexion_8900', confidence: 0.98, source: 'manual', usageCount: 22 },
  { variant: 'lex8900', canonicalBrand: 'claas', canonicalModel: 'lexion_8900', confidence: 0.90, source: 'manual', usageCount: 12 },
  { variant: 'lex-8900', canonicalBrand: 'claas', canonicalModel: 'lexion_8900', confidence: 0.90, source: 'manual', usageCount: 9 },
  
  // Massey Ferguson IDEAL variants
  { variant: 'ideal 9t', canonicalBrand: 'massey_ferguson', canonicalModel: 'ideal_9t', confidence: 0.98, source: 'manual', usageCount: 16 },
  { variant: 'ideal9t', canonicalBrand: 'massey_ferguson', canonicalModel: 'ideal_9t', confidence: 0.95, source: 'manual', usageCount: 8 },
  { variant: 'ideal-9t', canonicalBrand: 'massey_ferguson', canonicalModel: 'ideal_9t', confidence: 0.95, source: 'manual', usageCount: 6 }
];

// Normalization rules for pattern matching
export const seedNormalizationRules: Omit<ModelNormalizationRule, 'id' | 'createdAt' | 'updatedAt'>[] = [
  // X-Series pattern matching
  {
    pattern: 'x9\\s*(\\d{4})',
    canonical: 'x9_$1',
    brand: 'john_deere',
    confidence: 0.95,
    isActive: true,
    source: 'manual',
    usageCount: 156,
    lastUsed: Timestamp.now()
  },
  
  // S-Series pattern matching
  {
    pattern: 's\\s*(\\d{3})',
    canonical: 's$1',
    brand: 'john_deere',
    confidence: 0.95,
    isActive: true,
    source: 'manual',
    usageCount: 234,
    lastUsed: Timestamp.now()
  },
  
  // Axial Flow pattern matching
  {
    pattern: 'a(?:xial)?\\s*f(?:low)?\\s*(\\d{4})',
    canonical: 'af_$1',
    brand: 'case_ih',
    confidence: 0.95,
    isActive: true,
    source: 'manual',
    usageCount: 189,
    lastUsed: Timestamp.now()
  },
  
  // CR Series pattern matching
  {
    pattern: 'cr\\s*(\\d{1,2}\\.?\\d{0,2})',
    canonical: 'cr_$1',
    brand: 'new_holland',
    confidence: 0.90,
    isActive: true,
    source: 'manual',
    usageCount: 87,
    lastUsed: Timestamp.now()
  },
  
  // Lexion pattern matching
  {
    pattern: 'lex(?:ion)?\\s*(\\d{4})',
    canonical: 'lexion_$1',
    brand: 'claas',
    confidence: 0.90,
    isActive: true,
    source: 'manual',
    usageCount: 45,
    lastUsed: Timestamp.now()
  },
  
  // IDEAL pattern matching
  {
    pattern: 'ideal\\s*(\\d+[a-z]?)',
    canonical: 'ideal_$1',
    brand: 'massey_ferguson',
    confidence: 0.90,
    isActive: true,
    source: 'manual',
    usageCount: 32,
    lastUsed: Timestamp.now()
  }
];

// Data retention policies for PIPEDA compliance
export const seedDataRetentionPolicies: Omit<DataRetentionPolicy, 'id' | 'createdAt' | 'updatedAt'>[] = [
  {
    collection: 'userCombines',
    retentionDays: 2555, // 7 years
    autoDelete: true,
    backupBeforeDelete: true,
    exemptions: [],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)) // 30 days from now
  },
  {
    collection: 'combineSpecs',
    retentionDays: 3650, // 10 years for specs
    autoDelete: false, // Keep for research
    backupBeforeDelete: true,
    exemptions: ['system'],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)) // 90 days from now
  },
  {
    collection: 'normalizationLearning',
    retentionDays: 1825, // 5 years
    autoDelete: true,
    backupBeforeDelete: true,
    exemptions: [],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
  },
  {
    collection: 'auditLogs',
    retentionDays: 2555, // 7 years for audit compliance
    autoDelete: true,
    backupBeforeDelete: true,
    exemptions: [],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
  },
  {
    collection: 'offlineCache',
    retentionDays: 30, // 30 days for cache
    autoDelete: true,
    backupBeforeDelete: false,
    exemptions: [],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 1 * 24 * 60 * 60 * 1000)) // Daily cleanup
  },
  {
    collection: 'syncOperations',
    retentionDays: 90, // 90 days for sync history
    autoDelete: true,
    backupBeforeDelete: false,
    exemptions: [],
    nextCleanup: Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)) // Weekly cleanup
  }
];

// Regional insights initial data
export const seedRegionalInsights = [
  {
    region: 'western_canada',
    totalUsers: 156,
    activeUsers: 89,
    dataQuality: 'high' as const,
    lastUpdated: Timestamp.now()
  },
  {
    region: 'central_canada',
    totalUsers: 67,
    activeUsers: 34,
    dataQuality: 'medium' as const,
    lastUpdated: Timestamp.now()
  },
  {
    region: 'eastern_canada',
    totalUsers: 23,
    activeUsers: 12,
    dataQuality: 'low' as const,
    lastUpdated: Timestamp.now()
  },
  {
    region: 'northern_us',
    totalUsers: 234,
    activeUsers: 142,
    dataQuality: 'high' as const,
    lastUpdated: Timestamp.now()
  },
  {
    region: 'midwestern_us',
    totalUsers: 189,
    activeUsers: 98,
    dataQuality: 'high' as const,
    lastUpdated: Timestamp.now()
  }
];