/**
 * Combine data source for FieldReady selection UI
 * Contains detailed specifications, capabilities, and visual information
 */

import 'package:cloud_firestore/cloud_firestore.dart';

class CombineData {
  final String id;
  final String brand;
  final String model;
  final String displayName;
  final String imageUrl;
  final List<String> searchTerms;
  final CombineSpecs specs;
  final List<String> bestFor;
  final int popularityScore;
  final double avgRating;
  final int reviewCount;

  const CombineData({
    required this.id,
    required this.brand,
    required this.model,
    required this.displayName,
    required this.imageUrl,
    required this.searchTerms,
    required this.specs,
    required this.bestFor,
    required this.popularityScore,
    required this.avgRating,
    required this.reviewCount,
  });

  factory CombineData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CombineData(
      id: doc.id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      displayName: data['displayName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      searchTerms: List<String>.from(data['searchTerms'] ?? []),
      specs: CombineSpecs.fromMap(data['specs'] ?? {}),
      bestFor: List<String>.from(data['bestFor'] ?? []),
      popularityScore: data['popularityScore'] ?? 0,
      avgRating: (data['avgRating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  String get fullSearchText => [
    brand,
    model,
    displayName,
    ...searchTerms,
    ...bestFor,
    specs.headerSize,
    specs.enginePower,
  ].join(' ').toLowerCase();
}

class CombineSpecs {
  final String headerSize;
  final String enginePower;
  final String grainTankCapacity;
  final String operatingSpeed;
  final String dailyCapacity;
  final bool hasYieldMapping;
  final bool hasMoistureMapping;
  final bool hasAutomaticAdjustments;
  final List<String> cropTypes;

  const CombineSpecs({
    required this.headerSize,
    required this.enginePower,
    required this.grainTankCapacity,
    required this.operatingSpeed,
    required this.dailyCapacity,
    required this.hasYieldMapping,
    required this.hasMoistureMapping,
    required this.hasAutomaticAdjustments,
    required this.cropTypes,
  });

  factory CombineSpecs.fromMap(Map<String, dynamic> data) {
    return CombineSpecs(
      headerSize: data['headerSize'] ?? '',
      enginePower: data['enginePower'] ?? '',
      grainTankCapacity: data['grainTankCapacity'] ?? '',
      operatingSpeed: data['operatingSpeed'] ?? '',
      dailyCapacity: data['dailyCapacity'] ?? '',
      hasYieldMapping: data['hasYieldMapping'] ?? false,
      hasMoistureMapping: data['hasMoistureMapping'] ?? false,
      hasAutomaticAdjustments: data['hasAutomaticAdjustments'] ?? false,
      cropTypes: List<String>.from(data['cropTypes'] ?? []),
    );
  }
}

