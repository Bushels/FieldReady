/**
 * Harvest Intelligence Models for FieldFirst
 * Combines weather data with combine capabilities for optimal harvest timing
 * Includes weather API responses, crop conditions, and harvest recommendations
 */

import 'combine_models.dart';
import '../services/crop_threshold_service.dart';

/// Enums for harvest intelligence
enum WeatherProvider { tomorrowIo, msc }
enum RiskLevel { low, medium, high, critical }
enum HarvestRecommendation { optimal, acceptable, marginal, avoid }
enum WeatherCondition { clear, cloudy, rain, snow, fog, storm }
enum CropType { corn, soybeans, wheat, canola, barley, oats }

/// Weather data from APIs
class WeatherData {
  final String locationId;
  final DateTime timestamp;
  final WeatherProvider provider;
  final double? temperatureMin;
  final double? temperatureMax;
  final double? temperature;
  final double? humidity;
  final double? precipitation;
  final double? windSpeed;
  final double? windDirection;
  final double? dewPoint;
  final double? leafWetness;
  final double? evapotranspiration;
  final WeatherCondition condition;
  final String? description;
  final DateTime? sunrise;
  final DateTime? sunset;

  WeatherData({
    required this.locationId,
    required this.timestamp,
    required this.provider,
    this.temperatureMin,
    this.temperatureMax,
    this.temperature,
    this.humidity,
    this.precipitation,
    this.windSpeed,
    this.windDirection,
    this.dewPoint,
    this.leafWetness,
    this.evapotranspiration,
    required this.condition,
    this.description,
    this.sunrise,
    this.sunset,
  });

  factory WeatherData.fromTomorrowIo(Map<String, dynamic> json, String locationId) {
    final values = json['values'] as Map<String, dynamic>;
    
    return WeatherData(
      locationId: locationId,
      timestamp: DateTime.parse(json['time'] as String),
      provider: WeatherProvider.tomorrowIo,
      temperatureMin: values['temperatureMin']?.toDouble(),
      temperatureMax: values['temperatureMax']?.toDouble(),
      temperature: values['temperature']?.toDouble(),
      humidity: values['humidity']?.toDouble(),
      precipitation: values['precipitationIntensity']?.toDouble(),
      windSpeed: values['windSpeed']?.toDouble(),
      windDirection: values['windDirection']?.toDouble(),
      dewPoint: values['dewPoint']?.toDouble(),
      leafWetness: values['leafWetness']?.toDouble(),
      evapotranspiration: values['evapotranspiration']?.toDouble(),
      condition: _parseWeatherCondition(values['weatherCode']),
      description: values['weatherCodeFullDay'] as String?,
      sunrise: values['sunriseTime'] != null 
          ? DateTime.parse(values['sunriseTime'] as String)
          : null,
      sunset: values['sunsetTime'] != null 
          ? DateTime.parse(values['sunsetTime'] as String)
          : null,
    );
  }

