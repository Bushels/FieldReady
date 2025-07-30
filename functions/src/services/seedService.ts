/**
 * Service for seeding the Firestore database with initial combine specifications
 * and normalization data for the FieldFirst system
 */

import * as admin from 'firebase-admin';
import { 
  seedCombineSpecs, 
  seedBrandAliases, 
  seedModelVariants, 
  seedNormalizationRules,
  seedDataRetentionPolicies,
  seedRegionalInsights
} from '../data/seedData';
import { Timestamp } from 'firebase-admin/firestore';

interface SeedResult {
  success: boolean;
  message: string;
  details: {
    combineSpecs: number;
    brandAliases: number;
    modelVariants: number;
    normalizationRules: number;
    dataRetentionPolicies: number;
    regionalInsights: number;
    errors: string[];
  };
}

export class SeedService {
  private db: FirebaseFirestore.Firestore;

  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Seed the entire database with initial data
   */
  async seedDatabase(): Promise<SeedResult> {
    const result: SeedResult = {
      success: false,
      message: 'Database seeding in progress...',
      details: {
        combineSpecs: 0,
        brandAliases: 0,
        modelVariants: 0,
        normalizationRules: 0,
        dataRetentionPolicies: 0,
        regionalInsights: 0,
        errors: []
      }
    };

    try {
      console.log('Starting database seeding process...');

      // Seed combine specifications
      const combineSpecsResult = await this.seedCombineSpecs();
      result.details.combineSpecs = combineSpecsResult.count;
      if (combineSpecsResult.errors.length > 0) {
        result.details.errors.push(...combineSpecsResult.errors);
      }

      // Seed brand aliases
      const brandAliasesResult = await this.seedBrandAliases();
      result.details.brandAliases = brandAliasesResult.count;
      if (brandAliasesResult.errors.length > 0) {
        result.details.errors.push(...brandAliasesResult.errors);
      }

      // Seed model variants
      const modelVariantsResult = await this.seedModelVariants();
      result.details.modelVariants = modelVariantsResult.count;
      if (modelVariantsResult.errors.length > 0) {
        result.details.errors.push(...modelVariantsResult.errors);
      }

      // Seed normalization rules
      const normalizationRulesResult = await this.seedNormalizationRules();
      result.details.normalizationRules = normalizationRulesResult.count;
      if (normalizationRulesResult.errors.length > 0) {
        result.details.errors.push(...normalizationRulesResult.errors);
      }

      // Seed data retention policies
      const dataRetentionResult = await this.seedDataRetentionPolicies();
      result.details.dataRetentionPolicies = dataRetentionResult.count;
      if (dataRetentionResult.errors.length > 0) {
        result.details.errors.push(...dataRetentionResult.errors);
      }

      // Seed regional insights
      const regionalInsightsResult = await this.seedRegionalInsights();
      result.details.regionalInsights = regionalInsightsResult.count;
      if (regionalInsightsResult.errors.length > 0) {
        result.details.errors.push(...regionalInsightsResult.errors);
      }

      // Update result
      const totalSeeded = result.details.combineSpecs + 
                         result.details.brandAliases + 
                         result.details.modelVariants + 
                         result.details.normalizationRules +
                         result.details.dataRetentionPolicies +
                         result.details.regionalInsights;

      if (result.details.errors.length === 0) {
        result.success = true;
        result.message = `Successfully seeded database with ${totalSeeded} documents`;
      } else {
        result.success = false;
        result.message = `Seeded ${totalSeeded} documents with ${result.details.errors.length} errors`;
      }

      console.log('Database seeding completed:', result);
      return result;

    } catch (error) {
      console.error('Fatal error during database seeding:', error);
      result.success = false;
      result.message = `Fatal error during seeding: ${error.message}`;
      result.details.errors.push(`Fatal error: ${error.message}`);
      return result;
    }
  }

