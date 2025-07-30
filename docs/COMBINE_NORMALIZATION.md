# COMBINE_NORMALIZATION.md - Combine Model Matching & Data Standardization

## Last Updated: 2025-01-28

## Overview
The Combine Normalization System standardizes user-entered combine specifications to enable accurate data aggregation and insights. It handles model variants, brand aliases, common typos, and provides confidence scoring for uncertain matches.

## Core Components

### 1. Fuzzy Matching Algorithm

#### Implementation Strategy
Uses Levenshtein distance algorithm with optimizations for combine model patterns:

```typescript
interface FuzzyMatchResult {
  canonical: string;
  confidence: number;        // 0-1 score
  distance: number;          // Edit distance
  matchType: 'exact' | 'variant' | 'fuzzy' | 'brand_alias';
  requiresConfirmation: boolean;
}

class CombineModelMatcher {
  private readonly CONFIDENCE_THRESHOLDS = {
    HIGH: 0.95,     // Exact or known variant
    MEDIUM: 0.8,    // Close fuzzy match
    LOW: 0.6        // Requires confirmation
  };

  async findBestMatch(userInput: string): Promise<FuzzyMatchResult> {
    const normalized = this.normalizeInput(userInput);
    
    // 1. Check exact matches first
    const exactMatch = await this.findExactMatch(normalized);
    if (exactMatch) {
      return {
        canonical: exactMatch,
        confidence: 1.0,
        distance: 0,
        matchType: 'exact',
        requiresConfirmation: false
      };
    }
    
    // 2. Check known variants
    const variantMatch = await this.findVariantMatch(normalized);
    if (variantMatch) {
      return {
        canonical: variantMatch.canonical,
        confidence: 0.98,
        distance: 0,
        matchType: 'variant',
        requiresConfirmation: false
      };
    }
    
    // 3. Fuzzy matching with edit distance
    const fuzzyMatch = await this.findFuzzyMatch(normalized);
    return fuzzyMatch;
  }
  
  private normalizeInput(input: string): string {
    return input
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '') // Remove special chars
      .trim();
  }
  
  private calculateConfidence(distance: number, maxLength: number): number {
    const similarity = 1 - (distance / maxLength);
    return Math.max(0, similarity);
  }
}
```

### 2. Brand Aliases Mapping

#### Standardized Brand Names
```typescript
const BRAND_ALIASES: Record<string, string> = {
  // John Deere variants
  'jd': 'john_deere',
  'johndeere': 'john_deere',
  'john-deere': 'john_deere',
  'deere': 'john_deere',
  
  // Case IH variants
  'caseih': 'case_ih',
  'case-ih': 'case_ih',
  'case ih': 'case_ih',
  'cnh': 'case_ih',
  
  // New Holland variants
  'newholland': 'new_holland',
  'new-holland': 'new_holland',
  'nh': 'new_holland',
  
  // Claas variants
  'class': 'claas',         // Common typo
  'clas': 'claas',
  
  // Massey Ferguson variants
  'mf': 'massey_ferguson',
  'massey': 'massey_ferguson',
  'ferguson': 'massey_ferguson',
  
  // Gleaner variants
  'agco': 'gleaner',
  
  // Fendt variants
  'fent': 'fendt',
  'fendit': 'fendt'
};
```

#### Brand Recognition Algorithm
```typescript
class BrandNormalizer {
  normalizeBrand(input: string): { canonical: string; confidence: number } {
    const normalized = input.toLowerCase().trim();
    
    // Check exact alias match
    if (BRAND_ALIASES[normalized]) {
      return {
        canonical: BRAND_ALIASES[normalized],
        confidence: 1.0
      };
    }
    
    // Fuzzy match against all brand names
    let bestMatch = { canonical: '', confidence: 0 };
    
    for (const [alias, canonical] of Object.entries(BRAND_ALIASES)) {
      const distance = levenshteinDistance(normalized, alias);
      const confidence = 1 - (distance / Math.max(normalized.length, alias.length));
      
      if (confidence > bestMatch.confidence && confidence > 0.7) {
        bestMatch = { canonical, confidence };
      }
    }
    
    return bestMatch.confidence > 0 ? bestMatch : { canonical: normalized, confidence: 0.5 };
  }
}
```

### 3. Model Variants Database