  factory WeatherData.fromMsc(Map<String, dynamic> json, String locationId) {
    return WeatherData(
      locationId: locationId,
      timestamp: DateTime.parse(json['datetime'] as String),
      provider: WeatherProvider.msc,
      temperatureMin: json['temp_min']?.toDouble(),
      temperatureMax: json['temp_max']?.toDouble(),
      temperature: json['temp']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      precipitation: json['precip']?.toDouble(),
      windSpeed: json['wind_speed']?.toDouble(),
      windDirection: json['wind_dir']?.toDouble(),
      dewPoint: json['dew_point']?.toDouble(),
      condition: _parseWeatherConditionMsc(json['condition']),
      description: json['condition_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider.name,
      'temperatureMin': temperatureMin,
      'temperatureMax': temperatureMax,
      'temperature': temperature,
      'humidity': humidity,
      'precipitation': precipitation,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'dewPoint': dewPoint,
      'leafWetness': leafWetness,
      'evapotranspiration': evapotranspiration,
      'condition': condition.name,
      'description': description,
      'sunrise': sunrise?.toIso8601String(),
      'sunset': sunset?.toIso8601String(),
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      locationId: json['locationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: WeatherProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      temperatureMin: json['temperatureMin']?.toDouble(),
      temperatureMax: json['temperatureMax']?.toDouble(),
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      precipitation: json['precipitation']?.toDouble(),
      windSpeed: json['windSpeed']?.toDouble(),
      windDirection: json['windDirection']?.toDouble(),
      dewPoint: json['dewPoint']?.toDouble(),
      leafWetness: json['leafWetness']?.toDouble(),
      evapotranspiration: json['evapotranspiration']?.toDouble(),
      condition: WeatherCondition.values.firstWhere(
        (e) => e.name == json['condition'],
      ),
      description: json['description'] as String?,
      sunrise: json['sunrise'] != null 
          ? DateTime.parse(json['sunrise'] as String)
          : null,
      sunset: json['sunset'] != null 
          ? DateTime.parse(json['sunset'] as String)
          : null,
    );
  }

  static WeatherCondition _parseWeatherCondition(dynamic code) {
    if (code is int) {
      switch (code) {
        case 1000: return WeatherCondition.clear;
        case 1100: case 1101: case 1102: return WeatherCondition.cloudy;
        case 4000: case 4001: case 4200: case 4201: return WeatherCondition.rain;
        case 5000: case 5001: case 5100: case 5101: return WeatherCondition.snow;
        case 2000: case 2100: return WeatherCondition.fog;
        case 8000: return WeatherCondition.storm;
        default: return WeatherCondition.cloudy;
      }
    }
    return WeatherCondition.cloudy;
  }

  static WeatherCondition _parseWeatherConditionMsc(dynamic condition) {
    if (condition is String) {
      final lower = condition.toLowerCase();
      if (lower.contains('clear') || lower.contains('sunny')) {
        return WeatherCondition.clear;
      } else if (lower.contains('rain') || lower.contains('shower')) {
        return WeatherCondition.rain;
      } else if (lower.contains('snow')) {
        return WeatherCondition.snow;
      } else if (lower.contains('fog')) {
        return WeatherCondition.fog;
      } else if (lower.contains('storm') || lower.contains('thunder')) {
        return WeatherCondition.storm;
      }
    }
    return WeatherCondition.cloudy;
  }
}

/// Weather forecast for multiple days
class WeatherForecast {
  final String locationId;
  final DateTime generatedAt;
  final WeatherProvider provider;
  final List<WeatherData> dailyForecasts;
  final Duration cacheDuration;

  WeatherForecast({
    required this.locationId,
    required this.generatedAt,
    required this.provider,
    required this.dailyForecasts,
    this.cacheDuration = const Duration(minutes: 15),
  });

  bool get isExpired {
    return DateTime.now().difference(generatedAt) > cacheDuration;
  }

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      locationId: json['locationId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      provider: WeatherProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      dailyForecasts: (json['dailyForecasts'] as List)
          .map((e) => WeatherData.fromJson(e))
          .toList(),
      cacheDuration: Duration(
        milliseconds: json['cacheDurationMs'] ?? 900000,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'generatedAt': generatedAt.toIso8601String(),
      'provider': provider.name,
      'dailyForecasts': dailyForecasts.map((e) => e.toJson()).toList(),
      'cacheDurationMs': cacheDuration.inMilliseconds,
    };
  }
}

/// Combine capability assessment for harvest conditions
class CombineCapability {
  final String combineSpecId;
  final double moistureToleranceScore; // 1-10 scale
  final double toughCropScore; // 1-10 scale  
  final double reliabilityScore; // 1-10 scale
  final double speedScore; // 1-10 scale
  final double overallScore; // Weighted average
  final Map<CropType, double> cropSpecificScores;
  final DateTime calculatedAt;

  CombineCapability({
    required this.combineSpecId,
    required this.moistureToleranceScore,
    required this.toughCropScore,
    required this.reliabilityScore,
    required this.speedScore,
    required this.overallScore,
    required this.cropSpecificScores,
    required this.calculatedAt,
  });

  factory CombineCapability.fromCombineSpec(CombineSpec spec) {
    // Calculate capability scores based on combine specifications
    final moistureScore = _calculateMoistureScore(spec.moistureTolerance);
    final toughScore = spec.toughCropAbility.rating.toDouble();
    final reliabilityScore = _calculateReliabilityScore(spec);
    final speedScore = _calculateSpeedScore(spec);
    
    // Weighted overall score
    final overallScore = (
      moistureScore * 0.3 +
      toughScore * 0.3 +
      reliabilityScore * 0.2 +
      speedScore * 0.2
    );

    final cropScores = <CropType, double>{};
    for (final crop in CropType.values) {
      cropScores[crop] = _calculateCropSpecificScore(spec, crop);
    }

    return CombineCapability(
      combineSpecId: spec.id,
      moistureToleranceScore: moistureScore,
      toughCropScore: toughScore,
      reliabilityScore: reliabilityScore,
      speedScore: speedScore,
      overallScore: overallScore,
      cropSpecificScores: cropScores,
      calculatedAt: DateTime.now(),
    );
  }

  static double _calculateMoistureScore(MoistureTolerance tolerance) {
    // Higher max moisture tolerance = higher score
    // Scale: 14% = 1, 18% = 8, 22% = 10
    final maxMoisture = tolerance.max;
    if (maxMoisture >= 22) return 10.0;
    if (maxMoisture >= 20) return 9.0;
    if (maxMoisture >= 18) return 8.0;
    if (maxMoisture >= 16) return 6.0;
    if (maxMoisture >= 15) return 4.0;
    if (maxMoisture >= 14) return 2.0;
    return 1.0;
  }

  static double _calculateReliabilityScore(CombineSpec spec) {
    // Based on source data quality and user reports
    double score = 5.0; // Base score
    
    if (spec.sourceData.manufacturerSpecs) score += 2.0;
    if (spec.sourceData.expertValidation) score += 2.0;
    if (spec.sourceData.userReports >= 10) score += 1.0;
    
    return score.clamp(1.0, 10.0);
  }

  static double _calculateSpeedScore(CombineSpec spec) {
    // Placeholder - would be based on actual combine specs
    // For now, use brand-based heuristics
    switch (spec.brand.toLowerCase()) {
      case 'john_deere':
        if (spec.model.contains('x9')) return 9.0;
        if (spec.model.contains('s7')) return 8.0;
        return 7.0;
      case 'case_ih':
        if (spec.model.contains('9250')) return 8.5;
        return 7.5;
      case 'new_holland':
        if (spec.model.contains('cr10')) return 8.0;
        return 7.0;
      case 'claas':
        if (spec.model.contains('lexion')) return 8.5;
        return 7.5;
      default:
        return 6.0;
    }
  }

  static double _calculateCropSpecificScore(CombineSpec spec, CropType crop) {
    double baseScore = spec.toughCropAbility.rating.toDouble();
    
    // Adjust based on crop-specific capabilities
    final cropsHandled = spec.toughCropAbility.crops
        .map((c) => c.toLowerCase())
        .toList();
    
    if (cropsHandled.contains(crop.name)) {
      baseScore += 1.0;
    }
    
    return baseScore.clamp(1.0, 10.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'moistureToleranceScore': moistureToleranceScore,
      'toughCropScore': toughCropScore,
      'reliabilityScore': reliabilityScore,
      'speedScore': speedScore,
      'overallScore': overallScore,
      'cropSpecificScores': cropSpecificScores.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory CombineCapability.fromJson(Map<String, dynamic> json) {
    return CombineCapability(
      combineSpecId: json['combineSpecId'] as String,
      moistureToleranceScore: (json['moistureToleranceScore'] as num).toDouble(),
      toughCropScore: (json['toughCropScore'] as num).toDouble(),
      reliabilityScore: (json['reliabilityScore'] as num).toDouble(),
      speedScore: (json['speedScore'] as num).toDouble(),
      overallScore: (json['overallScore'] as num).toDouble(),
      cropSpecificScores: (json['cropSpecificScores'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
            CropType.values.firstWhere((e) => e.name == key),
            (value as num).toDouble(),
          )),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }
}

/// Risk assessment for different harvest factors
class HarvestRiskAssessment {
  final RiskLevel moistureRisk;
  final RiskLevel frostRisk;
  final RiskLevel heatStressRisk;
  final RiskLevel precipitationRisk;
  final RiskLevel windRisk;
  final RiskLevel overallRisk;
  final Map<String, dynamic> riskFactors;
  final List<String> riskReasons;

  HarvestRiskAssessment({
    required this.moistureRisk,
    required this.frostRisk,
    required this.heatStressRisk,
    required this.precipitationRisk,
    required this.windRisk,
    required this.overallRisk,
    required this.riskFactors,
    required this.riskReasons,
  });

  factory HarvestRiskAssessment.fromWeatherData(
    WeatherData weather,
    CropType crop,
  ) {
    final factors = <String, dynamic>{};
    final reasons = <String>[];

    // Assess moisture risk
    final moistureRisk = _assessMoistureRisk(weather, factors, reasons);
    
    // Assess frost risk
    final frostRisk = _assessFrostRisk(weather, factors, reasons);
    
    // Assess heat stress risk
    final heatStressRisk = _assessHeatStressRisk(weather, factors, reasons);
    
    // Assess precipitation risk
    final precipitationRisk = _assessPrecipitationRisk(weather, factors, reasons);
    
    // Assess wind risk
    final windRisk = _assessWindRisk(weather, factors, reasons);
    
    // Calculate overall risk
    final riskScores = [
      moistureRisk.index,
      frostRisk.index,
      heatStressRisk.index,
      precipitationRisk.index,
      windRisk.index,
    ];
    
    final maxRisk = riskScores.reduce((a, b) => a > b ? a : b);
    final overallRisk = RiskLevel.values[maxRisk];

    return HarvestRiskAssessment(
      moistureRisk: moistureRisk,
      frostRisk: frostRisk,
      heatStressRisk: heatStressRisk,
      precipitationRisk: precipitationRisk,
      windRisk: windRisk,
      overallRisk: overallRisk,
      riskFactors: factors,
      riskReasons: reasons,
    );
  }

  /// Enhanced factory method using crop-specific thresholds
  factory HarvestRiskAssessment.fromWeatherDataAndThresholds(
    WeatherData weather,
    CropType crop,
    WeatherThresholdAnalysis thresholdAnalysis,
  ) {
    final factors = <String, dynamic>{};
    final reasons = <String>[];

    // Convert threshold violations to risk levels
    final moistureRisk = _assessMoistureRiskWithThresholds(weather, thresholdAnalysis, factors, reasons);
    final frostRisk = _assessFrostRiskWithThresholds(weather, thresholdAnalysis, factors, reasons);
    final heatStressRisk = _assessHeatStressRiskWithThresholds(weather, thresholdAnalysis, factors, reasons);
    final precipitationRisk = _assessPrecipitationRiskWithThresholds(weather, thresholdAnalysis, factors, reasons);
    final windRisk = _assessWindRiskWithThresholds(weather, thresholdAnalysis, factors, reasons);
    
    // Calculate overall risk based on threshold analysis
    final overallRisk = _calculateOverallRiskFromThresholds(thresholdAnalysis);
    
    // Add threshold-specific reasons
    for (final violation in thresholdAnalysis.violations) {
      reasons.add('${violation.factor}: ${violation.impact}');
    }
    for (final warning in thresholdAnalysis.warnings) {
      reasons.add('${warning.factor} warning: ${warning.recommendation}');
    }

    // Add threshold analysis to factors
    factors['thresholdViolations'] = thresholdAnalysis.violations.length;
    factors['thresholdWarnings'] = thresholdAnalysis.warnings.length;
    factors['overallRiskScore'] = thresholdAnalysis.overallRiskScore;

    return HarvestRiskAssessment(
      moistureRisk: moistureRisk,
      frostRisk: frostRisk,
      heatStressRisk: heatStressRisk,
      precipitationRisk: precipitationRisk,
      windRisk: windRisk,
      overallRisk: overallRisk,
      riskFactors: factors,
      riskReasons: reasons,
    );
  }

  static RiskLevel _assessMoistureRisk(
    WeatherData weather,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final humidity = weather.humidity ?? 50.0;
    final leafWetness = weather.leafWetness ?? 0.0;
    
    factors['humidity'] = humidity;
    factors['leafWetness'] = leafWetness;

    if (humidity > 85 || leafWetness > 8) {
      reasons.add('High humidity/leaf wetness increases moisture risk');
      return RiskLevel.high;
    } else if (humidity > 75 || leafWetness > 5) {
      reasons.add('Moderate humidity/leaf wetness');
      return RiskLevel.medium;
    } else if (humidity > 60 || leafWetness > 2) {
      return RiskLevel.low;
    }
    
    return RiskLevel.low;
  }

  static RiskLevel _assessFrostRisk(
    WeatherData weather,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final tempMin = weather.temperatureMin ?? weather.temperature ?? 10.0;
    final dewPoint = weather.dewPoint ?? tempMin - 5;
    
    factors['temperatureMin'] = tempMin;
    factors['dewPoint'] = dewPoint;

    if (tempMin <= 0 || dewPoint <= -2) {
      reasons.add('Frost conditions present');
      return RiskLevel.critical;
    } else if (tempMin <= 2 || dewPoint <= 0) {
      reasons.add('Near-frost conditions');
      return RiskLevel.high;
    } else if (tempMin <= 5) {
      reasons.add('Cool temperatures may affect harvest');
      return RiskLevel.medium;
    }
    
    return RiskLevel.low;
  }

  static RiskLevel _assessHeatStressRisk(
    WeatherData weather,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final tempMax = weather.temperatureMax ?? weather.temperature ?? 20.0;
    
    factors['temperatureMax'] = tempMax;

    if (tempMax >= 35) {
      reasons.add('Extreme heat may stress equipment and crops');
      return RiskLevel.high;
    } else if (tempMax >= 30) {
      reasons.add('High temperatures increase equipment stress');
      return RiskLevel.medium;
    }
    
    return RiskLevel.low;
  }

  static RiskLevel _assessPrecipitationRisk(
    WeatherData weather,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final precipitation = weather.precipitation ?? 0.0;
    
    factors['precipitation'] = precipitation;

    if (precipitation > 10) {
      reasons.add('Heavy precipitation prevents harvest');
      return RiskLevel.critical;
    } else if (precipitation > 2) {
      reasons.add('Light precipitation may delay harvest');
      return RiskLevel.high;
    } else if (precipitation > 0.5) {
      reasons.add('Minimal precipitation risk');
      return RiskLevel.medium;
    }
    
    return RiskLevel.low;
  }

  static RiskLevel _assessWindRisk(
    WeatherData weather,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final windSpeed = weather.windSpeed ?? 0.0;
    
    factors['windSpeed'] = windSpeed;

    if (windSpeed > 50) {
      reasons.add('Dangerous wind speeds for harvest operations');
      return RiskLevel.critical;
    } else if (windSpeed > 30) {
      reasons.add('High winds may affect harvest efficiency');
      return RiskLevel.high;
    } else if (windSpeed > 20) {
      reasons.add('Moderate winds present');
      return RiskLevel.medium;
    }
    
    return RiskLevel.low;
  }

  /// Assess risks using crop-specific thresholds
  static RiskLevel _assessMoistureRiskWithThresholds(
    WeatherData weather,
    WeatherThresholdAnalysis analysis,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    final humidity = weather.humidity ?? 50.0;
    final leafWetness = weather.leafWetness ?? 0.0;
    
    factors['humidity'] = humidity;
    factors['leafWetness'] = leafWetness;

    // Check for humidity-related violations
    final humidityViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('humidity'))
        .toList();
    
    if (humidityViolations.isNotEmpty) {
      final severity = humidityViolations.first.severity;
      switch (severity) {
        case 'critical':
          return RiskLevel.critical;
        case 'high':
          return RiskLevel.high;
        case 'medium':
          return RiskLevel.medium;
        default:
          return RiskLevel.low;
      }
    }

    // Fall back to original logic if no threshold violations
    return _assessMoistureRisk(weather, factors, reasons);
  }

  static RiskLevel _assessFrostRiskWithThresholds(
    WeatherData weather,
    WeatherThresholdAnalysis analysis,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    // Check for frost-related violations
    final frostViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('frost'))
        .toList();
    
    if (frostViolations.isNotEmpty) {
      final severity = frostViolations.first.severity;
      switch (severity) {
        case 'critical':
          return RiskLevel.critical;
        case 'high':
          return RiskLevel.high;
        case 'medium':
          return RiskLevel.medium;
        default:
          return RiskLevel.low;
      }
    }

    return _assessFrostRisk(weather, factors, reasons);
  }

  static RiskLevel _assessHeatStressRiskWithThresholds(
    WeatherData weather,
    WeatherThresholdAnalysis analysis,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    // Check for heat stress violations
    final heatViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('heat'))
        .toList();
    
    if (heatViolations.isNotEmpty) {
      final severity = heatViolations.first.severity;
      switch (severity) {
        case 'critical':
          return RiskLevel.critical;
        case 'high':
          return RiskLevel.high;
        case 'medium':
          return RiskLevel.medium;
        default:
          return RiskLevel.low;
      }
    }

    return _assessHeatStressRisk(weather, factors, reasons);
  }

  static RiskLevel _assessPrecipitationRiskWithThresholds(
    WeatherData weather,
    WeatherThresholdAnalysis analysis,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    // Check for precipitation violations
    final precipViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('precipitation') ||
                     v.factor.toLowerCase().contains('rain'))
        .toList();
    
    if (precipViolations.isNotEmpty) {
      final severity = precipViolations.first.severity;
      switch (severity) {
        case 'critical':
          return RiskLevel.critical;
        case 'high':
          return RiskLevel.high;
        case 'medium':
          return RiskLevel.medium;
        default:
          return RiskLevel.low;
      }
    }

    return _assessPrecipitationRisk(weather, factors, reasons);
  }

  static RiskLevel _assessWindRiskWithThresholds(
    WeatherData weather,
    WeatherThresholdAnalysis analysis,
    Map<String, dynamic> factors,
    List<String> reasons,
  ) {
    // Check for wind-related violations
    final windViolations = analysis.violations
        .where((v) => v.factor.toLowerCase().contains('wind'))
        .toList();
    
    if (windViolations.isNotEmpty) {
      final severity = windViolations.first.severity;
      switch (severity) {
        case 'critical':
          return RiskLevel.critical;
        case 'high':
          return RiskLevel.high;
        case 'medium':
          return RiskLevel.medium;
        default:
          return RiskLevel.low;
      }
    }

    return _assessWindRisk(weather, factors, reasons);
  }

  static RiskLevel _calculateOverallRiskFromThresholds(
    WeatherThresholdAnalysis analysis,
  ) {
    // Critical violations = critical risk
    final criticalViolations = analysis.violations
        .where((v) => v.severity == 'critical')
        .length;
    if (criticalViolations > 0) {
      return RiskLevel.critical;
    }

    // Multiple high violations = high risk  
    final highViolations = analysis.violations
        .where((v) => v.severity == 'high')
        .length;
    if (highViolations > 1) {
      return RiskLevel.high;
    } else if (highViolations > 0) {
      return RiskLevel.high;
    }

    // Medium violations or warnings = medium risk
    final mediumViolations = analysis.violations
        .where((v) => v.severity == 'medium')
        .length;
    if (mediumViolations > 0 || analysis.warnings.isNotEmpty) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }

  Map<String, dynamic> toJson() {
    return {
      'moistureRisk': moistureRisk.name,
      'frostRisk': frostRisk.name,
      'heatStressRisk': heatStressRisk.name,
      'precipitationRisk': precipitationRisk.name,
      'windRisk': windRisk.name,
      'overallRisk': overallRisk.name,
      'riskFactors': riskFactors,
      'riskReasons': riskReasons,
    };
  }

  factory HarvestRiskAssessment.fromJson(Map<String, dynamic> json) {
    return HarvestRiskAssessment(
      moistureRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['moistureRisk'],
      ),
      frostRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['frostRisk'],
      ),
      heatStressRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['heatStressRisk'],
      ),
      precipitationRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['precipitationRisk'],
      ),
      windRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['windRisk'],
      ),
      overallRisk: RiskLevel.values.firstWhere(
        (e) => e.name == json['overallRisk'],
      ),
      riskFactors: Map<String, dynamic>.from(json['riskFactors']),
      riskReasons: List<String>.from(json['riskReasons']),
    );
  }
}

