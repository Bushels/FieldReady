/**
 * Combine Normalizer Service for Flutter/Dart
 * Implements fuzzy matching using Levenshtein distance for combine model standardization
 * Includes brand aliases, confidence scoring, and top 3 matches for user confirmation
 */

import 'dart:math';
import '../models/combine_models.dart';

class CombineNormalizer {
  static const Map<String, double> _confidenceThresholds = {
    'high': 0.95,
    'medium': 0.8,
    'low': 0.6,
  };

  static const Map<String, String> _brandAliases = {
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
    'class': 'claas', // Common typo
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
    'fendit': 'fendt',
  };

  static const Map<String, List<String>> _modelVariants = {
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
    's770': [
      's 770', 's-770', 'deere s770', 'jd s770',
      '770s', 's.770', 'john deere s770'
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
    'af_7250': [
      'axial flow 7250', 'af7250', 'af-7250',
      '7250 af', 'axialflow 7250', 'case 7250', 'case ih 7250'
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
    'cr_8.90': [
      'cr8.90', 'cr 8.90', 'cr-8.90', 'cr890',
      'new holland cr8.90', 'nh cr8.90', 'cr 890'
    ],
    
    // Claas Lexion Series
    'lexion_8900': [
      'lexion 8900', 'lex8900', 'lex-8900',
      '8900 lexion', 'claas 8900', 'claas lexion8900'
    ],
    'lexion_8800': [
      'lexion 8800', 'lex8800', 'lex-8800',
      '8800 lexion', 'claas 8800', 'claas lexion8800'
    ],
    'lexion_8700': [
      'lexion 8700', 'lex8700', 'lex-8700',
      '8700 lexion', 'claas 8700', 'claas lexion8700'
    ],
    
    // Massey Ferguson
    'mf_9545': [
      'mf 9545', 'mf9545', 'mf-9545', 'massey 9545',
      'massey ferguson 9545', 'ferguson 9545'
    ],
    'mf_9565': [
      'mf 9565', 'mf9565', 'mf-9565', 'massey 9565',
      'massey ferguson 9565', 'ferguson 9565'
    ],
  };

  static const List<TypoPattern> _typoPatterns = [
    TypoPattern(
      pattern: r'(\d)o(\d)',
      replacement: r'$10$2',
      description: 'O instead of 0 in model numbers',
    ),
    TypoPattern(
      pattern: r'(\d)l(\d)',
      replacement: r'$11$2',
      description: 'L instead of 1 in model numbers',
    ),
    TypoPattern(
      pattern: r'([a-z])\1{2,}',
      replacement: r'$1$1',
      description: 'Remove excessive repeated letters',
    ),
    TypoPattern(
      pattern: r'([a-z])(\d)',
      replacement: r'$1 $2',
      description: 'Add space between letters and numbers',
    ),
    TypoPattern(
      pattern: r'john?deer?e?',
      replacement: 'john deere',
      description: 'John Deere spelling variations',
    ),
    TypoPattern(
      pattern: r'case?ih',
      replacement: 'case ih',
      description: 'Case IH spacing',
    ),
    TypoPattern(
      pattern: r'x(\d+)',
      replacement: 'x\$1',
      description: 'Standardize X-series format',
    ),
    TypoPattern(
      pattern: r's(\d+)',
      replacement: 's\$1',
      description: 'Standardize S-series format',
    ),
  ];

  final Map<String, FuzzyMatchResult> _cache = {};
  static const int _cacheTimeout = 24 * 60 * 60 * 1000; // 24 hours

  /// Main normalization entry point
  /// Returns top 3 matches for user confirmation
  Future<List<FuzzyMatchResult>> normalize(
    String userInput, {
    int? year,
    String? userId,
    String? region,
    int maxResults = 3,
  }) async {
    final cacheKey = _getCacheKey(userInput);
    final cached = _getCachedMatch(cacheKey);
    
    if (cached != null) {
      return [cached];
    }

    try {
      final normalized = _normalizeInput(userInput);
      final corrected = _correctTypos(normalized);
      
      // 1. Check exact matches first
      final exactMatch = await _findExactMatch(corrected);
      if (exactMatch != null) {
        final result = FuzzyMatchResult(
          canonical: exactMatch,
          confidence: 1.0,
          distance: 0,
          matchType: MatchType.exact,
          requiresConfirmation: false,
        );
        _setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 2. Check known variants
      final variantMatch = await _findVariantMatch(corrected);
      if (variantMatch != null) {
        final result = FuzzyMatchResult(
          canonical: variantMatch,
          confidence: 0.98,
          distance: 0,
          matchType: MatchType.variant,
          requiresConfirmation: false,
        );
        _setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 3. Brand alias matching
      final brandMatch = await _findBrandAliasMatch(corrected);
      if (brandMatch != null) {
        final result = FuzzyMatchResult(
          canonical: brandMatch.canonical,
          confidence: brandMatch.confidence,
          distance: 0,
          matchType: MatchType.brandAlias,
          requiresConfirmation: brandMatch.confidence < _confidenceThresholds['medium']!,
        );
        _setCachedMatch(cacheKey, result);
        return [result];
      }
      
      // 4. Fuzzy matching with edit distance
      final fuzzyMatches = await _findFuzzyMatches(
        corrected,
        year: year,
        userId: userId,
        region: region,
        maxResults: maxResults,
      );
      
      if (fuzzyMatches.isNotEmpty) {
        _setCachedMatch(cacheKey, fuzzyMatches.first);
      }
      
      return fuzzyMatches;
      
    } catch (e) {
      throw NormalizationException(
        'Failed to normalize combine input: ${e.toString()}',
        userInput,
        [
          'Check spelling of brand and model',
          'Try using just the model number',
          'Contact support if this is a valid model'
        ],
      );
    }
  }

  /// Get confidence level description
  ConfidenceLevel getConfidenceLevel(double score) {
    if (score >= _confidenceThresholds['high']!) return ConfidenceLevel.high;
    if (score >= _confidenceThresholds['medium']!) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Check if user confirmation is required
  bool requiresConfirmation(double score) {
    return score < _confidenceThresholds['medium']!;
  }

  /// Normalize input string for consistent matching
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special chars but keep spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Apply typo correction patterns
  String _correctTypos(String input) {
    String corrected = input;
    
    for (final pattern in _typoPatterns) {
      corrected = corrected.replaceAll(
        RegExp(pattern.pattern, caseSensitive: false),
        pattern.replacement,
      );
    }
    
    return corrected.trim();
  }

  /// Check for exact matches in canonical names
  Future<String?> _findExactMatch(String normalized) async {
    final canonical = _toCanonicalFormat(normalized);
    
    // Check against known canonical models
    if (_modelVariants.containsKey(canonical)) {
      return canonical;
    }
    
    return null;
  }

  /// Check known model variants
  Future<String?> _findVariantMatch(String normalized) async {
    for (final entry in _modelVariants.entries) {
      final canonical = entry.key;
      final variants = entry.value;
      
      for (final variant in variants) {
        if (_normalizeInput(variant) == normalized) {
          return canonical;
        }
      }
    }
    
    return null;
  }

  /// Check brand aliases
  Future<BrandMatchResult?> _findBrandAliasMatch(String normalized) async {
    final words = normalized.split(' ');
    if (words.isEmpty) return null;
    
    final brandWord = words.first;
    
    if (_brandAliases.containsKey(brandWord)) {
      final canonicalBrand = _brandAliases[brandWord]!;
      final modelPart = words.skip(1).join(' ');
      
      if (modelPart.isNotEmpty) {
        final canonical = '${canonicalBrand}_${modelPart.replaceAll(' ', '_')}';
        return BrandMatchResult(
          canonical: canonical,
          confidence: 0.9,
        );
      }
    }
    
    return null;
  }

  /// Fuzzy matching using Levenshtein distance
  Future<List<FuzzyMatchResult>> _findFuzzyMatches(
    String normalized, {
    int? year,
    String? userId,
    String? region,
    int maxResults = 3,
  }) async {
    final allCandidates = _getAllCandidates();
    final matches = <ScoredMatch>[];
    
    for (final candidate in allCandidates) {
      final distance = _levenshteinDistance(normalized, candidate);
      final maxLength = max(normalized.length, candidate.length);
      
      if (maxLength == 0) continue;
      
      final similarity = 1 - (distance / maxLength);
      
      if (similarity >= _confidenceThresholds['low']!) {
        final confidence = _calculateConfidence(ConfidenceFactors(
          editDistance: distance,
          lengthSimilarity: similarity,
          brandMatch: _hasBrandMatch(normalized, candidate),
          yearMatch: year != null ? _hasYearMatch(candidate, year) : true,
          contextClues: _countContextClues(normalized, candidate),
        ));
        
        matches.add(ScoredMatch(
          canonical: candidate,
          confidence: confidence,
          distance: distance,
          matchType: MatchType.fuzzy,
          requiresConfirmation: confidence < _confidenceThresholds['medium']!,
          score: confidence,
        ));
      }
    }
    
    // Sort by confidence score and return top matches
    matches.sort((a, b) => b.score.compareTo(a.score));
    
    final topMatches = matches.take(maxResults).toList();
    
    return topMatches.map((match) {
      final alternativeMatches = matches
          .skip(1)
          .take(2)
          .map((alt) => AlternativeMatch(
                canonical: alt.canonical,
                confidence: alt.confidence,
                matchType: alt.matchType,
              ))
          .toList();

      return FuzzyMatchResult(
        canonical: match.canonical,
        confidence: match.confidence,
        distance: match.distance,
        matchType: match.matchType,
        requiresConfirmation: match.requiresConfirmation,
        alternativeMatches: alternativeMatches,
      );
    }).toList();
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String str1, String str2) {
    final matrix = List.generate(str2.length + 1, 
        (i) => List.filled(str1.length + 1, 0));
    
    for (int i = 0; i <= str1.length; i++) {
      matrix[0][i] = i;
    }
    
    for (int j = 0; j <= str2.length; j++) {
      matrix[j][0] = j;
    }
    
    for (int j = 1; j <= str2.length; j++) {
      for (int i = 1; i <= str1.length; i++) {
        final indicator = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[j][i] = [
          matrix[j][i - 1] + 1, // deletion
          matrix[j - 1][i] + 1, // insertion
          matrix[j - 1][i - 1] + indicator, // substitution
        ].reduce(min);
      }
    }
    
    return matrix[str2.length][str1.length];
  }

  /// Calculate confidence score based on multiple factors
  double _calculateConfidence(ConfidenceFactors factors) {
    const weights = {
      'editDistance': 0.4,
      'lengthSimilarity': 0.2,
      'brandMatch': 0.2,
      'yearMatch': 0.1,
      'contextClues': 0.1,
    };
    
    // Edit distance score (inverted - lower distance = higher confidence)
    final maxDistance = max(factors.editDistance, 10);
    final distanceScore = 1 - (factors.editDistance / maxDistance);
    
    // Length similarity score
    final lengthScore = factors.lengthSimilarity;
    
    // Boolean factors
    final brandScore = factors.brandMatch ? 1.0 : 0.0;
    final yearScore = factors.yearMatch ? 1.0 : 0.0;
    final contextScore = min(factors.contextClues / 3.0, 1.0); // Normalize to 0-1
    
    final totalScore = (
        distanceScore * weights['editDistance']! +
        lengthScore * weights['lengthSimilarity']! +
        brandScore * weights['brandMatch']! +
        yearScore * weights['yearMatch']! +
        contextScore * weights['contextClues']!
    );
    
    return max(0.0, min(totalScore, 1.0));
  }

  /// Check if brand names match
  bool _hasBrandMatch(String input, String candidate) {
    final inputBrand = input.split('_').first.split(' ').first;
    final candidateBrand = candidate.split('_').first.split(' ').first;
    
    return inputBrand == candidateBrand || 
           _brandAliases[inputBrand] == candidateBrand;
  }

  /// Check if year is in reasonable range for model
  bool _hasYearMatch(String candidate, int year) {
    // Basic year validation - most combines are from 1990-2025
    return year >= 1990 && year <= DateTime.now().year + 1;
  }

  /// Count contextual clues that support the match
  int _countContextClues(String input, String candidate) {
    int clues = 0;
    
    // Check for series indicators (X9, S7, etc.)
    final inputSeries = RegExp(r'[a-z]\d+', caseSensitive: false)
        .allMatches(input)
        .map((m) => m.group(0)!)
        .toList();
    final candidateSeries = RegExp(r'[a-z]\d+', caseSensitive: false)
        .allMatches(candidate)
        .map((m) => m.group(0)!)
        .toList();
    
    for (final series in inputSeries) {
      if (candidateSeries.any((cs) => cs.toLowerCase() == series.toLowerCase())) {
        clues++;
      }
    }
    
    // Check for numeric matches
    final inputNumbers = RegExp(r'\d+')
        .allMatches(input)
        .map((m) => m.group(0)!)
        .toList();
    final candidateNumbers = RegExp(r'\d+')
        .allMatches(candidate)
        .map((m) => m.group(0)!)
        .toList();
    
    for (final num in inputNumbers) {
      if (candidateNumbers.contains(num)) {
        clues++;
      }
    }
    
    return clues;
  }

  /// Get all candidate models for fuzzy matching
  List<String> _getAllCandidates() {
    final candidates = <String>{};
    
    // Add canonical models
    candidates.addAll(_modelVariants.keys);
    
    // Add common variants
    for (final variants in _modelVariants.values) {
      for (final variant in variants) {
        candidates.add(_toCanonicalFormat(variant));
      }
    }
    
    return candidates.toList();
  }

  /// Convert to canonical format
  String _toCanonicalFormat(String input) {
    return input
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Cache management
  String _getCacheKey(String input) {
    return 'normalize_${_normalizeInput(input)}';
  }

  FuzzyMatchResult? _getCachedMatch(String key) {
    final cached = _cache[key];
    
    if (cached != null && _isValid(cached)) {
      return cached;
    }
    
    _cache.remove(key);
    return null;
  }

  void _setCachedMatch(String key, FuzzyMatchResult result) {
    result.cachedAt = DateTime.now().millisecondsSinceEpoch;
    _cache[key] = result;
  }

  bool _isValid(FuzzyMatchResult result) {
    final cachedAt = result.cachedAt ?? 0;
    return (DateTime.now().millisecondsSinceEpoch - cachedAt) < _cacheTimeout;
  }

  /// Learn from user corrections to improve future matching
  Future<void> learnFromCorrection(
    String originalInput,
    String incorrectSuggestion,
    String correctAnswer,
  ) async {
    // In a real implementation, this would update the database
    // with the learning data to improve future matches
    print('Learning: "$originalInput" -> "$correctAnswer" (not "$incorrectSuggestion")');
  }
}

/// Supporting classes

class TypoPattern {
  final String pattern;
  final String replacement;
  final String description;

  const TypoPattern({
    required this.pattern,
    required this.replacement,
    required this.description,
  });
}

class BrandMatchResult {
  final String canonical;
  final double confidence;

  BrandMatchResult({
    required this.canonical,
    required this.confidence,
  });
}

class ConfidenceFactors {
  final int editDistance;
  final double lengthSimilarity;
  final bool brandMatch;
  final bool yearMatch;
  final int contextClues;

  ConfidenceFactors({
    required this.editDistance,
    required this.lengthSimilarity,
    required this.brandMatch,
    required this.yearMatch,
    required this.contextClues,
  });
}

class ScoredMatch extends FuzzyMatchResult {
  final double score;

  ScoredMatch({
    required String canonical,
    required double confidence,
    required int distance,
    required MatchType matchType,
    required bool requiresConfirmation,
    required this.score,
  }) : super(
          canonical: canonical,
          confidence: confidence,
          distance: distance,
          matchType: matchType,
          requiresConfirmation: requiresConfirmation,
        );
}

class NormalizationException implements Exception {
  final String message;
  final String? input;
  final List<String>? suggestions;

  NormalizationException(this.message, [this.input, this.suggestions]);

  @override
  String toString() => 'NormalizationException: $message';
}