/**
 * Fuzzy search utility for FieldReady combine selection
 * Provides intelligent search with ranking and relevance scoring
 */

import '../data/combine_data.dart';

class FuzzySearchResult<T> {
  final T item;
  final double score;
  final List<String> matchedTerms;

  const FuzzySearchResult({
    required this.item,
    required this.score,
    required this.matchedTerms,
  });
}

class FuzzySearch {
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  static double _similarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final distance = _levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    return 1.0 - (distance / maxLength);
  }

  /// Check if query contains all words from search term
  static bool _containsAllWords(String text, String query) {
    final textWords = text.toLowerCase().split(RegExp(r'\s+'));
    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));
    
    return queryWords.every((queryWord) =>
        textWords.any((textWord) => textWord.contains(queryWord)));
  }

  /// Search combines with fuzzy matching and intelligent scoring
  static List<FuzzySearchResult<CombineData>> searchCombines(
    String query, List<CombineData> combines, {
    double threshold = 0.3,
    int maxResults = 50,
  }) {
    if (query.trim().isEmpty) {
      return combines
          .map((combine) => FuzzySearchResult(
                item: combine,
                score: 1.0,
                matchedTerms: [],
              ))
          .toList();
    }

    final results = <FuzzySearchResult<CombineData>>[];
    final normalizedQuery = query.toLowerCase().trim();

    for (final combine in combines) {
      double bestScore = 0.0;
      final matchedTerms = <String>[];

      // Score against different fields with different weights
      final scoringFields = [
        // High priority matches
        (combine.displayName, 1.0),
        (combine.brand, 0.9),
        (combine.model, 0.9),
        
        // Medium priority matches
        ('${combine.brand} ${combine.model}', 0.8),
        (combine.specs.headerSize, 0.7),
        (combine.specs.enginePower, 0.7),
        
        // Lower priority matches
        ...combine.searchTerms.map((term) => (term, 0.6)),
        ...combine.bestFor.map((capability) => (capability, 0.5)),
        ...combine.specs.cropTypes.map((crop) => (crop, 0.4)),
      ];

      for (final (field, weight) in scoringFields) {
        final fieldLower = field.toLowerCase();
        
        // Exact match bonus
        if (fieldLower == normalizedQuery) {
          bestScore = (bestScore < weight * 1.2) ? weight * 1.2 : bestScore;
          if (!matchedTerms.contains(field)) matchedTerms.add(field);
          continue;
        }

        // Starts with bonus
        if (fieldLower.startsWith(normalizedQuery)) {
          final score = weight * 1.1;
          bestScore = (bestScore < score) ? score : bestScore;
          if (!matchedTerms.contains(field)) matchedTerms.add(field);
          continue;
        }

        // Contains query
        if (fieldLower.contains(normalizedQuery)) {
          final score = weight * 0.9;
          bestScore = (bestScore < score) ? score : bestScore;
          if (!matchedTerms.contains(field)) matchedTerms.add(field);
          continue;
        }

        // Multi-word queries
        if (normalizedQuery.contains(' ')) {
          if (_containsAllWords(fieldLower, normalizedQuery)) {
            final score = weight * 0.8;
            bestScore = (bestScore < score) ? score : bestScore;
            if (!matchedTerms.contains(field)) matchedTerms.add(field);
            continue;
          }
        }

        // Fuzzy matching
        final similarity = _similarity(fieldLower, normalizedQuery);
        if (similarity > threshold) {
          final score = weight * similarity * 0.7;
          bestScore = (bestScore < score) ? score : bestScore;
          if (similarity > 0.6 && !matchedTerms.contains(field)) {
            matchedTerms.add(field);
          }
        }
      }

      // Boost popular combines slightly
      if (combine.popularityScore > 85) {
        bestScore *= 1.05;
      }

      // Boost highly rated combines
      if (combine.avgRating >= 4.5) {
        bestScore *= 1.02;
      }

      if (bestScore > threshold) {
        results.add(FuzzySearchResult(
          item: combine,
          score: bestScore,
          matchedTerms: matchedTerms,
        ));
      }
    }

    // Sort by score (descending) and limit results
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  /// Quick brand search
  static List<String> searchBrands(String query, List<CombineData> combines) {
    if (query.trim().isEmpty) return combines.map((c) => c.brand).toSet().toList()..sort();

    final normalizedQuery = query.toLowerCase();
    return combines
        .where((brand) => brand.brand.toLowerCase().contains(normalizedQuery))
        .map((c) => c.brand)
        .toSet()
        .toList()
      ..sort();
  }

  /// Search by capabilities
  static List<CombineData> searchByCapability(String capability, List<CombineData> combines) {
    final normalizedCapability = capability.toLowerCase();
    
    return combines
        .where((combine) => combine.bestFor
            .any((cap) => cap.toLowerCase().contains(normalizedCapability)))
        .toList();
  }

  /// Get suggestions based on partial input
  static List<String> getSuggestions(String partialQuery, List<CombineData> combines) {
    if (partialQuery.trim().isEmpty) return [];

    final suggestions = <String>{};
    final normalizedQuery = partialQuery.toLowerCase();

    for (final combine in combines) {
      // Add brand suggestions
      if (combine.brand.toLowerCase().startsWith(normalizedQuery)) {
        suggestions.add(combine.brand);
      }

      // Add model suggestions
      if (combine.model.toLowerCase().startsWith(normalizedQuery)) {
        suggestions.add(combine.model);
      }

      // Add display name suggestions
      if (combine.displayName.toLowerCase().startsWith(normalizedQuery)) {
        suggestions.add(combine.displayName);
      }

      // Add search term suggestions
      for (final term in combine.searchTerms) {
        if (term.toLowerCase().startsWith(normalizedQuery)) {
          suggestions.add(term);
        }
      }

      // Add capability suggestions
      for (final capability in combine.bestFor) {
        if (capability.toLowerCase().startsWith(normalizedQuery)) {
          suggestions.add(capability);
        }
      }
    }

    return suggestions.take(8).toList()..sort();
  }

  /// Advanced search with filters
  static List<CombineData> advancedSearch(List<CombineData> combines, {
    String? query,
    String? brand,
    List<String>? cropTypes,
    String? enginePowerRange,
    bool? hasYieldMapping,
    bool? hasMoistureMapping,
    double minRating = 0.0,
  }) {
    var results = combines;

    // Apply text search
    if (query != null && query.trim().isNotEmpty) {
      final searchResults = searchCombines(query, combines);
      results = searchResults.map((r) => r.item).toList();
    }

    // Apply brand filter
    if (brand != null && brand.isNotEmpty) {
      results = results.where((c) => c.brand == brand).toList();
    }

    // Apply crop type filter
    if (cropTypes != null && cropTypes.isNotEmpty) {
      results = results.where((c) => 
          cropTypes.any((crop) => c.specs.cropTypes.contains(crop))).toList();
    }

    // Apply yield mapping filter
    if (hasYieldMapping != null) {
      results = results.where((c) => c.specs.hasYieldMapping == hasYieldMapping).toList();
    }

    // Apply moisture mapping filter
    if (hasMoistureMapping != null) {
      results = results.where((c) => c.specs.hasMoistureMapping == hasMoistureMapping).toList();
    }

    // Apply rating filter
    if (minRating > 0.0) {
      results = results.where((c) => c.avgRating >= minRating).toList();
    }

    return results;
  }
}