/// Optimal harvest window recommendation
class HarvestWindow {
  final DateTime startTime;
  final DateTime endTime;
  final HarvestRecommendation recommendation;
  final double confidenceScore; // 0-1 scale
  final double combineWeatherMultiplier; // Combine capability × weather readiness
  final HarvestRiskAssessment riskAssessment;
  final Map<String, dynamic> conditions;
  final List<String> reasons;
  final int priority; // 1-10, higher = better window

  HarvestWindow({
    required this.startTime,
    required this.endTime,
    required this.recommendation,
    required this.confidenceScore,
    required this.combineWeatherMultiplier,
    required this.riskAssessment,
    required this.conditions,
    required this.reasons,
    required this.priority,
  });

  Duration get duration => endTime.difference(startTime);

  bool get isOptimal => recommendation == HarvestRecommendation.optimal;
  bool get isAcceptable => recommendation == HarvestRecommendation.acceptable;
  bool get shouldAvoid => recommendation == HarvestRecommendation.avoid;

  factory HarvestWindow.create({
    required DateTime startTime,
    required DateTime endTime,
    required WeatherData weather,
    required CombineCapability combineCapability,
    required CropType crop,
  }) {
    final riskAssessment = HarvestRiskAssessment.fromWeatherData(weather, crop);
    final conditions = <String, dynamic>{};
    final reasons = <String>[];

    // Calculate weather readiness (0-1 scale)
    final weatherReadiness = _calculateWeatherReadiness(weather, riskAssessment);
    
    // Get combine capability for this crop (0-1 scale)
    final combineReadiness = combineCapability.cropSpecificScores[crop]! / 10.0;
    
    // Calculate combine-weather multiplier
    final multiplier = combineReadiness * weatherReadiness;
    
    // Determine recommendation based on multiplier and risk
    final recommendation = _determineRecommendation(multiplier, riskAssessment);
    
    // Calculate confidence score
    final confidenceScore = _calculateConfidence(
      multiplier,
      riskAssessment,
      combineCapability,
    );

    // Calculate priority
    final priority = (multiplier * 10).round();

    // Add condition details
    conditions['weatherReadiness'] = weatherReadiness;
    conditions['combineReadiness'] = combineReadiness;
    conditions['temperature'] = weather.temperature;
    conditions['humidity'] = weather.humidity;
    conditions['precipitation'] = weather.precipitation;
    conditions['windSpeed'] = weather.windSpeed;

    // Add reasoning
    reasons.addAll(riskAssessment.riskReasons);
    _addRecommendationReasons(reasons, recommendation, multiplier, combineCapability);

    return HarvestWindow(
      startTime: startTime,
      endTime: endTime,
      recommendation: recommendation,
      confidenceScore: confidenceScore,
      combineWeatherMultiplier: multiplier,
      riskAssessment: riskAssessment,
      conditions: conditions,
      reasons: reasons,
      priority: priority,
    );
  }

