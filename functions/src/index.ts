/**
 * Firebase Cloud Functions for FieldFirst Combine Intelligence System
 * Implements normalization, aggregation, and real-time insights
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { CombineNormalizer } from './services/combineNormalizer';
import { SeedService } from './services/seedService';
import { 
  NormalizeRequest,
  NormalizeResponse,
  ConfirmMatchRequest,
  ConfirmMatchResponse,
  InsightsRequest,
  InsightsResponse,
  CombineSpec,
  UserCombine,
  CombineInsight,
  SyncOperation,
  AuditLog
} from './types/combine.types';

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const combineNormalizer = new CombineNormalizer();
const seedService = new SeedService();

/**
 * Cloud Function: Normalize combine model input
 * Provides fuzzy matching and confidence scoring
 */
exports.normalizeCombineModel = functions.https.onCall(
  async (data: NormalizeRequest, context): Promise<NormalizeResponse> => {
    try {
      // Validate authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated to normalize combine models'
        );
      }

      // Validate input
      if (!data.input || typeof data.input !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Input string is required'
        );
      }

      // Log audit trail
      await logAuditEvent({
        userId: context.auth.uid,
        action: 'normalize_combine_model',
        collection: 'modelNormalization',
        changes: { input: data.input },
        timestamp: admin.firestore.Timestamp.now(),
        complianceLevel: 'required'
      });

      // Perform normalization
      const matches = await combineNormalizer.normalize(data.input, {
        ...data.context,
        userId: context.auth.uid
      });

      if (matches.length === 0) {
        return {
          success: false,
          error: {
            code: 'NORMALIZATION_FAILED',
            message: 'Unable to match combine model',
            details: {
              input: data.input,
              suggestions: [
                'Check spelling of brand and model',
                'Try using just the model number',
                'Contact support if this is a valid model'
              ]
            }
          }
        };
      }

      return {
        success: true,
        data: {
          matches,
          bestMatch: {
            brand: matches[0].canonical.split('_')[0],
            model: matches[0].canonical.split('_').slice(1).join('_'),
            confidence: matches[0].confidence
          }
        }
      };

    } catch (error) {
      console.error('Normalization error:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'Internal error during normalization'
      );
    }
  }
);

/**
 * Cloud Function: Confirm model match and learn from corrections
 */
exports.confirmModelMatch = functions.https.onCall(
  async (data: ConfirmMatchRequest, context): Promise<ConfirmMatchResponse> => {
    try {
      // Validate authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      // Validate input
      if (!data.originalInput || !data.suggestedMatch || !data.userConfirmation) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required confirmation data'
        );
      }

      const userId = context.auth.uid;
      const batch = db.batch();

      // Log the confirmation
      const learningRef = db.collection('normalizationLearning').doc();
      batch.set(learningRef, {
        originalInput: data.originalInput,
        incorrectSuggestion: data.userConfirmation.accepted ? null : 
          `${data.suggestedMatch.brand}_${data.suggestedMatch.model}`,
        correctAnswer: data.userConfirmation.accepted ? 
          `${data.suggestedMatch.brand}_${data.suggestedMatch.model}` :
          `${data.userConfirmation.correctedBrand}_${data.userConfirmation.correctedModel}`,
        confidenceScore: data.userConfirmation.accepted ? 1.0 : 0.0,
        userId,
        improved: !data.userConfirmation.accepted,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now()
      });

      // If user corrected the match, learn from it
      if (!data.userConfirmation.accepted && data.userConfirmation.correctedBrand) {
        await combineNormalizer.learnFromCorrection(
          data.originalInput,
          `${data.suggestedMatch.brand}_${data.suggestedMatch.model}`,
          `${data.userConfirmation.correctedBrand}_${data.userConfirmation.correctedModel}`
        );
      }

      // Audit log
      const auditRef = db.collection('auditLogs').doc();
      batch.set(auditRef, {
        userId,
        action: 'confirm_model_match',
        collection: 'normalizationLearning',
        documentId: learningRef.id,
        changes: {
          originalInput: data.originalInput,
          accepted: data.userConfirmation.accepted,
          corrected: !data.userConfirmation.accepted
        },
        timestamp: admin.firestore.Timestamp.now(),
        complianceLevel: 'required'
      });

      await batch.commit();

      return {
        success: true,
        data: {
          learned: true,
          improvedMatching: !data.userConfirmation.accepted,
          thanksMessage: data.userConfirmation.accepted ?
            "Thank you for confirming the match!" :
            "Thank you for helping improve our combine database!"
        }
      };

    } catch (error) {
      console.error('Confirmation error:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Error processing confirmation'
      );
    }
  }
);

