/**
 * Combine Model Normalizer Service
 * Implements fuzzy matching with Levenshtein distance for combine model standardization
 * Includes brand aliases, confidence scoring, and user confirmation flow
 */

import { 
  FuzzyMatchResult, 
  MatchType, 
  BrandAlias, 
  ModelVariant,
  NormalizationError,
  ConfidenceLevel
} from '../types/combine.types';

interface ConfidenceFactors {
  editDistance: number;
  lengthSimilarity: number;
  brandMatch: boolean;
  yearMatch: boolean;
  contextClues: number;
}

interface TypoPattern {
  pattern: RegExp;
  replacement: string;
  description: string;
}

export class CombineNormalizer {
  private readonly CONFIDENCE_THRESHOLDS = {
    HIGH: 0.95,     // Exact or known variant
    MEDIUM: 0.8,    // Close fuzzy match
    LOW: 0.6        // Requires confirmation
  };

  private readonly BRAND_ALIASES: Record<string, string> = {
    // John Deere variants
    'jd': 'john_deere',
    'johndeere': 'john_deere',
    'john-deere': 'john_deere',
    'deere': 'john_deere',
    'john deer': 'john_deere',
    
    // Case IH variants
    'caseih': 'case_ih',
    'case-ih': 'case_ih',
    'case ih': 'case_ih',
    'cnh': 'case_ih',
    'case': 'case_ih',
    
    // New Holland variants
    'newholland': 'new_holland',
    'new-holland': 'new_holland',
    'nh': 'new_holland',
    'new holland': 'new_holland',
    
    // Claas variants
    'class': 'claas',         // Common typo
    'clas': 'claas',
    'klaus': 'claas',
    
    // Massey Ferguson variants
    'mf': 'massey_ferguson',
    'massey': 'massey_ferguson',
    'ferguson': 'massey_ferguson',
    'massey ferguson': 'massey_ferguson',
    
    // Gleaner variants
    'agco': 'gleaner',
    
    // Fendt variants
    'fent': 'fendt',
    'fendit': 'fendt'
  };

  private readonly MODEL_VARIANTS: Record<string, string[]> = {
    // John Deere X9 Series
    'x9_1100': [
      'x9 1100', 'x91100', 'x9-1100', '1100x9', 
      'x 9 1100', 'x.9.1100', 'john deere x9 1100', 'jd x9 1100'
    ],
    'x9_1000': [
      'x9 1000', 'x91000', 'x9-1000', '1000x9',
      'x 9 1000', 'x.9.1000', 'john deere x9 1000', 'jd x9 1000'
    ],
    
    // John Deere S Series
    's790': [
      's 790', 's-790', 'deere s790', 'jd s790',
      '790s', 's.790', 'john deere s790'
    ],
    's780': [
      's 780', 's-780', 'deere s780', 'jd s780',
      '780s', 's.780', 'john deere s780'
    ],
    
    // Case IH Axial Flow
    'af_8250': [
      'axial flow 8250', 'af8250', 'af-8250',
      '8250 af', 'axialflow 8250', 'case 8250', 'case ih 8250'
    ],
    'af_9250': [
      'axial flow 9250', 'af9250', 'af-9250',
      '9250 af', 'axialflow 9250', 'case 9250', 'case ih 9250'
    ],
    
    // New Holland CR Series
    'cr_10.90': [
      'cr10.90', 'cr 10.90', 'cr-10.90', 'cr1090',
      'new holland cr10.90', 'nh cr10.90', 'cr 1090'
    ],
    'cr_9.90': [
      'cr9.90', 'cr 9.90', 'cr-9.90', 'cr990',
      'new holland cr9.90', 'nh cr9.90', 'cr 990'
    ],
    
    // Claas Lexion Series
    'lexion_8900': [
      'lexion 8900', 'lex8900', 'lex-8900',
      '8900 lexion', 'claas 8900', 'claas lexion8900'
    ],
    'lexion_8800': [
      'lexion 8800', 'lex8800', 'lex-8800',
      '8800 lexion', 'claas 8800', 'claas lexion8800'
    ]
  };