#### Common Model Patterns
```typescript
const MODEL_VARIANTS: Record<string, string[]> = {
  // John Deere X9 Series
  'x9_1100': [
    'x9 1100', 'x91100', 'x9-1100', '1100x9', 
    'x 9 1100', 'x.9.1100', 'john deere x9 1100'
  ],
  'x9_1000': [
    'x9 1000', 'x91000', 'x9-1000', '1000x9',
    'x 9 1000', 'x.9.1000'
  ],
  
  // John Deere S Series
  's790': [
    's 790', 's-790', 'deere s790', 'jd s790',
    '790s', 's.790'
  ],
  's780': [
    's 780', 's-780', 'deere s780', 'jd s780',
    '780s', 's.780'
  ],
  
  // Case IH Axial Flow
  'af_8250': [
    'axial flow 8250', 'af8250', 'af-8250',
    '8250 af', 'axialflow 8250', 'case 8250'
  ],
  'af_9250': [
    'axial flow 9250', 'af9250', 'af-9250',
    '9250 af', 'axialflow 9250', 'case 9250'
  ],
  
  // New Holland CR Series
  'cr_10.90': [
    'cr10.90', 'cr 10.90', 'cr-10.90', 'cr1090',
    'new holland cr10.90', 'nh cr10.90'
  ],
  'cr_9.90': [
    'cr9.90', 'cr 9.90', 'cr-9.90', 'cr990',
    'new holland cr9.90', 'nh cr9.90'
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
```

### 4. Common Typos Database

#### Systematic Typo Patterns
```typescript
interface TypoPattern {
  pattern: RegExp;
  replacement: string;
  description: string;
}

const TYPO_PATTERNS: TypoPattern[] = [
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

class TypoCorrector {
  correctTypos(input: string): string {
    let corrected = input;
    
    for (const pattern of TYPO_PATTERNS) {
      corrected = corrected.replace(pattern.pattern, pattern.replacement);
    }
    
    return corrected.trim();
  }
  
  findPotentialTypos(input: string): string[] {
    const suggestions: string[] = [];
    
    // Check each typo pattern
    for (const pattern of TYPO_PATTERNS) {
      if (pattern.pattern.test(input)) {
        const suggested = input.replace(pattern.pattern, pattern.replacement);
        if (suggested !== input) {
          suggestions.push(suggested);
        }
      }
    }
    
    return suggestions;
  }
}
```

### 5. Confidence Scoring System

#### Multi-Factor Confidence Calculation
```typescript
interface ConfidenceFactors {
  editDistance: number;      // Levenshtein distance
  lengthSimilarity: number;  // Length ratio similarity
  brandMatch: boolean;       // Brand correctly identified
  yearMatch: boolean;        // Year in reasonable range
  contextClues: number;      // Additional context matches
}

class ConfidenceCalculator {
  calculateConfidence(factors: ConfidenceFactors): number {
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
  
  getConfidenceLevel(score: number): 'high' | 'medium' | 'low' {
    if (score >= 0.9) return 'high';
    if (score >= 0.7) return 'medium';
    return 'low';
  }
  
  requiresConfirmation(score: number): boolean {
    return score < 0.8;
  }
}
```

### 6. User Confirmation Flow

#### Confirmation UI States
```typescript
interface ConfirmationRequest {
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
    timestamp: Date;
  };
}

class UserConfirmationFlow {
  async requestConfirmation(request: ConfirmationRequest): Promise<ConfirmationRequest> {
    // Present to user via UI
    const confirmationUI = {
      title: "Confirm Your Combine",
      message: `We found "${request.suggestedMatch.brand} ${request.suggestedMatch.model}" 
                for your entry "${request.originalInput}". Is this correct?`,
      options: [
        {
          text: "Yes, that's correct",
          action: 'accept',
          primary: true
        },
        {
          text: "No, let me correct it",
          action: 'correct',
          primary: false
        },
        {
          text: "Show other suggestions",
          action: 'alternatives',
          primary: false
        }
      ],
      alternatives: request.alternatives.map(alt => ({
        display: `${alt.brand} ${alt.model}`,
        confidence: `${Math.round(alt.confidence * 100)}% match`
      }))
    };
    
    // Wait for user response (implementation depends on UI framework)
    const response = await this.showConfirmationDialog(confirmationUI);
    
    // Process response
    request.userFeedback = {
      accepted: response.action === 'accept',
      correctedBrand: response.correctedBrand,
      correctedModel: response.correctedModel,
      timestamp: new Date()
    };
    
    // Learn from user feedback
    if (!request.userFeedback.accepted && request.userFeedback.correctedBrand) {
      await this.learnFromCorrection(request);
    }
    
    return request;
  }
  
  private async learnFromCorrection(request: ConfirmationRequest): Promise<void> {
    // Add to learning database for future improvements
    const learningEntry = {
      originalInput: request.originalInput,
      incorrectSuggestion: `${request.suggestedMatch.brand} ${request.suggestedMatch.model}`,
      correctAnswer: `${request.userFeedback.correctedBrand} ${request.userFeedback.correctedModel}`,
      timestamp: new Date()
    };
    
    await this.saveLearningEntry(learningEntry);
    
    // Update variant mappings if applicable
    await this.updateVariantMappings(learningEntry);
  }
}
```