/**
 * Cloud Function: Get regional combine insights with progressive detail
 */
exports.getRegionalInsights = functions.https.onCall(
  async (data: InsightsRequest, context): Promise<InsightsResponse> => {
    try {
      // Validate authentication
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      // Validate required parameters
      if (!data.region) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Region is required'
        );
      }

      const userId = context.auth.uid;

      // Check for cached insights first
      const cacheKey = `insights_${data.region}_${data.level || 'progressive'}_${data.crop || 'all'}`;
      const cachedInsight = await db
        .collection('combineInsights')
        .where('region', '==', data.region)
        .where('generatedAt', '>', admin.firestore.Timestamp.fromMillis(Date.now() - 300000)) // 5 min cache
        .limit(1)
        .get();

      if (!cachedInsight.empty) {
        const insight = cachedInsight.docs[0].data() as CombineInsight;
        return {
          success: true,
          data: insight
        };
      }

      // Generate new insights
      const insight = await generateRegionalInsights(data.region, data.level, data.crop);

      // Cache the insight
      await db.collection('combineInsights').add({
        ...insight,
        generatedAt: admin.firestore.Timestamp.now(),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 300000) // 5 min expiry
      });

      // Log audit event
      await logAuditEvent({
        userId,
        action: 'get_regional_insights',
        collection: 'combineInsights',
        changes: { region: data.region, level: data.level, crop: data.crop },
        timestamp: admin.firestore.Timestamp.now(),
        complianceLevel: 'optional'
      });

      return {
        success: true,
        data: insight
      };

    } catch (error) {
      console.error('Insights error:', error);
      
      if (error.code === 'INSUFFICIENT_DATA') {
        return {
          success: false,
          error: {
            code: 'INSUFFICIENT_DATA',
            message: error.message,
            details: error.details
          }
        };
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'Error generating insights'
      );
    }
  }
);

/**
 * Firestore Trigger: Real-time aggregation when combine specs are added/updated
 */
exports.updateCombineAggregations = functions.firestore
  .document('combineSpecs/{specId}')
  .onWrite(async (change, context) => {
    try {
      const specId = context.params.specId;
      const newData = change.after.exists ? change.after.data() as CombineSpec : null;
      const oldData = change.before.exists ? change.before.data() as CombineSpec : null;

      // Don't process if data hasn't actually changed
      if (newData && oldData && 
          newData.brand === oldData.brand && 
          newData.model === oldData.model &&
          newData.region === oldData.region) {
        return;
      }

      const batch = db.batch();

      // Update regional aggregations
      if (newData?.region) {
        await updateRegionalAggregations(batch, newData.region, newData, oldData);
      }

      // Update brand aggregations
      if (newData?.brand) {
        await updateBrandAggregations(batch, newData.brand, newData, oldData);
      }

      // Update model aggregations
      if (newData?.brand && newData?.model) {
        await updateModelAggregations(batch, newData.brand, newData.model, newData, oldData);
      }

      await batch.commit();

      console.log(`Updated aggregations for combine spec: ${specId}`);

    } catch (error) {
      console.error('Aggregation update error:', error);
    }
  });

/**
 * Scheduled Function: Clean up expired cache and old data
 */
exports.cleanupExpiredData = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM
  .timeZone('America/Regina')
  .onRun(async (context) => {
    const batch = db.batch();
    const now = admin.firestore.Timestamp.now();

    try {
      // Clean expired insights
      const expiredInsights = await db
        .collection('combineInsights')
        .where('expiresAt', '<', now)
        .limit(100)
        .get();

      expiredInsights.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      // Clean old cache entries
      const expiredCache = await db
        .collectionGroup('offlineCache')
        .where('expiresAt', '<', now)
        .limit(100)
        .get();

      expiredCache.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      // Clean old audit logs (keep for 90 days)
      const oldAuditLogs = await db
        .collection('auditLogs')
        .where('timestamp', '<', admin.firestore.Timestamp.fromMillis(Date.now() - 90 * 24 * 60 * 60 * 1000))
        .limit(100)
        .get();

      oldAuditLogs.docs.forEach(doc => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      console.log(`Cleaned up ${expiredInsights.size + expiredCache.size + oldAuditLogs.size} expired documents`);

    } catch (error) {
      console.error('Cleanup error:', error);
    }
  });

/**
 * Cloud Function: Seed database with initial combine data
 * Admin-only function for populating the database
 */
exports.seedDatabase = functions.https.onCall(
  async (data, context) => {
    try {
      // Validate admin authentication
      if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only administrators can seed the database'
        );
      }

      // Check if database is already seeded
      const isSeeded = await seedService.isDatabaseSeeded();
      if (isSeeded && !data.force) {
        return {
          success: false,
          message: 'Database is already seeded. Use force: true to re-seed.',
          seedingStatus: await seedService.getSeedingStatus()
        };
      }

      // Clear existing data if force is true
      if (data.force && isSeeded) {
        const clearResult = await seedService.clearSeedData();
        if (!clearResult.success) {
          throw new functions.https.HttpsError(
            'internal',
            `Failed to clear existing data: ${clearResult.message}`
          );
        }
      }

      // Perform seeding
      const result = await seedService.seedDatabase();

      // Log audit event
      await logAuditEvent({
        userId: context.auth.uid,
        action: 'seed_database',
        collection: 'system',
        changes: { 
          forced: data.force || false,
          result: result.details
        },
        timestamp: admin.firestore.Timestamp.now(),
        complianceLevel: 'system'
      });

      return {
        success: result.success,
        message: result.message,
        details: result.details,
        seedingStatus: await seedService.getSeedingStatus()
      };

    } catch (error) {
      console.error('Database seeding error:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'Internal error during database seeding'
      );
    }
  }
);