  static double _calculateWeatherReadiness(
    WeatherData weather,
    HarvestRiskAssessment riskAssessment,
  ) {
    // Start with base readiness
    double readiness = 1.0;

    // Reduce based on risk levels
    switch (riskAssessment.overallRisk) {
      case RiskLevel.critical:
        readiness *= 0.1;
        break;
      case RiskLevel.high:
        readiness *= 0.3;
        break;
      case RiskLevel.medium:
        readiness *= 0.7;
        break;
      case RiskLevel.low:
        // No reduction
        break;
    }

    // Adjust for specific conditions
    if (weather.precipitation != null && weather.precipitation! > 0) {
      readiness *= (1.0 - (weather.precipitation! / 20.0)).clamp(0.0, 1.0);
    }

    return readiness.clamp(0.0, 1.0);
  }

  static HarvestRecommendation _determineRecommendation(
    double multiplier,
    HarvestRiskAssessment riskAssessment,
  ) {
    // Avoid if critical risk
    if (riskAssessment.overallRisk == RiskLevel.critical) {
      return HarvestRecommendation.avoid;
    }

    // Use multiplier to determine recommendation
    if (multiplier >= 0.8) {
      return HarvestRecommendation.optimal;
    } else if (multiplier >= 0.6) {
      return HarvestRecommendation.acceptable;
    } else if (multiplier >= 0.4) {
      return HarvestRecommendation.marginal;
    } else {
      return HarvestRecommendation.avoid;
    }
  }