  private readonly TYPO_PATTERNS: TypoPattern[] = [
    // Number/letter confusion
    { 
      pattern: /(\d)o(\d)/gi, 
      replacement: '$10$2', 
      description: 'O instead of 0 in model numbers' 
    },
    { 
      pattern: /(\d)l(\d)/gi, 
      replacement: '$11$2', 
      description: 'L instead of 1 in model numbers' 
    },
    
    // Double letters
    { 
      pattern: /([a-z])\1{2,}/gi, 
      replacement: '$1$1', 
      description: 'Remove excessive repeated letters' 
    },
    
    // Missing spaces
    { 
      pattern: /([a-z])(\d)/gi, 
      replacement: '$1 $2', 
      description: 'Add space between letters and numbers' 
    },
    
    // Common brand misspellings
    { 
      pattern: /john?deer?e?/gi, 
      replacement: 'john deere', 
      description: 'John Deere spelling variations' 
    },
    { 
      pattern: /case?ih/gi, 
      replacement: 'case ih', 
      description: 'Case IH spacing' 
    },
    
    // Model number patterns
    { 
      pattern: /x(\d+)/gi, 
      replacement: 'x$1', 
      description: 'Standardize X-series format' 
    },
    { 
      pattern: /s(\d+)/gi, 
      replacement: 's$1', 
      description: 'Standardize S-series format' 
    }
  ];

  private cache = new Map<string, FuzzyMatchResult>();
  private readonly TTL = 24 * 60 * 60 * 1000; // 24 hours