/**
 * Cloud Function: Get database seeding status
 * Admin-only function for checking seed status
 */
exports.getSeedingStatus = functions.https.onCall(
  async (data, context) => {
    try {
      // Validate admin authentication
      if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Only administrators can check seeding status'
        );
      }

      const status = await seedService.getSeedingStatus();

      return {
        success: true,
        data: status
      };

    } catch (error) {
      console.error('Error getting seeding status:', error);
      
      throw new functions.https.HttpsError(
        'internal',
        'Error retrieving seeding status'
      );
    }
  }
);

/**
 * Helper function: Generate regional insights with progressive detail
 */
async function generateRegionalInsights(
  region: string, 
  level?: string, 
  crop?: string
): Promise<CombineInsight> {
  // Query all combine specs in the region
  let query = db.collection('combineSpecs')
    .where('region', '==', region)
    .where('isPublic', '==', true);

  if (crop) {
    // This would need a more complex query in practice
    // For now, we'll filter in memory
  }

  const specs = await query.get();
  const totalFarmers = specs.size;

  // Determine insight level based on data volume
  let insightLevel: 'basic' | 'brand' | 'model' = 'basic';
  
  if (totalFarmers >= 15) {
    insightLevel = 'model';
  } else if (totalFarmers >= 5) {
    insightLevel = 'brand';
  }

  // Override with requested level if specified
  if (level && ['basic', 'brand', 'model'].includes(level)) {
    insightLevel = level as 'basic' | 'brand' | 'model';
  }

  const insight: CombineInsight = {
    id: `insight_${region}_${Date.now()}`,
    region,
    level: insightLevel,
    totalFarmers,
    dataPoints: totalFarmers,
    insights: {},
    generatedAt: admin.firestore.Timestamp.now(),
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 300000), // 5 min
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  };

  // Generate insights based on level
  switch (insightLevel) {
    case 'basic':
      insight.insights.basic = await generateBasicInsights(specs.docs);
      break;
    
    case 'brand':
      insight.insights.brand = await generateBrandInsights(specs.docs);
      break;
    
    case 'model':
      insight.insights.model = await generateModelInsights(specs.docs);
      break;
  }

  return insight;
}

/**
 * Helper function: Generate basic insights
 */
async function generateBasicInsights(specs: any[]): Promise<any> {
  const activeSpecs = specs.filter(doc => {
    const data = doc.data();
    return data.sourceData?.userReports > 0;
  });

  const averageMoisture = activeSpecs.reduce((sum, doc) => {
    const data = doc.data();
    return sum + (data.moistureTolerance?.optimal || 15);
  }, 0) / activeSpecs.length || 15;

  return {
    startedHarvest: Math.floor(activeSpecs.length * 0.15), // Simulated
    averageMoisture: Math.round(averageMoisture * 10) / 10,
    weatherConditions: 'favorable', // Would integrate with weather service
    recommendation: 'Monitor moisture levels closely'
  };
}

/**
 * Helper function: Generate brand-specific insights
 */