## Database Schema

### Core Tables
```sql
-- Combine specifications master table
CREATE TABLE combine_specs (
  id SERIAL PRIMARY KEY,
  brand VARCHAR(50) NOT NULL,
  model VARCHAR(100) NOT NULL,
  model_variants TEXT[], -- Array of known variants
  year_min INTEGER,
  year_max INTEGER,
  moisture_tolerance_min DECIMAL(4,2),
  moisture_tolerance_max DECIMAL(4,2),
  moisture_tolerance_optimal DECIMAL(4,2),
  moisture_confidence VARCHAR(10) DEFAULT 'medium',
  tough_crop_rating INTEGER DEFAULT 5,
  tough_crop_supported TEXT[],
  tough_crop_limitations TEXT[],
  tough_crop_confidence VARCHAR(10) DEFAULT 'medium',
  user_reports INTEGER DEFAULT 0,
  manufacturer_specs BOOLEAN DEFAULT FALSE,
  expert_validation BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(brand, model)
);

-- User combine entries (before normalization)
CREATE TABLE user_combine_entries (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  raw_input TEXT NOT NULL,
  normalized_brand VARCHAR(50),
  normalized_model VARCHAR(100),
  confidence_score DECIMAL(4,3),
  requires_confirmation BOOLEAN DEFAULT FALSE,
  user_confirmed BOOLEAN DEFAULT FALSE,
  user_corrected_brand VARCHAR(50),
  user_corrected_model VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  confirmed_at TIMESTAMP
);

-- Learning database for improving matches
CREATE TABLE normalization_learning (
  id SERIAL PRIMARY KEY,
  original_input TEXT NOT NULL,
  incorrect_suggestion TEXT,
  correct_answer TEXT NOT NULL,
  confidence_score DECIMAL(4,3),
  user_id INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Brand aliases lookup
CREATE TABLE brand_aliases (
  id SERIAL PRIMARY KEY,
  alias VARCHAR(100) NOT NULL,
  canonical_brand VARCHAR(50) NOT NULL,
  confidence DECIMAL(4,3) DEFAULT 1.0,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(alias)
);

-- Model variants lookup
CREATE TABLE model_variants (
  id SERIAL PRIMARY KEY,
  variant VARCHAR(200) NOT NULL,
  canonical_brand VARCHAR(50) NOT NULL,
  canonical_model VARCHAR(100) NOT NULL,
  confidence DECIMAL(4,3) DEFAULT 1.0,
  source VARCHAR(20) DEFAULT 'manual', -- 'manual', 'learned', 'fuzzy'
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(variant, canonical_brand)
);
```

### Indexes for Performance
```sql
-- Optimize fuzzy matching queries
CREATE INDEX idx_combine_specs_brand_model ON combine_specs(brand, model);
CREATE INDEX idx_user_entries_confidence ON user_combine_entries(confidence_score DESC);
CREATE INDEX idx_brand_aliases_lookup ON brand_aliases(alias);
CREATE INDEX idx_model_variants_lookup ON model_variants(variant);

-- Full-text search for fuzzy matching
CREATE INDEX idx_combine_specs_fts ON combine_specs 
  USING gin(to_tsvector('english', brand || ' ' || model));
```

## Performance Considerations