  /**
   * Main normalization entry point
   */
  async normalize(
    userInput: string, 
    context?: { year?: number; userId?: string; region?: string }
  ): Promise<FuzzyMatchResult[]> {
    const cacheKey = this.getCacheKey(userInput);
    const cached = this.getCachedMatch(cacheKey);
    
    if (cached) {
      return [cached];
    }

    try {
      const normalized = this.normalizeInput(userInput);
      const corrected = this.correctTypos(normalized);
      
      // 1. Check exact matches first
      const exactMatch = await this.findExactMatch(corrected);
      if (exactMatch) {
        const result = {
          canonical: exactMatch,
          confidence: 1.0,
          distance: 0,
          matchType: 'exact' as MatchType,
          requiresConfirmation: false
        };
        this.setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 2. Check known variants
      const variantMatch = await this.findVariantMatch(corrected);
      if (variantMatch) {
        const result = {
          canonical: variantMatch.canonical,
          confidence: 0.98,
          distance: 0,
          matchType: 'variant' as MatchType,
          requiresConfirmation: false
        };
        this.setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 3. Brand alias matching
      const brandMatch = await this.findBrandAliasMatch(corrected);
      if (brandMatch) {
        const result = {
          canonical: brandMatch.canonical,
          confidence: brandMatch.confidence,
          distance: 0,
          matchType: 'brand_alias' as MatchType,
          requiresConfirmation: brandMatch.confidence < this.CONFIDENCE_THRESHOLDS.MEDIUM
        };
        this.setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 4. Fuzzy matching with edit distance
      const fuzzyMatches = await this.findFuzzyMatches(corrected, context);
      
      if (fuzzyMatches.length > 0) {
        this.setCachedMatch(cacheKey, fuzzyMatches[0]);
      }
      
      return fuzzyMatches;
      
    } catch (error) {
      throw new NormalizationError(
        `Failed to normalize combine input: ${error.message}`,
        userInput,
        ['Check spelling of brand and model', 'Try using just the model number']
      );
    }
  }

  /**
   * Find the top 3 best matches for user confirmation
   */
  async findBestMatches(userInput: string, limit: number = 3): Promise<FuzzyMatchResult[]> {
    const matches = await this.normalize(userInput);
    return matches.slice(0, limit);
  }

  /**
   * Normalize input string for consistent matching
   */
  private normalizeInput(input: string): string {
    return input
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, '') // Remove special chars but keep spaces
      .replace(/\s+/g, ' ') // Normalize whitespace
      .trim();
  }

  /**
   * Apply typo correction patterns
   */
  private correctTypos(input: string): string {
    let corrected = input;
    
    for (const pattern of this.TYPO_PATTERNS) {
      corrected = corrected.replace(pattern.pattern, pattern.replacement);
    }
    
    return corrected.trim();
  }

  /**
   * Check for exact matches in canonical names
   */
  private async findExactMatch(normalized: string): Promise<string | null> {
    const canonical = this.toCanonicalFormat(normalized);
    
    // Check against known canonical models
    const allModels = Object.keys(this.MODEL_VARIANTS);
    if (allModels.includes(canonical)) {
      return canonical;
    }
    
    return null;
  }

  /**
   * Check known model variants
   */
  private async findVariantMatch(normalized: string): Promise<{ canonical: string } | null> {
    for (const [canonical, variants] of Object.entries(this.MODEL_VARIANTS)) {
      for (const variant of variants) {
        if (this.normalizeInput(variant) === normalized) {
          return { canonical };
        }
      }
    }
    
    return null;
  }

  /**
   * Check brand aliases
   */
  private async findBrandAliasMatch(
    normalized: string
  ): Promise<{ canonical: string; confidence: number } | null> {
    const words = normalized.split(' ');
    const brandWord = words[0];
    
    if (this.BRAND_ALIASES[brandWord]) {
      const canonicalBrand = this.BRAND_ALIASES[brandWord];
      const modelPart = words.slice(1).join(' ');
      
      if (modelPart) {
        const canonical = `${canonicalBrand}_${modelPart.replace(/\s+/g, '_')}`;
        return {
          canonical,
          confidence: 0.9
        };
      }
    }
    
    return null;
  }

  /**
   * Fuzzy matching using Levenshtein distance
   */
  private async findFuzzyMatches(
    normalized: string,
    context?: { year?: number; userId?: string; region?: string }
  ): Promise<FuzzyMatchResult[]> {
    const allCandidates = this.getAllCandidates();
    const matches: Array<FuzzyMatchResult & { score: number }> = [];
    
    for (const candidate of allCandidates) {
      const distance = this.levenshteinDistance(normalized, candidate);
      const maxLength = Math.max(normalized.length, candidate.length);
      
      if (maxLength === 0) continue;
      
      const similarity = 1 - (distance / maxLength);
      
      if (similarity >= this.CONFIDENCE_THRESHOLDS.LOW) {
        const confidence = this.calculateConfidence({
          editDistance: distance,
          lengthSimilarity: similarity,
          brandMatch: this.hasBrandMatch(normalized, candidate),
          yearMatch: context?.year ? this.hasYearMatch(candidate, context.year) : true,
          contextClues: this.countContextClues(normalized, candidate)
        });
        
        matches.push({
          canonical: candidate,
          confidence,
          distance,
          matchType: 'fuzzy' as MatchType,
          requiresConfirmation: confidence < this.CONFIDENCE_THRESHOLDS.MEDIUM,
          score: confidence
        });
      }
    }
    
    // Sort by confidence score and return top matches
    matches.sort((a, b) => b.score - a.score);
    
    return matches.slice(0, 3).map(match => ({
      canonical: match.canonical,
      confidence: match.confidence,
      distance: match.distance,
      matchType: match.matchType,
      requiresConfirmation: match.requiresConfirmation,
      alternativeMatches: matches.slice(1, 3).map(alt => ({
        canonical: alt.canonical,
        confidence: alt.confidence,
        matchType: alt.matchType
      }))
    }));
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const matrix = Array(str2.length + 1).fill(null).map(() => 
      Array(str1.length + 1).fill(null)
    );
    
    for (let i = 0; i <= str1.length; i++) {
      matrix[0][i] = i;
    }
    
    for (let j = 0; j <= str2.length; j++) {
      matrix[j][0] = j;
    }
    
    for (let j = 1; j <= str2.length; j++) {
      for (let i = 1; i <= str1.length; i++) {
        const indicator = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[j][i] = Math.min(
          matrix[j][i - 1] + 1, // deletion
          matrix[j - 1][i] + 1, // insertion
          matrix[j - 1][i - 1] + indicator // substitution
        );
      }
    }
    
    return matrix[str2.length][str1.length];
  }

  /**
   * Calculate confidence score based on multiple factors
   */
  private calculateConfidence(factors: ConfidenceFactors): number {
    const weights = {
      editDistance: 0.4,
      lengthSimilarity: 0.2,
      brandMatch: 0.2,
      yearMatch: 0.1,
      contextClues: 0.1
    };
    
    // Edit distance score (inverted - lower distance = higher confidence)
    const maxDistance = Math.max(factors.editDistance, 10);
    const distanceScore = 1 - (factors.editDistance / maxDistance);
    
    // Length similarity score
    const lengthScore = factors.lengthSimilarity;
    
    // Boolean factors
    const brandScore = factors.brandMatch ? 1 : 0;
    const yearScore = factors.yearMatch ? 1 : 0;
    const contextScore = Math.min(factors.contextClues / 3, 1); // Normalize to 0-1
    
    const totalScore = (
      distanceScore * weights.editDistance +
      lengthScore * weights.lengthSimilarity +
      brandScore * weights.brandMatch +
      yearScore * weights.yearMatch +
      contextScore * weights.contextClues
    );
    
    return Math.min(Math.max(totalScore, 0), 1);
  }

  /**
   * Check if brand names match
   */
  private hasBrandMatch(input: string, candidate: string): boolean {
    const inputBrand = input.split('_')[0] || input.split(' ')[0];
    const candidateBrand = candidate.split('_')[0] || candidate.split(' ')[0];
    
    return inputBrand === candidateBrand || 
           this.BRAND_ALIASES[inputBrand] === candidateBrand;
  }

  /**
   * Check if year is in reasonable range for model
   */
  private hasYearMatch(candidate: string, year: number): boolean {
    // Basic year validation - most combines are from 1990-2025
    return year >= 1990 && year <= new Date().getFullYear() + 1;
  }

  /**
   * Count contextual clues that support the match
   */
  private countContextClues(input: string, candidate: string): number {
    let clues = 0;
    
    // Check for series indicators (X9, S7, etc.)
    const inputSeries = input.match(/[a-z]\d+/gi);
    const candidateSeries = candidate.match(/[a-z]\d+/gi);
    
    if (inputSeries && candidateSeries) {
      for (const series of inputSeries) {
        if (candidateSeries.some(cs => cs.toLowerCase() === series.toLowerCase())) {
          clues++;
        }
      }
    }
    
    // Check for numeric matches
    const inputNumbers = input.match(/\d+/g);
    const candidateNumbers = candidate.match(/\d+/g);
    
    if (inputNumbers && candidateNumbers) {
      for (const num of inputNumbers) {
        if (candidateNumbers.includes(num)) {
          clues++;
        }
      }
    }
    
    return clues;
  }

  /**
   * Get all candidate models for fuzzy matching
   */
  private getAllCandidates(): string[] {
    const candidates = new Set<string>();
    
    // Add canonical models
    Object.keys(this.MODEL_VARIANTS).forEach(model => candidates.add(model));
    
    // Add common variants
    Object.values(this.MODEL_VARIANTS).forEach(variants => {
      variants.forEach(variant => candidates.add(this.toCanonicalFormat(variant)));
    });
    
    return Array.from(candidates);
  }

  /**
   * Convert to canonical format
   */
  private toCanonicalFormat(input: string): string {
    return input
      .toLowerCase()
      .replace(/\s+/g, '_')
      .replace(/[^a-z0-9_]/g, '');
  }

  /**
   * Cache management
   */
  private getCacheKey(input: string): string {
    return `normalize_${this.normalizeInput(input)}`;
  }

  private getCachedMatch(key: string): FuzzyMatchResult | null {
    const cached = this.cache.get(key);
    
    if (cached && this.isValid(cached)) {
      return cached;
    }
    
    this.cache.delete(key);
    return null;
  }

  private setCachedMatch(key: string, result: FuzzyMatchResult): void {
    result.cachedAt = Date.now();
    this.cache.set(key, result);
  }

  private isValid(result: FuzzyMatchResult): boolean {
    return (Date.now() - (result.cachedAt || 0)) < this.TTL;
  }

  /**
   * Get confidence level description
   */
  getConfidenceLevel(score: number): ConfidenceLevel {
    if (score >= this.CONFIDENCE_THRESHOLDS.HIGH) return 'high';
    if (score >= this.CONFIDENCE_THRESHOLDS.MEDIUM) return 'medium';
    return 'low';
  }

  /**
   * Check if user confirmation is required
   */
  requiresConfirmation(score: number): boolean {
    return score < this.CONFIDENCE_THRESHOLDS.MEDIUM;
  }

  /**
   * Learn from user corrections to improve future matching
   */
  async learnFromCorrection(
    originalInput: string,
    incorrectSuggestion: string,
    correctAnswer: string
  ): Promise<void> {
    // In a real implementation, this would update the database
    // with the learning data to improve future matches
    console.log(`Learning: "${originalInput}" -> "${correctAnswer}" (not "${incorrectSuggestion}")`);
  }
}