  static double _calculateConfidence(
    double multiplier,
    HarvestRiskAssessment riskAssessment,
    CombineCapability capability,
  ) {
    // Base confidence from multiplier
    double confidence = multiplier;

    // Adjust based on risk assessment certainty
    if (riskAssessment.riskReasons.isEmpty) {
      confidence *= 0.8; // Reduce if no clear reasoning
    }

    // Adjust based on combine capability data quality
    if (capability.reliabilityScore > 8) {
      confidence *= 1.1;
    } else if (capability.reliabilityScore < 5) {
      confidence *= 0.9;
    }

    return confidence.clamp(0.0, 1.0);
  }

  static void _addRecommendationReasons(
    List<String> reasons,
    HarvestRecommendation recommendation,
    double multiplier,
    CombineCapability capability,
  ) {
    switch (recommendation) {
      case HarvestRecommendation.optimal:
        reasons.add('Excellent conditions for harvest operations');
        if (capability.overallScore > 8) {
          reasons.add('High-capability combine well-suited for conditions');
        }
        break;
      case HarvestRecommendation.acceptable:
        reasons.add('Good conditions for harvest with minor considerations');
        break;
      case HarvestRecommendation.marginal:
        reasons.add('Marginal conditions - consider equipment capabilities');
        if (capability.overallScore > 7) {
          reasons.add('Capable combine may handle marginal conditions');
        }
        break;
      case HarvestRecommendation.avoid:
        reasons.add('Poor conditions for harvest operations');
        break;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'recommendation': recommendation.name,
      'confidenceScore': confidenceScore,
      'combineWeatherMultiplier': combineWeatherMultiplier,
      'riskAssessment': riskAssessment.toJson(),
      'conditions': conditions,
      'reasons': reasons,
      'priority': priority,
    };
  }

  factory HarvestWindow.fromJson(Map<String, dynamic> json) {
    return HarvestWindow(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      recommendation: HarvestRecommendation.values.firstWhere(
        (e) => e.name == json['recommendation'],
      ),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      combineWeatherMultiplier: (json['combineWeatherMultiplier'] as num).toDouble(),
      riskAssessment: HarvestRiskAssessment.fromJson(json['riskAssessment']),
      conditions: Map<String, dynamic>.from(json['conditions']),
      reasons: List<String>.from(json['reasons']),
      priority: json['priority'] as int,
    );
  }
}