  /**
   * Seed combine specifications
   */
  private async seedCombineSpecs(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding combine specifications...');

    for (const spec of seedCombineSpecs) {
      try {
        const docRef = this.db.collection('combineSpecs').doc();
        await docRef.set({
          ...spec,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed combine spec ${spec.brand}_${spec.model}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} combine specifications`);
    return { count, errors };
  }

  /**
   * Seed brand aliases
   */
  private async seedBrandAliases(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding brand aliases...');

    for (const alias of seedBrandAliases) {
      try {
        const docRef = this.db.collection('brandAliases').doc();
        await docRef.set({
          ...alias,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed brand alias ${alias.alias}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} brand aliases`);
    return { count, errors };
  }

  /**
   * Seed model variants
   */
  private async seedModelVariants(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding model variants...');

    for (const variant of seedModelVariants) {
      try {
        const docRef = this.db.collection('modelVariants').doc();
        await docRef.set({
          ...variant,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed model variant ${variant.variant}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} model variants`);
    return { count, errors };
  }

  /**
   * Seed normalization rules
   */
  private async seedNormalizationRules(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding normalization rules...');

    for (const rule of seedNormalizationRules) {
      try {
        const docRef = this.db.collection('modelNormalization').doc();
        await docRef.set({
          ...rule,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed normalization rule ${rule.pattern}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} normalization rules`);
    return { count, errors };
  }

  /**
   * Seed data retention policies
   */
  private async seedDataRetentionPolicies(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding data retention policies...');

    for (const policy of seedDataRetentionPolicies) {
      try {
        const docRef = this.db.collection('dataRetentionPolicies').doc();
        await docRef.set({
          ...policy,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed retention policy for ${policy.collection}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} data retention policies`);
    return { count, errors };
  }

  /**
   * Seed regional insights
   */
  private async seedRegionalInsights(): Promise<{ count: number; errors: string[] }> {
    const errors: string[] = [];
    let count = 0;

    console.log('Seeding regional insights...');

    for (const insight of seedRegionalInsights) {
      try {
        const docRef = this.db.collection('regionalInsights').doc();
        await docRef.set({
          ...insight,
          id: docRef.id,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now()
        });
        count++;
      } catch (error) {
        const errorMsg = `Failed to seed regional insight for ${insight.region}: ${error.message}`;
        console.error(errorMsg);
        errors.push(errorMsg);
      }
    }

    console.log(`Seeded ${count} regional insights`);
    return { count, errors };
  }

  /**
   * Check if database is already seeded
   */
  async isDatabaseSeeded(): Promise<boolean> {
    try {
      const combineSpecsSnapshot = await this.db.collection('combineSpecs').limit(1).get();
      const brandAliasesSnapshot = await this.db.collection('brandAliases').limit(1).get();
      
      return !combineSpecsSnapshot.empty && !brandAliasesSnapshot.empty;
    } catch (error) {
      console.error('Error checking if database is seeded:', error);
      return false;
    }
  }

  /**
   * Clear all seeded data (use with caution)
   */
  async clearSeedData(): Promise<{ success: boolean; message: string }> {
    try {
      console.log('Clearing seed data...');

      const collections = [
        'combineSpecs',
        'brandAliases', 
        'modelVariants',
        'modelNormalization',
        'dataRetentionPolicies',
        'regionalInsights'
      ];

      const batch = this.db.batch();
      let totalDeleted = 0;

      for (const collectionName of collections) {
        const snapshot = await this.db.collection(collectionName)
          .where('userId', '==', 'system')
          .get();
        
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
          totalDeleted++;
        });
      }

      await batch.commit();

      console.log(`Cleared ${totalDeleted} seed documents`);
      return {
        success: true,
        message: `Successfully cleared ${totalDeleted} seed documents`
      };

    } catch (error) {
      console.error('Error clearing seed data:', error);
      return {
        success: false,
        message: `Error clearing seed data: ${error.message}`
      };
    }
  }

  /**
   * Get seeding status
   */
  async getSeedingStatus(): Promise<{
    isSeeded: boolean;
    counts: Record<string, number>;
    lastSeeded?: Date;
  }> {
    try {
      const collections = [
        'combineSpecs',
        'brandAliases',
        'modelVariants', 
        'modelNormalization',
        'dataRetentionPolicies',
        'regionalInsights'
      ];

      const counts: Record<string, number> = {};
      let totalCount = 0;

      for (const collection of collections) {
        const snapshot = await this.db.collection(collection).get();
        counts[collection] = snapshot.size;
        totalCount += snapshot.size;
      }

      // Check for system-created documents to estimate last seeded date
      let lastSeeded: Date | undefined;
      if (totalCount > 0) {
        const systemDocs = await this.db.collection('combineSpecs')
          .where('userId', '==', 'system')
          .orderBy('createdAt', 'desc')
          .limit(1)
          .get();
        
        if (!systemDocs.empty) {
          lastSeeded = systemDocs.docs[0].data().createdAt.toDate();
        }
      }

      return {
        isSeeded: totalCount > 0,
        counts,
        lastSeeded
      };

    } catch (error) {
      console.error('Error getting seeding status:', error);
      return {
        isSeeded: false,
        counts: {}
      };
    }
  }
}