async function generateBrandInsights(specs: any[]): Promise<any[]> {
  const brandGroups = new Map<string, any[]>();
  
  specs.forEach(doc => {
    const data = doc.data();
    if (!brandGroups.has(data.brand)) {
      brandGroups.set(data.brand, []);
    }
    brandGroups.get(data.brand)!.push(data);
  });

  const insights = [];
  
  for (const [brand, brandSpecs] of brandGroups) {
    if (brandSpecs.length >= 3) { // Minimum threshold for brand insights
      const averageMoisture = brandSpecs.reduce((sum, spec) => 
        sum + (spec.moistureTolerance?.optimal || 15), 0
      ) / brandSpecs.length;

      insights.push({
        brand,
        farmers: brandSpecs.length,
        started: Math.floor(brandSpecs.length * 0.2), // Simulated
        averageMoisture: Math.round(averageMoisture * 10) / 10,
        moistureRange: `${Math.round(averageMoisture - 1.5)}-${Math.round(averageMoisture + 1.5)}`,
        recommendation: `${brand.replace('_', ' ')} combines performing well at current levels`
      });
    }
  }

  return insights;
}

/**
 * Helper function: Generate model-specific insights
 */
async function generateModelInsights(specs: any[]): Promise<any[]> {
  const modelGroups = new Map<string, any[]>();
  
  specs.forEach(doc => {
    const data = doc.data();
    const modelKey = `${data.brand}_${data.model}`;
    if (!modelGroups.has(modelKey)) {
      modelGroups.set(modelKey, []);
    }
    modelGroups.get(modelKey)!.push(data);
  });

  const insights = [];
  
  for (const [modelKey, modelSpecs] of modelGroups) {
    if (modelSpecs.length >= 5) { // Minimum threshold for model insights
      const [brand, model] = modelKey.split('_');
      const averageMoisture = modelSpecs.reduce((sum, spec) => 
        sum + (spec.moistureTolerance?.optimal || 15), 0
      ) / modelSpecs.length;

      const averageToughCrop = modelSpecs.reduce((sum, spec) => 
        sum + (spec.toughCropAbility?.rating || 5), 0
      ) / modelSpecs.length;

      insights.push({
        brand,
        model,
        farmers: modelSpecs.length,
        started: Math.floor(modelSpecs.length * 0.25), // Simulated
        averageMoisture: Math.round(averageMoisture * 10) / 10,
        moistureRange: `${Math.round(averageMoisture - 1.5)}-${Math.round(averageMoisture + 1.5)}`,
        toughCropRating: Math.round(averageToughCrop * 10) / 10,
        recommendations: [
          'Excellent performance in current conditions',
          `Can handle moisture up to ${Math.round(averageMoisture + 2)}% with reduced speed`,
          averageToughCrop > 7 ? 'Superior tough crop handling' : 'Good tough crop performance'
        ],
        peerComparison: {
          betterThan: [], // Would require more complex analysis
          similarTo: [],
          challengedBy: []
        }
      });
    }
  }

  return insights;
}

/**
 * Helper function: Update regional aggregations
 */
async function updateRegionalAggregations(
  batch: FirebaseFirestore.WriteBatch,
  region: string,
  newData: CombineSpec,
  oldData: CombineSpec | null
): Promise<void> {
  const regionalRef = db.collection('regionalInsights').doc(region);
  
  const increment = admin.firestore.FieldValue.increment(1);
  const decrement = admin.firestore.FieldValue.increment(-1);
  
  // Update user count
  if (newData && !oldData) {
    batch.set(regionalRef, {
      region,
      totalUsers: increment,
      lastUpdated: admin.firestore.Timestamp.now()
    }, { merge: true });
  } else if (!newData && oldData) {
    batch.update(regionalRef, {
      totalUsers: decrement,
      lastUpdated: admin.firestore.Timestamp.now()
    });
  }
}

/**
 * Helper function: Update brand aggregations
 */
async function updateBrandAggregations(
  batch: FirebaseFirestore.WriteBatch,
  brand: string,
  newData: CombineSpec,
  oldData: CombineSpec | null
): Promise<void> {
  // Implementation would track brand-specific statistics
  console.log(`Updating brand aggregations for: ${brand}`);
}

/**
 * Helper function: Update model aggregations
 */
async function updateModelAggregations(
  batch: FirebaseFirestore.WriteBatch,
  brand: string,
  model: string,
  newData: CombineSpec,
  oldData: CombineSpec | null
): Promise<void> {
  // Implementation would track model-specific statistics
  console.log(`Updating model aggregations for: ${brand} ${model}`);
}

/**
 * Helper function: Log audit events for PIPEDA compliance
 */
async function logAuditEvent(event: Omit<AuditLog, 'id' | 'createdAt' | 'updatedAt'>): Promise<void> {
  await db.collection('auditLogs').add({
    ...event,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  });
}