/// Cost tracking for API calls
/// Equipment-specific performance factors that modify harvest capabilities
class EquipmentFactor {
  final String factorId;
  final String factorName;
  final EquipmentFactorType type;
  final double baseValue;
  final double adjustedValue;
  final FactorModifierReason reason;
  final Map<String, dynamic> modifierDetails;
  final DateTime calculatedAt;
  final double confidence; // 0-1 scale

  EquipmentFactor({
    required this.factorId,
    required this.factorName,
    required this.type,
    required this.baseValue,
    required this.adjustedValue,
    required this.reason,
    this.modifierDetails = const {},
    required this.calculatedAt,
    required this.confidence,
  });

  /// Calculate the performance impact as a multiplier (0.5-1.5)
  double get performanceMultiplier {
    final ratio = adjustedValue / baseValue;
    return ratio.clamp(0.5, 1.5);
  }

  /// Check if this factor improves performance
  bool get improvesPerformance => adjustedValue > baseValue;

  /// Check if this factor reduces performance
  bool get reducesPerformance => adjustedValue < baseValue;

  factory EquipmentFactor.fromCombineSpec({
    required CombineSpec spec,
    required EquipmentFactorType factorType,
    required WeatherData? currentWeather,
    required CropType crop,
  }) {
    switch (factorType) {
      case EquipmentFactorType.moistureHandling:
        return _createMoistureHandlingFactor(spec, currentWeather, crop);
      case EquipmentFactorType.speedEfficiency:
        return _createSpeedEfficiencyFactor(spec, currentWeather, crop);
      case EquipmentFactorType.fuelConsumption:
        return _createFuelConsumptionFactor(spec, currentWeather, crop);
      case EquipmentFactorType.reliabilityRating:
        return _createReliabilityFactor(spec, currentWeather, crop);
      case EquipmentFactorType.maintenanceComplexity:
        return _createMaintenanceFactor(spec, currentWeather, crop);
      case EquipmentFactorType.weatherAdaptability:
        return _createWeatherAdaptabilityFactor(spec, currentWeather, crop);
    }
  }

  static EquipmentFactor _createMoistureHandlingFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    final baseValue = (spec.moistureTolerance.max - spec.moistureTolerance.min) / 2;
    double adjustedValue = baseValue;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Adjust based on current weather conditions
    if (weather != null) {
      final humidity = weather.humidity ?? 50.0;
      final leafWetness = weather.leafWetness ?? 0.0;

      if (humidity > 80 || leafWetness > 6) {
        // High moisture conditions - some combines handle better
        if (spec.toughCropAbility.handlesHighMoisture) {
          adjustedValue *= 1.2;
          reason = FactorModifierReason.weatherOptimized;
          details['moistureAdvantage'] = 'Combine designed for high moisture';
        } else {
          adjustedValue *= 0.8;
          reason = FactorModifierReason.weatherLimited;
          details['moistureChallenge'] = 'High moisture conditions reduce efficiency';
        }
      }

      details['currentHumidity'] = humidity;
      details['leafWetness'] = leafWetness;
    }

    // Crop-specific adjustments
    if (spec.toughCropAbility.cropSpecificRatings?.containsKey(crop.name) == true) {
      final cropRating = spec.toughCropAbility.cropSpecificRatings![crop.name]!;
      adjustedValue *= (cropRating / 10.0).clamp(0.8, 1.2);
      details['cropSpecificRating'] = cropRating;
    }

