/**
 * Common Types and Models for FieldReady
 * Defines shared types used across the application
 */

/// User preferences model
class UserPreferences {
  final String userId;
  final Map<String, dynamic> settings;
  final String? defaultCombineId;
  final List<String> favoriteFields;
  final bool notificationsEnabled;
  final String? preferredUnit; // 'metric' or 'imperial'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    required this.settings,
    this.defaultCombineId,
    this.favoriteFields = const [],
    this.notificationsEnabled = true,
    this.preferredUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'settings': settings,
      'defaultCombineId': defaultCombineId,
      'favoriteFields': favoriteFields,
      'notificationsEnabled': notificationsEnabled,
      'preferredUnit': preferredUnit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String,
      settings: Map<String, dynamic>.from(json['settings'] as Map),
      defaultCombineId: json['defaultCombineId'] as String?,
      favoriteFields: List<String>.from(json['favoriteFields'] ?? []),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      preferredUnit: json['preferredUnit'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Progressive capabilities model
class ProgressiveCapabilities {
  final String combineId;
  final int dataPoints;
  final Map<String, double> basicMetrics;
  final Map<String, double>? brandMetrics;
  final Map<String, double>? modelMetrics;
  final DateTime calculatedAt;
  
  // Additional properties for UI
  int get userCount => dataPoints;
  double get dataConfidence => dataPoints > 10 ? 0.9 : (dataPoints / 10.0);
  String get level => dataPoints > 50 ? 'rich' : dataPoints > 20 ? 'moderate' : 'basic';

  ProgressiveCapabilities({
    required this.combineId,
    required this.dataPoints,
    required this.basicMetrics,
    this.brandMetrics,
    this.modelMetrics,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'combineId': combineId,
      'dataPoints': dataPoints,
      'basicMetrics': basicMetrics,
      'brandMetrics': brandMetrics,
      'modelMetrics': modelMetrics,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory ProgressiveCapabilities.fromJson(Map<String, dynamic> json) {
    return ProgressiveCapabilities(
      combineId: json['combineId'] as String,
      dataPoints: json['dataPoints'] as int,
      basicMetrics: Map<String, double>.from(json['basicMetrics'] as Map),
      brandMetrics: json['brandMetrics'] != null
          ? Map<String, double>.from(json['brandMetrics'] as Map)
          : null,
      modelMetrics: json['modelMetrics'] != null
          ? Map<String, double>.from(json['modelMetrics'] as Map)
          : null,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}

/// Data retention policy model
class DataRetentionPolicy {
  final String policyName;
  final Map<String, int> retentionDays; // collection -> days to retain
  final List<String> excludedCollections;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? lastExecuted;

  DataRetentionPolicy({
    required this.policyName,
    required this.retentionDays,
    this.excludedCollections = const [],
    this.enabled = true,
    required this.createdAt,
    this.lastExecuted,
  });

  Map<String, dynamic> toJson() {
    return {
      'policyName': policyName,
      'retentionDays': retentionDays,
      'excludedCollections': excludedCollections,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'lastExecuted': lastExecuted?.toIso8601String(),
    };
  }

  factory DataRetentionPolicy.fromJson(Map<String, dynamic> json) {
    return DataRetentionPolicy(
      policyName: json['policyName'] as String,
      retentionDays: Map<String, int>.from(json['retentionDays'] as Map),
      excludedCollections: List<String>.from(json['excludedCollections'] ?? []),
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastExecuted: json['lastExecuted'] != null
          ? DateTime.parse(json['lastExecuted'] as String)
          : null,
    );
  }
}

// ConnectivityResult enum removed to avoid conflict with connectivity_plus package
// Use connectivity_plus.ConnectivityResult directly in code