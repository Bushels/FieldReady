/**
 * Data models for the FieldFirst combine specifications system
 * Includes all necessary models for offline-first architecture
 */

import 'package:equatable/equatable.dart';
import 'harvest_models.dart';

/// Base class for all documents with common fields
abstract class BaseDocument {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseDocument({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseDocument &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Enums for type safety
enum ConfidenceLevel { high, medium, low }
enum MatchType { exact, variant, fuzzy, brandAlias }
enum SyncStatus { pending, syncing, completed, failed }
enum SyncOperationType { create, update, delete }
enum ComplianceLevel { required, optional, system }

/// Moisture tolerance specifications
class MoistureTolerance {
  final double min;
  final double max;
  final double optimal;
  final ConfidenceLevel confidence;

  MoistureTolerance({
    required this.min,
    required this.max,
    required this.optimal,
    required this.confidence,
  });

  factory MoistureTolerance.fromJson(Map<String, dynamic> json) {
    return MoistureTolerance(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      optimal: (json['optimal'] as num).toDouble(),
      confidence: ConfidenceLevel.values.firstWhere(
        (e) => e.name == json['confidence'],
        orElse: () => ConfidenceLevel.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'optimal': optimal,
      'confidence': confidence.name,
    };
  }

  MoistureTolerance copyWith({
    double? min,
    double? max,
    double? optimal,
    ConfidenceLevel? confidence,
  }) {
    return MoistureTolerance(
      min: min ?? this.min,
      max: max ?? this.max,
      optimal: optimal ?? this.optimal,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Tough crop ability ratings
class ToughCropAbility {
  final int rating; // 1-10 scale
  final List<String> crops;
  final List<String> limitations;
  final ConfidenceLevel confidence;
  final Map<String, int>? cropSpecificRatings; // Crop-specific ratings
  final bool handlesHighMoisture; // Can handle high moisture crops
  final bool handlesLodgedCrops; // Can handle lodged/down crops
  final bool handlesGreenStem; // Can handle green stem conditions

  ToughCropAbility({
    required this.rating,
    required this.crops,
    required this.limitations,
    required this.confidence,
    this.cropSpecificRatings,
    this.handlesHighMoisture = false,
    this.handlesLodgedCrops = false,
    this.handlesGreenStem = false,
  });

  factory ToughCropAbility.fromJson(Map<String, dynamic> json) {
    return ToughCropAbility(
      rating: json['rating'] as int,
      crops: List<String>.from(json['crops'] as List),
      limitations: List<String>.from(json['limitations'] as List),
      confidence: ConfidenceLevel.values.firstWhere(
        (e) => e.name == json['confidence'],
        orElse: () => ConfidenceLevel.medium,
      ),
      cropSpecificRatings: json['cropSpecificRatings'] != null
          ? Map<String, int>.from(json['cropSpecificRatings'])
          : null,
      handlesHighMoisture: json['handlesHighMoisture'] ?? false,
      handlesLodgedCrops: json['handlesLodgedCrops'] ?? false,
      handlesGreenStem: json['handlesGreenStem'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'crops': crops,
      'limitations': limitations,
      'confidence': confidence.name,
      'cropSpecificRatings': cropSpecificRatings,
      'handlesHighMoisture': handlesHighMoisture,
      'handlesLodgedCrops': handlesLodgedCrops,
      'handlesGreenStem': handlesGreenStem,
    };
  }

  ToughCropAbility copyWith({
    int? rating,
    List<String>? crops,
    List<String>? limitations,
    ConfidenceLevel? confidence,
    Map<String, int>? cropSpecificRatings,
    bool? handlesHighMoisture,
    bool? handlesLodgedCrops,
    bool? handlesGreenStem,
  }) {
    return ToughCropAbility(
      rating: rating ?? this.rating,
      crops: crops ?? this.crops,
      limitations: limitations ?? this.limitations,
      confidence: confidence ?? this.confidence,
      cropSpecificRatings: cropSpecificRatings ?? this.cropSpecificRatings,
      handlesHighMoisture: handlesHighMoisture ?? this.handlesHighMoisture,
      handlesLodgedCrops: handlesLodgedCrops ?? this.handlesLodgedCrops,
      handlesGreenStem: handlesGreenStem ?? this.handlesGreenStem,
    );
  }
}

/// Source data tracking for transparency
class SourceData {
  final int userReports;
  final bool manufacturerSpecs;
  final bool expertValidation;
  final DateTime lastUpdated;

  SourceData({
    required this.userReports,
    required this.manufacturerSpecs,
    required this.expertValidation,
    required this.lastUpdated,
  });

  factory SourceData.fromJson(Map<String, dynamic> json) {
    return SourceData(
      userReports: json['userReports'] as int,
      manufacturerSpecs: json['manufacturerSpecs'] as bool,
      expertValidation: json['expertValidation'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userReports': userReports,
      'manufacturerSpecs': manufacturerSpecs,
      'expertValidation': expertValidation,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  SourceData copyWith({
    int? userReports,
    bool? manufacturerSpecs,
    bool? expertValidation,
    DateTime? lastUpdated,
  }) {
    return SourceData(
      userReports: userReports ?? this.userReports,
      manufacturerSpecs: manufacturerSpecs ?? this.manufacturerSpecs,
      expertValidation: expertValidation ?? this.expertValidation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Enhanced harvest capabilities for combine specifications
class HarvestCapabilities {
  final double operatingSpeedKmh; // Operating speed in km/h
  final double grainTankCapacityL; // Grain tank capacity in liters
  final double unloadingRateLS; // Unloading rate in L/s
  final double fuelConsumptionLh; // Fuel consumption in L/h
  final double dailyCapacityHa; // Typical daily capacity in hectares
  final bool hasYieldMapping; // Yield mapping capability
  final bool hasMoistureMapping; // Moisture mapping capability
  final bool hasAutomaticAdjustments; // Automatic setting adjustments
  final Map<String, double> weatherLimitations; // Weather-specific limitations
  final int reliabilityRating; // 1-10 reliability under stress
  final int maintenanceComplexity; // 1-10 maintenance complexity
  
  // Equipment factor integration
  final Map<String, double>? equipmentFactorModifiers; // Equipment-specific modifiers
  final DateTime? lastFactorUpdate; // When equipment factors were last calculated

  HarvestCapabilities({
    required this.operatingSpeedKmh,
    required this.grainTankCapacityL,
    required this.unloadingRateLS,
    required this.fuelConsumptionLh,
    required this.dailyCapacityHa,
    this.hasYieldMapping = false,
    this.hasMoistureMapping = false,
    this.hasAutomaticAdjustments = false,
    this.weatherLimitations = const {},
    required this.reliabilityRating,
    required this.maintenanceComplexity,
    this.equipmentFactorModifiers,
    this.lastFactorUpdate,
  });

  factory HarvestCapabilities.fromJson(Map<String, dynamic> json) {
    return HarvestCapabilities(
      operatingSpeedKmh: (json['operatingSpeedKmh'] as num).toDouble(),
      grainTankCapacityL: (json['grainTankCapacityL'] as num).toDouble(),
      unloadingRateLS: (json['unloadingRateLS'] as num).toDouble(),
      fuelConsumptionLh: (json['fuelConsumptionLh'] as num).toDouble(),
      dailyCapacityHa: (json['dailyCapacityHa'] as num).toDouble(),
      hasYieldMapping: json['hasYieldMapping'] ?? false,
      hasMoistureMapping: json['hasMoistureMapping'] ?? false,
      hasAutomaticAdjustments: json['hasAutomaticAdjustments'] ?? false,
      weatherLimitations: json['weatherLimitations'] != null
          ? Map<String, double>.from(json['weatherLimitations'])
          : {},
      reliabilityRating: json['reliabilityRating'] as int,
      maintenanceComplexity: json['maintenanceComplexity'] as int,
      equipmentFactorModifiers: json['equipmentFactorModifiers'] != null
          ? Map<String, double>.from(json['equipmentFactorModifiers'])
          : null,
      lastFactorUpdate: json['lastFactorUpdate'] != null
          ? DateTime.parse(json['lastFactorUpdate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operatingSpeedKmh': operatingSpeedKmh,
      'grainTankCapacityL': grainTankCapacityL,
      'unloadingRateLS': unloadingRateLS,
      'fuelConsumptionLh': fuelConsumptionLh,
      'dailyCapacityHa': dailyCapacityHa,
      'hasYieldMapping': hasYieldMapping,
      'hasMoistureMapping': hasMoistureMapping,
      'hasAutomaticAdjustments': hasAutomaticAdjustments,
      'weatherLimitations': weatherLimitations,
      'reliabilityRating': reliabilityRating,
      'maintenanceComplexity': maintenanceComplexity,
      'equipmentFactorModifiers': equipmentFactorModifiers,
      'lastFactorUpdate': lastFactorUpdate?.toIso8601String(),
    };
  }

  HarvestCapabilities copyWith({
    double? operatingSpeedKmh,
    double? grainTankCapacityL,
    double? unloadingRateLS,
    double? fuelConsumptionLh,
    double? dailyCapacityHa,
    bool? hasYieldMapping,
    bool? hasMoistureMapping,
    bool? hasAutomaticAdjustments,
    Map<String, double>? weatherLimitations,
    int? reliabilityRating,
    int? maintenanceComplexity,
    Map<String, double>? equipmentFactorModifiers,
    DateTime? lastFactorUpdate,
  }) {
    return HarvestCapabilities(
      operatingSpeedKmh: operatingSpeedKmh ?? this.operatingSpeedKmh,
      grainTankCapacityL: grainTankCapacityL ?? this.grainTankCapacityL,
      unloadingRateLS: unloadingRateLS ?? this.unloadingRateLS,
      fuelConsumptionLh: fuelConsumptionLh ?? this.fuelConsumptionLh,
      dailyCapacityHa: dailyCapacityHa ?? this.dailyCapacityHa,
      hasYieldMapping: hasYieldMapping ?? this.hasYieldMapping,
      hasMoistureMapping: hasMoistureMapping ?? this.hasMoistureMapping,
      hasAutomaticAdjustments: hasAutomaticAdjustments ?? this.hasAutomaticAdjustments,
      weatherLimitations: weatherLimitations ?? this.weatherLimitations,
      reliabilityRating: reliabilityRating ?? this.reliabilityRating,
      maintenanceComplexity: maintenanceComplexity ?? this.maintenanceComplexity,
      equipmentFactorModifiers: equipmentFactorModifiers ?? this.equipmentFactorModifiers,
      lastFactorUpdate: lastFactorUpdate ?? this.lastFactorUpdate,
    );
  }

  /// Apply equipment factors to create adjusted harvest capabilities
  HarvestCapabilities applyEquipmentFactors(List<EquipmentFactor> factors) {
    final modifiers = <String, double>{};
    
    // Calculate adjusted values based on equipment factors
    double adjustedSpeed = operatingSpeedKmh;
    double adjustedFuel = fuelConsumptionLh;
    double adjustedDailyCapacity = dailyCapacityHa;
    int adjustedReliability = reliabilityRating;
    int adjustedMaintenance = maintenanceComplexity;

    for (final factor in factors) {
      modifiers[factor.type.name] = factor.performanceMultiplier;
      
      switch (factor.type) {
        case EquipmentFactorType.speedEfficiency:
          adjustedSpeed *= factor.performanceMultiplier;
          break;
        case EquipmentFactorType.fuelConsumption:
          adjustedFuel *= factor.performanceMultiplier;
          break;
        case EquipmentFactorType.reliabilityRating:
          adjustedReliability = (adjustedReliability * factor.performanceMultiplier).round();
          break;
        case EquipmentFactorType.maintenanceComplexity:
          adjustedMaintenance = (adjustedMaintenance * factor.performanceMultiplier).round();
          break;
        default:
          // Other factors affect overall performance but don't directly modify capabilities
          break;
      }
    }

    // Recalculate daily capacity based on adjusted speed and other factors
    final overallMultiplier = factors.isNotEmpty 
        ? factors.map((f) => f.performanceMultiplier).reduce((a, b) => a * b) / factors.length
        : 1.0;
    adjustedDailyCapacity *= overallMultiplier;

    return copyWith(
      operatingSpeedKmh: adjustedSpeed,
      fuelConsumptionLh: adjustedFuel,
      dailyCapacityHa: adjustedDailyCapacity,
      reliabilityRating: adjustedReliability.clamp(1, 10),
      maintenanceComplexity: adjustedMaintenance.clamp(1, 10),
      equipmentFactorModifiers: modifiers,
      lastFactorUpdate: DateTime.now(),
    );
  }

  /// Check if equipment factors need to be recalculated (older than 1 hour)
  bool get needsFactorUpdate {
    if (lastFactorUpdate == null) return true;
    return DateTime.now().difference(lastFactorUpdate!) > const Duration(hours: 1);
  }
}

/// Main combine specifications document
class CombineSpec extends BaseDocument {
  final String brand;
  final String model;
  final List<String> modelVariants;
  final int? year;
  final String userId;
  final MoistureTolerance moistureTolerance;
  final ToughCropAbility toughCropAbility;
  final SourceData sourceData;
  final String? region;
  final bool isPublic;
  final HarvestCapabilities? harvestCapabilities; // Enhanced harvest capabilities

  CombineSpec({
    required String id,
    required this.brand,
    required this.model,
    required this.modelVariants,
    this.year,
    required this.userId,
    required this.moistureTolerance,
    required this.toughCropAbility,
    required this.sourceData,
    this.region,
    required this.isPublic,
    this.harvestCapabilities,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CombineSpec.fromJson(Map<String, dynamic> json) {
    return CombineSpec(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      modelVariants: List<String>.from(json['modelVariants'] as List),
      year: json['year'] as int?,
      userId: json['userId'] as String,
      moistureTolerance: MoistureTolerance.fromJson(json['moistureTolerance']),
      toughCropAbility: ToughCropAbility.fromJson(json['toughCropAbility']),
      sourceData: SourceData.fromJson(json['sourceData']),
      region: json['region'] as String?,
      isPublic: json['isPublic'] as bool,
      harvestCapabilities: json['harvestCapabilities'] != null
          ? HarvestCapabilities.fromJson(json['harvestCapabilities'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'modelVariants': modelVariants,
      'year': year,
      'userId': userId,
      'moistureTolerance': moistureTolerance.toJson(),
      'toughCropAbility': toughCropAbility.toJson(),
      'sourceData': sourceData.toJson(),
      'region': region,
      'isPublic': isPublic,
      'harvestCapabilities': harvestCapabilities?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CombineSpec copyWith({
    String? id,
    String? brand,
    String? model,
    List<String>? modelVariants,
    int? year,
    String? userId,
    MoistureTolerance? moistureTolerance,
    ToughCropAbility? toughCropAbility,
    SourceData? sourceData,
    String? region,
    bool? isPublic,
    HarvestCapabilities? harvestCapabilities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CombineSpec(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      modelVariants: modelVariants ?? this.modelVariants,
      year: year ?? this.year,
      userId: userId ?? this.userId,
      moistureTolerance: moistureTolerance ?? this.moistureTolerance,
      toughCropAbility: toughCropAbility ?? this.toughCropAbility,
      sourceData: sourceData ?? this.sourceData,
      region: region ?? this.region,
      isPublic: isPublic ?? this.isPublic,
      harvestCapabilities: harvestCapabilities ?? this.harvestCapabilities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User's personal combine equipment
class UserCombine extends BaseDocument {
  final String userId;
  final String combineSpecId;
  final String? nickname;
  final int? purchaseYear;
  final int? hoursOfOperation;
  final List<String>? maintenanceNotes;
  final Map<String, dynamic> customSettings;
  final bool isActive;
  final DateTime? lastSyncAt;

  UserCombine({
    required String id,
    required this.userId,
    required this.combineSpecId,
    this.nickname,
    this.purchaseYear,
    this.hoursOfOperation,
    this.maintenanceNotes,
    required this.customSettings,
    required this.isActive,
    this.lastSyncAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory UserCombine.fromJson(Map<String, dynamic> json) {
    return UserCombine(
      id: json['id'] as String,
      userId: json['userId'] as String,
      combineSpecId: json['combineSpecId'] as String,
      nickname: json['nickname'] as String?,
      purchaseYear: json['purchaseYear'] as int?,
      hoursOfOperation: json['hoursOfOperation'] as int?,
      maintenanceNotes: json['maintenanceNotes'] != null
          ? List<String>.from(json['maintenanceNotes'] as List)
          : null,
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map),
      isActive: json['isActive'] as bool,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'combineSpecId': combineSpecId,
      'nickname': nickname,
      'purchaseYear': purchaseYear,
      'hoursOfOperation': hoursOfOperation,
      'maintenanceNotes': maintenanceNotes,
      'customSettings': customSettings,
      'isActive': isActive,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserCombine copyWith({
    String? id,
    String? userId,
    String? combineSpecId,
    String? nickname,
    int? purchaseYear,
    int? hoursOfOperation,
    List<String>? maintenanceNotes,
    Map<String, dynamic>? customSettings,
    bool? isActive,
    DateTime? lastSyncAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCombine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      combineSpecId: combineSpecId ?? this.combineSpecId,
      nickname: nickname ?? this.nickname,
      purchaseYear: purchaseYear ?? this.purchaseYear,
      hoursOfOperation: hoursOfOperation ?? this.hoursOfOperation,
      maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
      customSettings: customSettings ?? this.customSettings,
      isActive: isActive ?? this.isActive,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Fuzzy matching results
class FuzzyMatchResult {
  final String canonical;
  final double confidence;
  final int distance;
  final MatchType matchType;
  final bool requiresConfirmation;
  final List<AlternativeMatch>? alternativeMatches;
  int? cachedAt;

  FuzzyMatchResult({
    required this.canonical,
    required this.confidence,
    required this.distance,
    required this.matchType,
    required this.requiresConfirmation,
    this.alternativeMatches,
    this.cachedAt,
  });

  factory FuzzyMatchResult.fromJson(Map<String, dynamic> json) {
    return FuzzyMatchResult(
      canonical: json['canonical'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      distance: json['distance'] as int,
      matchType: MatchType.values.firstWhere(
        (e) => e.name == json['matchType'],
        orElse: () => MatchType.fuzzy,
      ),
      requiresConfirmation: json['requiresConfirmation'] as bool,
      alternativeMatches: json['alternativeMatches'] != null
          ? (json['alternativeMatches'] as List)
              .map((e) => AlternativeMatch.fromJson(e))
              .toList()
          : null,
      cachedAt: json['cachedAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canonical': canonical,
      'confidence': confidence,
      'distance': distance,
      'matchType': matchType.name,
      'requiresConfirmation': requiresConfirmation,
      'alternativeMatches': alternativeMatches?.map((e) => e.toJson()).toList(),
      'cachedAt': cachedAt,
    };
  }
}

/// Alternative match for fuzzy results
class AlternativeMatch {
  final String canonical;
  final double confidence;
  final MatchType matchType;

  AlternativeMatch({
    required this.canonical,
    required this.confidence,
    required this.matchType,
  });

  factory AlternativeMatch.fromJson(Map<String, dynamic> json) {
    return AlternativeMatch(
      canonical: json['canonical'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      matchType: MatchType.values.firstWhere(
        (e) => e.name == json['matchType'],
        orElse: () => MatchType.fuzzy,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canonical': canonical,
      'confidence': confidence,
      'matchType': matchType.name,
    };
  }
}

/// Model normalization rules
class ModelNormalizationRule extends BaseDocument {
  final String pattern;
  final String canonical;
  final String brand;
  final double confidence;
  final bool isActive;
  final String source;
  final int usageCount;
  final DateTime? lastUsed;

  ModelNormalizationRule({
    required String id,
    required this.pattern,
    required this.canonical,
    required this.brand,
    required this.confidence,
    required this.isActive,
    required this.source,
    required this.usageCount,
    this.lastUsed,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory ModelNormalizationRule.fromJson(Map<String, dynamic> json) {
    return ModelNormalizationRule(
      id: json['id'] as String,
      pattern: json['pattern'] as String,
      canonical: json['canonical'] as String,
      brand: json['brand'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      source: json['source'] as String,
      usageCount: json['usageCount'] as int,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pattern': pattern,
      'canonical': canonical,
      'brand': brand,
      'confidence': confidence,
      'isActive': isActive,
      'source': source,
      'usageCount': usageCount,
      'lastUsed': lastUsed?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Brand aliases for normalization
class BrandAlias extends BaseDocument {
  final String alias;
  final String canonical;
  final double confidence;
  final bool isActive;
  final String source;

  BrandAlias({
    required String id,
    required this.alias,
    required this.canonical,
    required this.confidence,
    required this.isActive,
    required this.source,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory BrandAlias.fromJson(Map<String, dynamic> json) {
    return BrandAlias(
      id: json['id'] as String,
      alias: json['alias'] as String,
      canonical: json['canonical'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isActive: json['isActive'] as bool,
      source: json['source'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'canonical': canonical,
      'confidence': confidence,
      'isActive': isActive,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Model variants for matching
class ModelVariant extends BaseDocument {
  final String variant;
  final String canonicalBrand;
  final String canonicalModel;
  final double confidence;
  final String source;
  final int usageCount;

  ModelVariant({
    required String id,
    required this.variant,
    required this.canonicalBrand,
    required this.canonicalModel,
    required this.confidence,
    required this.source,
    required this.usageCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory ModelVariant.fromJson(Map<String, dynamic> json) {
    return ModelVariant(
      id: json['id'] as String,
      variant: json['variant'] as String,
      canonicalBrand: json['canonicalBrand'] as String,
      canonicalModel: json['canonicalModel'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      source: json['source'] as String,
      usageCount: json['usageCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variant': variant,
      'canonicalBrand': canonicalBrand,
      'canonicalModel': canonicalModel,
      'confidence': confidence,
      'source': source,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Learning data for improving matching
class NormalizationLearning extends BaseDocument {
  final String originalInput;
  final String? incorrectSuggestion;
  final String correctAnswer;
  final double confidenceScore;
  final String userId;
  final bool improved;

  NormalizationLearning({
    required String id,
    required this.originalInput,
    this.incorrectSuggestion,
    required this.correctAnswer,
    required this.confidenceScore,
    required this.userId,
    required this.improved,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory NormalizationLearning.fromJson(Map<String, dynamic> json) {
    return NormalizationLearning(
      id: json['id'] as String,
      originalInput: json['originalInput'] as String,
      incorrectSuggestion: json['incorrectSuggestion'] as String?,
      correctAnswer: json['correctAnswer'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      userId: json['userId'] as String,
      improved: json['improved'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalInput': originalInput,
      'incorrectSuggestion': incorrectSuggestion,
      'correctAnswer': correctAnswer,
      'confidenceScore': confidenceScore,
      'userId': userId,
      'improved': improved,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Regional aggregation data
class RegionalInsight extends BaseDocument {
  final String region;
  final String? crop;
  final String? moistureRange;
  final int totalUsers;
  final int activeUsers;
  final ConfidenceLevel dataQuality;
  final DateTime lastUpdated;

  RegionalInsight({
    required String id,
    required this.region,
    this.crop,
    this.moistureRange,
    required this.totalUsers,
    required this.activeUsers,
    required this.dataQuality,
    required this.lastUpdated,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory RegionalInsight.fromJson(Map<String, dynamic> json) {
    return RegionalInsight(
      id: json['id'] as String,
      region: json['region'] as String,
      crop: json['crop'] as String?,
      moistureRange: json['moistureRange'] as String?,
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      dataQuality: ConfidenceLevel.values.firstWhere(
        (e) => e.name == json['dataQuality'],
        orElse: () => ConfidenceLevel.medium,
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'crop': crop,
      'moistureRange': moistureRange,
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'dataQuality': dataQuality.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Progressive insights based on data volume
class CombineInsight extends BaseDocument {
  final String region;
  final String level; // 'basic', 'brand', 'model'
  final int totalFarmers;
  final int dataPoints;
  final Map<String, dynamic> insights;
  final DateTime generatedAt;
  final DateTime expiresAt;

  CombineInsight({
    required String id,
    required this.region,
    required this.level,
    required this.totalFarmers,
    required this.dataPoints,
    required this.insights,
    required this.generatedAt,
    required this.expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory CombineInsight.fromJson(Map<String, dynamic> json) {
    return CombineInsight(
      id: json['id'] as String,
      region: json['region'] as String,
      level: json['level'] as String,
      totalFarmers: json['totalFarmers'] as int,
      dataPoints: json['dataPoints'] as int,
      insights: Map<String, dynamic>.from(json['insights'] as Map),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'level': level,
      'totalFarmers': totalFarmers,
      'dataPoints': dataPoints,
      'insights': insights,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Offline sync operation
class SyncOperation extends BaseDocument {
  final String userId;
  final SyncOperationType operation;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;
  SyncStatus status;
  int retryCount;
  DateTime? lastAttempt;
  String? error;
  final OperationPriority priority;

  SyncOperation({
    required String id,
    required this.userId,
    required this.operation,
    required this.collection,
    required this.documentId,
    this.data,
    required this.status,
    required this.retryCount,
    this.lastAttempt,
    this.error,
    required this.priority,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      operation: SyncOperationType.values.firstWhere(
        (e) => e.name == json['operation'],
      ),
      collection: json['collection'] as String,
      documentId: json['documentId'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      retryCount: json['retryCount'] as int,
      lastAttempt: json['lastAttempt'] != null
          ? DateTime.parse(json['lastAttempt'] as String)
          : null,
      error: json['error'] as String?,
      priority: OperationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => OperationPriority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'operation': operation.name,
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'status': status.name,
      'retryCount': retryCount,
      'lastAttempt': lastAttempt?.toIso8601String(),
      'error': error,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Audit log for PIPEDA compliance
class AuditLog extends BaseDocument {
  final String? userId;
  final String action;
  final String collection;
  final String? documentId;
  final Map<String, dynamic>? changes;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final ComplianceLevel complianceLevel;

  AuditLog({
    required String id,
    this.userId,
    required this.action,
    required this.collection,
    this.documentId,
    this.changes,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    required this.complianceLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      action: json['action'] as String,
      collection: json['collection'] as String,
      documentId: json['documentId'] as String?,
      changes: json['changes'] != null
          ? Map<String, dynamic>.from(json['changes'] as Map)
          : null,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      complianceLevel: ComplianceLevel.values.firstWhere(
        (e) => e.name == json['complianceLevel'],
        orElse: () => ComplianceLevel.optional,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'collection': collection,
      'documentId': documentId,
      'changes': changes,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': timestamp.toIso8601String(),
      'complianceLevel': complianceLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Peer comparison data for model capabilities
class PeerComparison extends Equatable {
  final List<String> betterThan;
  final List<String> similarTo;
  final List<String> challengedBy;
  final double overallScore;
  final Map<String, double> categoryScores;

  const PeerComparison({
    required this.betterThan,
    required this.similarTo,
    required this.challengedBy,
    required this.overallScore,
    this.categoryScores = const {},
  });

  factory PeerComparison.fromJson(Map<String, dynamic> json) {
    return PeerComparison(
      betterThan: List<String>.from(json['betterThan'] as List),
      similarTo: List<String>.from(json['similarTo'] as List),
      challengedBy: List<String>.from(json['challengedBy'] as List),
      overallScore: (json['overallScore'] as num).toDouble(),
      categoryScores: json['categoryScores'] != null
          ? Map<String, double>.from(json['categoryScores'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'betterThan': betterThan,
      'similarTo': similarTo,
      'challengedBy': challengedBy,
      'overallScore': overallScore,
      'categoryScores': categoryScores,
    };
  }

  @override
  List<Object?> get props => [betterThan, similarTo, challengedBy, overallScore, categoryScores];
}

/// Sync status data for tracking synchronization state
class SyncStatusData extends BaseDocument {
  final String userId;
  final DateTime lastSyncAttempt;
  final DateTime? lastSuccessfulSync;
  final int pendingOperations;
  final int failedOperations;
  final SyncStatus status;
  final String? lastError;
  final Map<String, DateTime> collectionLastSync;
  final double syncProgress; // 0.0 to 1.0

  SyncStatusData({
    required String id,
    required this.userId,
    required this.lastSyncAttempt,
    this.lastSuccessfulSync,
    required this.pendingOperations,
    required this.failedOperations,
    required this.status,
    this.lastError,
    required this.collectionLastSync,
    required this.syncProgress,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory SyncStatusData.fromJson(Map<String, dynamic> json) {
    return SyncStatusData(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lastSyncAttempt: DateTime.parse(json['lastSyncAttempt'] as String),
      lastSuccessfulSync: json['lastSuccessfulSync'] != null
          ? DateTime.parse(json['lastSuccessfulSync'] as String)
          : null,
      pendingOperations: json['pendingOperations'] as int,
      failedOperations: json['failedOperations'] as int,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      lastError: json['lastError'] as String?,
      collectionLastSync: (json['collectionLastSync'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, DateTime.parse(value as String)),
      ),
      syncProgress: (json['syncProgress'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lastSyncAttempt': lastSyncAttempt.toIso8601String(),
      'lastSuccessfulSync': lastSuccessfulSync?.toIso8601String(),
      'pendingOperations': pendingOperations,
      'failedOperations': failedOperations,
      'status': status.name,
      'lastError': lastError,
      'collectionLastSync': collectionLastSync.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'syncProgress': syncProgress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SyncStatusData copyWith({
    String? id,
    String? userId,
    DateTime? lastSyncAttempt,
    DateTime? lastSuccessfulSync,
    int? pendingOperations,
    int? failedOperations,
    SyncStatus? status,
    String? lastError,
    Map<String, DateTime>? collectionLastSync,
    double? syncProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncStatusData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      collectionLastSync: collectionLastSync ?? this.collectionLastSync,
      syncProgress: syncProgress ?? this.syncProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Additional supporting enums
enum OperationPriority { high, medium, low }