    return EquipmentFactor(
      factorId: 'moisture_${spec.id}',
      factorName: 'Moisture Handling Capability',
      type: EquipmentFactorType.moistureHandling,
      baseValue: baseValue,
      adjustedValue: adjustedValue,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static EquipmentFactor _createSpeedEfficiencyFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    final baseSpeed = spec.harvestCapabilities?.operatingSpeedKmh ?? 8.0;
    double adjustedSpeed = baseSpeed;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Weather adjustments
    if (weather != null) {
      final windSpeed = weather.windSpeed ?? 0.0;
      final precipitation = weather.precipitation ?? 0.0;

      if (windSpeed > 20) {
        adjustedSpeed *= 0.9;
        reason = FactorModifierReason.weatherLimited;
        details['windImpact'] = 'High winds reduce operating speed';
      }

      if (precipitation > 0.5) {
        adjustedSpeed *= 0.7;
        reason = FactorModifierReason.weatherLimited;
        details['precipitationImpact'] = 'Wet conditions require slower speeds';
      }

      details['windSpeed'] = windSpeed;
      details['precipitation'] = precipitation;
    }

    // Crop density adjustments
    switch (crop) {
      case CropType.corn:
        if (spec.toughCropAbility.rating >= 8) {
          adjustedSpeed *= 1.1;
          details['cropAdvantage'] = 'High-capacity combine handles corn well';
        }
        break;
      case CropType.soybeans:
        adjustedSpeed *= 1.05; // Generally easier to harvest
        break;
      case CropType.wheat:
        if (spec.toughCropAbility.handlesLodgedCrops) {
          adjustedSpeed *= 1.1;
          details['lodgedCropCapability'] = 'Equipped for lodged wheat';
        }
        break;
      default:
        break;
    }

    return EquipmentFactor(
      factorId: 'speed_${spec.id}',
      factorName: 'Speed Efficiency',
      type: EquipmentFactorType.speedEfficiency,
      baseValue: baseSpeed,
      adjustedValue: adjustedSpeed,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static EquipmentFactor _createFuelConsumptionFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    final baseFuel = spec.harvestCapabilities?.fuelConsumptionLh ?? 45.0;
    double adjustedFuel = baseFuel;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Weather impacts on fuel consumption
    if (weather != null) {
      final temperature = weather.temperature ?? 20.0;
      final humidity = weather.humidity ?? 50.0;

      // Cold weather increases fuel consumption
      if (temperature < 5) {
        adjustedFuel *= 1.15;
        reason = FactorModifierReason.weatherLimited;
        details['coldWeatherImpact'] = 'Cold conditions increase fuel use';
      }

      // High humidity may require more power
      if (humidity > 85) {
        adjustedFuel *= 1.1;
        details['humidityImpact'] = 'High humidity increases power requirements';
      }

      details['temperature'] = temperature;
      details['humidity'] = humidity;
    }

    // Crop-specific fuel requirements
    switch (crop) {
      case CropType.corn:
        adjustedFuel *= 1.1; // Corn typically requires more power
        details['cropFactor'] = 'Corn harvest requires additional power';
        break;
      case CropType.soybeans:
        adjustedFuel *= 0.95; // Soybeans are generally easier
        break;
      default:
        break;
    }

    return EquipmentFactor(
      factorId: 'fuel_${spec.id}',
      factorName: 'Fuel Consumption',
      type: EquipmentFactorType.fuelConsumption,
      baseValue: baseFuel,
      adjustedValue: adjustedFuel,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static EquipmentFactor _createReliabilityFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    final baseReliability = spec.harvestCapabilities?.reliabilityRating.toDouble() ?? 7.0;
    double adjustedReliability = baseReliability;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Weather stress on reliability
    if (weather != null) {
      final temperature = weather.temperature ?? 20.0;
      final humidity = weather.humidity ?? 50.0;
      final precipitation = weather.precipitation ?? 0.0;

      // Extreme temperatures affect reliability
      if (temperature > 35 || temperature < -5) {
        adjustedReliability *= 0.9;
        reason = FactorModifierReason.weatherLimited;
        details['temperatureStress'] = 'Extreme temperatures affect reliability';
      }

      // High moisture increases breakdown risk
      if (humidity > 90 || precipitation > 2) {
        adjustedReliability *= 0.85;
        reason = FactorModifierReason.weatherLimited;
        details['moistureRisk'] = 'High moisture increases breakdown risk';
      }

      details['temperature'] = temperature;
      details['humidity'] = humidity;
      details['precipitation'] = precipitation;
    }

    // Source data quality affects confidence in reliability
    if (spec.sourceData.expertValidation && spec.sourceData.userReports > 5) {
      adjustedReliability *= 1.05;
      details['dataQuality'] = 'High-quality reliability data available';
    }

    return EquipmentFactor(
      factorId: 'reliability_${spec.id}',
      factorName: 'Reliability Rating',
      type: EquipmentFactorType.reliabilityRating,
      baseValue: baseReliability,
      adjustedValue: adjustedReliability,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static EquipmentFactor _createMaintenanceFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    final baseComplexity = spec.harvestCapabilities?.maintenanceComplexity.toDouble() ?? 6.0;
    double adjustedComplexity = baseComplexity;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Weather affects maintenance needs
    if (weather != null) {
      final humidity = weather.humidity ?? 50.0;
      final precipitation = weather.precipitation ?? 0.0;

      // High moisture increases maintenance complexity
      if (humidity > 85 || precipitation > 1) {
        adjustedComplexity *= 1.2;
        reason = FactorModifierReason.weatherLimited;
        details['moistureMaintenanceImpact'] = 'High moisture increases maintenance needs';
      }

      details['humidity'] = humidity;
      details['precipitation'] = precipitation;
    }

    // Crop residue affects cleaning and maintenance
    switch (crop) {
      case CropType.corn:
        adjustedComplexity *= 1.15; // Corn creates more residue
        details['cropMaintenanceImpact'] = 'Corn harvest increases cleaning requirements';
        break;
      case CropType.soybeans:
        adjustedComplexity *= 0.95; // Cleaner harvest
        break;
      default:
        break;
    }

    return EquipmentFactor(
      factorId: 'maintenance_${spec.id}',
      factorName: 'Maintenance Complexity',
      type: EquipmentFactorType.maintenanceComplexity,
      baseValue: baseComplexity,
      adjustedValue: adjustedComplexity,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static EquipmentFactor _createWeatherAdaptabilityFactor(
    CombineSpec spec,
    WeatherData? weather,
    CropType crop,
  ) {
    // Calculate base adaptability from combine capabilities
    double baseAdaptability = 7.0;
    
    if (spec.harvestCapabilities?.hasAutomaticAdjustments == true) {
      baseAdaptability += 1.0;
    }
    if (spec.toughCropAbility.handlesHighMoisture) {
      baseAdaptability += 0.5;
    }
    if (spec.toughCropAbility.handlesLodgedCrops) {
      baseAdaptability += 0.5;
    }

    double adjustedAdaptability = baseAdaptability;
    final details = <String, dynamic>{};
    var reason = FactorModifierReason.optimal;

    // Current weather challenges
    if (weather != null) {
      final riskAssessment = HarvestRiskAssessment.fromWeatherData(weather, crop);
      
      switch (riskAssessment.overallRisk) {
        case RiskLevel.critical:
          adjustedAdaptability *= 0.6;
          reason = FactorModifierReason.weatherLimited;
          details['riskLevel'] = 'Critical weather conditions';
          break;
        case RiskLevel.high:
          adjustedAdaptability *= 0.8;
          reason = FactorModifierReason.weatherLimited;
          details['riskLevel'] = 'High risk weather conditions';
          break;
        case RiskLevel.medium:
          adjustedAdaptability *= 0.9;
          break;
        case RiskLevel.low:
          if (spec.harvestCapabilities?.hasAutomaticAdjustments == true) {
            adjustedAdaptability *= 1.1;
            reason = FactorModifierReason.weatherOptimized;
            details['advantageReason'] = 'Automatic adjustments optimize for conditions';
          }
          break;
      }

      details['weatherRiskFactors'] = riskAssessment.riskReasons;
    }

    return EquipmentFactor(
      factorId: 'adaptability_${spec.id}',
      factorName: 'Weather Adaptability',
      type: EquipmentFactorType.weatherAdaptability,
      baseValue: baseAdaptability,
      adjustedValue: adjustedAdaptability,
      reason: reason,
      modifierDetails: details,
      calculatedAt: DateTime.now(),
      confidence: _calculateConfidence(spec, weather),
    );
  }

  static double _calculateConfidence(CombineSpec spec, WeatherData? weather) {
    double confidence = 0.7; // Base confidence

    // Data quality adjustments
    if (spec.sourceData.manufacturerSpecs) confidence += 0.1;
    if (spec.sourceData.expertValidation) confidence += 0.1;
    if (spec.sourceData.userReports > 10) confidence += 0.1;

    // Weather data quality
    if (weather != null) {
      confidence += 0.1; // Real weather data available
    }

    return confidence.clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'factorId': factorId,
      'factorName': factorName,
      'type': type.name,
      'baseValue': baseValue,
      'adjustedValue': adjustedValue,
      'reason': reason.name,
      'modifierDetails': modifierDetails,
      'calculatedAt': calculatedAt.toIso8601String(),
      'confidence': confidence,
      'performanceMultiplier': performanceMultiplier,
    };
  }

  factory EquipmentFactor.fromJson(Map<String, dynamic> json) {
    return EquipmentFactor(
      factorId: json['factorId'] as String,
      factorName: json['factorName'] as String,
      type: EquipmentFactorType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      baseValue: (json['baseValue'] as num).toDouble(),
      adjustedValue: (json['adjustedValue'] as num).toDouble(),
      reason: FactorModifierReason.values.firstWhere(
        (e) => e.name == json['reason'],
      ),
      modifierDetails: Map<String, dynamic>.from(json['modifierDetails']),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// Equipment factor types
enum EquipmentFactorType {
  moistureHandling,
  speedEfficiency,
  fuelConsumption,
  reliabilityRating,
  maintenanceComplexity,
  weatherAdaptability,
}

/// Reasons for factor modifications
enum FactorModifierReason {
  optimal,
  weatherOptimized,
  weatherLimited,
  cropOptimized,
  cropLimited,
  equipmentAdvantage,
  equipmentLimitation,
  dataLimited,
}

/// Equipment factor analysis for a combine
class EquipmentFactorAnalysis {
  final String combineSpecId;
  final List<EquipmentFactor> factors;
  final double overallPerformanceMultiplier;
  final Map<EquipmentFactorType, double> factorWeights;
  final DateTime analyzedAt;
  final String? weatherLocationId;
  final CropType crop;

  EquipmentFactorAnalysis({
    required this.combineSpecId,
    required this.factors,
    required this.overallPerformanceMultiplier,
    this.factorWeights = const {
      EquipmentFactorType.moistureHandling: 0.25,
      EquipmentFactorType.speedEfficiency: 0.20,
      EquipmentFactorType.fuelConsumption: 0.15,
      EquipmentFactorType.reliabilityRating: 0.20,
      EquipmentFactorType.maintenanceComplexity: 0.10,
      EquipmentFactorType.weatherAdaptability: 0.10,
    },
    required this.analyzedAt,
    this.weatherLocationId,
    required this.crop,
  });

  /// Get factor by type
  EquipmentFactor? getFactorByType(EquipmentFactorType type) {
    final filtered = factors.where((f) => f.type == type);
    return filtered.isEmpty ? null : filtered.first;
  }

  /// Get factors that improve performance
  List<EquipmentFactor> get performanceAdvantages {
    return factors.where((f) => f.improvesPerformance).toList();
  }

  /// Get factors that reduce performance
  List<EquipmentFactor> get performanceLimitations {
    return factors.where((f) => f.reducesPerformance).toList();
  }

  /// Calculate weighted overall multiplier
  static double calculateOverallMultiplier(
    List<EquipmentFactor> factors,
    Map<EquipmentFactorType, double> weights,
  ) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final factor in factors) {
      final weight = weights[factor.type] ?? 0.1;
      weightedSum += factor.performanceMultiplier * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 1.0;
  }

  factory EquipmentFactorAnalysis.analyze({
    required CombineSpec spec,
    required WeatherData? weather,
    required CropType crop,
    String? weatherLocationId,
    Map<EquipmentFactorType, double>? customWeights,
  }) {
    final factors = <EquipmentFactor>[];

    // Generate all equipment factors
    for (final factorType in EquipmentFactorType.values) {
      final factor = EquipmentFactor.fromCombineSpec(
        spec: spec,
        factorType: factorType,
        currentWeather: weather,
        crop: crop,
      );
      factors.add(factor);
    }

    final weights = customWeights ?? const {
      EquipmentFactorType.moistureHandling: 0.25,
      EquipmentFactorType.speedEfficiency: 0.20,
      EquipmentFactorType.fuelConsumption: 0.15,
      EquipmentFactorType.reliabilityRating: 0.20,
      EquipmentFactorType.maintenanceComplexity: 0.10,
      EquipmentFactorType.weatherAdaptability: 0.10,
    };

    final overallMultiplier = calculateOverallMultiplier(factors, weights);

    return EquipmentFactorAnalysis(
      combineSpecId: spec.id,
      factors: factors,
      overallPerformanceMultiplier: overallMultiplier,
      factorWeights: weights,
      analyzedAt: DateTime.now(),
      weatherLocationId: weatherLocationId,
      crop: crop,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'combineSpecId': combineSpecId,
      'factors': factors.map((f) => f.toJson()).toList(),
      'overallPerformanceMultiplier': overallPerformanceMultiplier,
      'factorWeights': factorWeights.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'analyzedAt': analyzedAt.toIso8601String(),
      'weatherLocationId': weatherLocationId,
      'crop': crop.name,
    };
  }

  factory EquipmentFactorAnalysis.fromJson(Map<String, dynamic> json) {
    return EquipmentFactorAnalysis(
      combineSpecId: json['combineSpecId'] as String,
      factors: (json['factors'] as List)
          .map((f) => EquipmentFactor.fromJson(f))
          .toList(),
      overallPerformanceMultiplier: (json['overallPerformanceMultiplier'] as num).toDouble(),
      factorWeights: (json['factorWeights'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          EquipmentFactorType.values.firstWhere((e) => e.name == key),
          (value as num).toDouble(),
        ),
      ),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      weatherLocationId: json['weatherLocationId'] as String?,
      crop: CropType.values.firstWhere((e) => e.name == json['crop']),
    );
  }
}

class ApiCallCost {
  final WeatherProvider provider;
  final DateTime timestamp;
  final String endpoint;
  final int callCount;
  final double estimatedCost;
  final String locationId;
  final bool fromCache;

  ApiCallCost({
    required this.provider,
    required this.timestamp,
    required this.endpoint,
    required this.callCount,
    required this.estimatedCost,
    required this.locationId,
    required this.fromCache,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'timestamp': timestamp.toIso8601String(),
      'endpoint': endpoint,
      'callCount': callCount,
      'estimatedCost': estimatedCost,
      'locationId': locationId,
      'fromCache': fromCache,
    };
  }

  factory ApiCallCost.fromJson(Map<String, dynamic> json) {
    return ApiCallCost(
      provider: WeatherProvider.values.firstWhere(
        (e) => e.name == json['provider'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      endpoint: json['endpoint'] as String,
      callCount: json['callCount'] as int,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      locationId: json['locationId'] as String,
      fromCache: json['fromCache'] as bool,
    );
  }
}