### Caching Strategy
```typescript
class NormalizationCache {
  private cache = new Map<string, FuzzyMatchResult>();
  private readonly TTL = 24 * 60 * 60 * 1000; // 24 hours
  
  getCachedMatch(input: string): FuzzyMatchResult | null {
    const key = this.normalizeKey(input);
    const cached = this.cache.get(key);
    
    if (cached && this.isValid(cached)) {
      return cached;
    }
    
    this.cache.delete(key);
    return null;
  }
  
  setCachedMatch(input: string, result: FuzzyMatchResult): void {
    const key = this.normalizeKey(input);
    result.cachedAt = Date.now();
    this.cache.set(key, result);
  }
  
  private normalizeKey(input: string): string {
    return input.toLowerCase().replace(/[^a-z0-9]/g, '');
  }
  
  private isValid(result: FuzzyMatchResult): boolean {
    return (Date.now() - (result.cachedAt || 0)) < this.TTL;
  }
}
```

### Batch Processing
```typescript
class BatchNormalizer {
  async normalizeBatch(entries: string[]): Promise<FuzzyMatchResult[]> {
    const chunks = this.chunkArray(entries, 100); // Process in batches of 100
    const results: FuzzyMatchResult[] = [];
    
    for (const chunk of chunks) {
      const chunkResults = await Promise.all(
        chunk.map(entry => this.normalizeEntry(entry))
      );
      results.push(...chunkResults);
      
      // Prevent overwhelming the database
      await this.sleep(100);
    }
    
    return results;
  }
  
  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Testing Strategy

### Unit Tests
```typescript
describe('CombineModelMatcher', () => {
  const matcher = new CombineModelMatcher();
  
  test('exact match should return 100% confidence', async () => {
    const result = await matcher.findBestMatch('john_deere x9_1100');
    expect(result.confidence).toBe(1.0);
    expect(result.matchType).toBe('exact');
  });
  
  test('known variant should return high confidence', async () => {
    const result = await matcher.findBestMatch('x9 1100');
    expect(result.confidence).toBeGreaterThan(0.95);
    expect(result.canonical).toBe('x9_1100');
  });
  
  test('typo should be corrected with medium confidence', async () => {
    const result = await matcher.findBestMatch('johndeere x91100');
    expect(result.confidence).toBeGreaterThan(0.8);
    expect(result.canonical).toBe('x9_1100');
  });
  
  test('low confidence match should require confirmation', async () => {
    const result = await matcher.findBestMatch('combine 123');
    expect(result.requiresConfirmation).toBe(true);
  });
});
```

### Integration Tests
```typescript
describe('Full Normalization Pipeline', () => {
  test('end-to-end normalization with user confirmation', async () => {
    const pipeline = new NormalizationPipeline();
    
    const result = await pipeline.normalize({
      userInput: 'JD X9-1100',
      userId: '123',
      requireConfirmation: true
    });
    
    expect(result.normalized.brand).toBe('john_deere');
    expect(result.normalized.model).toBe('x9_1100');
    expect(result.confidence).toBeGreaterThan(0.9);
  });
});
```

## Monitoring & Analytics

### Key Metrics
- **Match Success Rate**: Percentage of inputs successfully normalized
- **Confirmation Rate**: Percentage requiring user confirmation
- **Correction Rate**: Percentage of confirmed matches that were corrected
- **Processing Time**: Average time to normalize an entry
- **Cache Hit Rate**: Percentage of matches served from cache

### Performance Monitoring
```typescript
class NormalizationMonitor {
  trackNormalization(input: string, result: FuzzyMatchResult, processingTimeMs: number) {
    const metrics = {
      timestamp: new Date(),
      inputLength: input.length,
      confidence: result.confidence,
      matchType: result.matchType,
      processingTime: processingTimeMs,
      requiresConfirmation: result.requiresConfirmation
    };
    
    // Send to monitoring service
    this.analyticsService.track('combine_normalization', metrics);
  }
  
  generateDailyReport(): NormalizationReport {
    // Aggregate daily statistics
    return {
      totalNormalizations: this.getTotalCount(),
      averageConfidence: this.getAverageConfidence(),
      confirmationRate: this.getConfirmationRate(),
      topUnmatchedInputs: this.getTopUnmatched(),
      performanceMetrics: this.getPerformanceStats()
    };
  }
}
```

## Future Enhancements

### Machine Learning Integration
- Train models on user correction patterns
- Implement neural network for complex pattern recognition
- Use embeddings for semantic similarity matching

### Advanced Features
- Multi-language support for international markets
- Integration with manufacturer APIs for real-time specs
- Automated learning from agricultural forums and databases
- Image recognition for combine identification from photos

### Scalability Improvements
- Implement distributed caching with Redis
- Add database sharding for large datasets
- Optimize fuzzy matching algorithms with specialized libraries
- Implement real-time learning pipeline