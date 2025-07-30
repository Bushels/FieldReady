/**
 * Crop Threshold Service for FieldReady
 * Integrates crop-specific harvest thresholds with weather predictions
 * Based on scientifically-validated thresholds from CROP_THRESHOLDS.md
 */

import 'dart:math';
import '../models/harvest_models.dart';

/// Crop-specific threshold configurations
class CropThresholds {
  final CropType crop;
  final MoistureThresholds moisture;
  final WeatherThresholds weather;
  final QualityFactors quality;
  final Map<String, dynamic> specificFactors;

  const CropThresholds({
    required this.crop,
    required this.moisture,
    required this.weather,
    required this.quality,
    this.specificFactors = const {},
  });
}

class MoistureThresholds {
  final double? minOptimal;
  final double? maxOptimal;
  final double? storageMax;
  final double? criticalMax;
  final String unit;

  const MoistureThresholds({
    this.minOptimal,
    this.maxOptimal,
    this.storageMax,
    this.criticalMax,
    this.unit = '%',
  });
}

class WeatherThresholds {
  final TemperatureThreshold? frost;
  final TemperatureThreshold? heatStress;
  final WindThreshold? wind;
  final PrecipitationThreshold? rain;
  final HumidityThreshold? humidity;
  final Map<String, dynamic> other;

  const WeatherThresholds({
    this.frost,
    this.heatStress,
    this.wind,
    this.rain,
    this.humidity,
    this.other = const {},
  });
}

class TemperatureThreshold {
  final double threshold;
  final String unit;
  final String description;
  final String impact;

  const TemperatureThreshold({
    required this.threshold,
    this.unit = '°C',
    required this.description,
    required this.impact,
  });
}

class WindThreshold {
  final double shatterThreshold;
  final double operationalLimit;
  final String unit;
  final bool moistureDependent;

  const WindThreshold({
    required this.shatterThreshold,
    required this.operationalLimit,
    this.unit = 'km/h',
    this.moistureDependent = false,
  });
}

class PrecipitationThreshold {
  final double lightRain;
  final double heavyRain;
  final double criticalAmount;
  final int durationHours;
  final String unit;

  const PrecipitationThreshold({
    required this.lightRain,
    required this.heavyRain,
    required this.criticalAmount,
    this.durationHours = 24,
    this.unit = 'mm',
  });
}

class HumidityThreshold {
  final double optimal;
  final double high;
  final double critical;
  final String unit;

  const HumidityThreshold({
    required this.optimal,
    required this.high,
    required this.critical,
    this.unit = '%',
  });
}

class QualityFactors {
  final Map<String, ThresholdRange> factors;
  final Map<String, String> impacts;

  const QualityFactors({
    required this.factors,
    this.impacts = const {},
  });
}

class ThresholdRange {
  final double? min;
  final double? max;
  final double? optimal;
  final String unit;

  const ThresholdRange({
    this.min,
    this.max,
    this.optimal,
    required this.unit,
  });
}

/// Weather threshold analysis result
class WeatherThresholdAnalysis {
  final CropType crop;
  final List<ThresholdViolation> violations;
  final List<ThresholdWarning> warnings;
  final List<ThresholdOpportunity> opportunities;
  final double overallRiskScore; // 0-1 scale
  final Map<String, dynamic> analysisDetails;
  final DateTime analyzedAt;

  WeatherThresholdAnalysis({
    required this.crop,
    required this.violations,
    required this.warnings,
    required this.opportunities,
    required this.overallRiskScore,
    required this.analysisDetails,
    required this.analyzedAt,
  });
}

class ThresholdViolation {
  final String factor;
  final double currentValue;
  final double threshold;
  final String severity; // 'critical', 'high', 'medium'
  final String impact;
  final String recommendation;

  ThresholdViolation({
    required this.factor,
    required this.currentValue,
    required this.threshold,
    required this.severity,
    required this.impact,
    required this.recommendation,
  });
}

class ThresholdWarning {
  final String factor;
  final double currentValue;
  final double threshold;
  final String timeToViolation;
  final String recommendation;

  ThresholdWarning({
    required this.factor,
    required this.currentValue,
    required this.threshold,
    required this.timeToViolation,
    required this.recommendation,
  });
}

class ThresholdOpportunity {
  final String factor;
  final double currentValue;
  final String advantage;
  final String recommendation;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  ThresholdOpportunity({
    required this.factor,
    required this.currentValue,
    required this.advantage,
    required this.recommendation,
    this.windowStart,
    this.windowEnd,
  });
}

/// Main service for crop threshold integration
class CropThresholdService {
  static const Map<CropType, CropThresholds> _cropThresholds = {
    CropType.wheat: CropThresholds(
      crop: CropType.wheat,
      moisture: MoistureThresholds(
        minOptimal: 14.0,
        maxOptimal: 20.0,
        storageMax: 14.5,
        criticalMax: 25.0,
      ),
      weather: WeatherThresholds(
        frost: TemperatureThreshold(
          threshold: -2.0,
          description: 'Kernel damage risk',
          impact: 'Quality degradation',
        ),
        heatStress: TemperatureThreshold(
          threshold: 30.0,
          description: 'Protein degradation accelerates',
          impact: 'Quality loss',
        ),
        wind: WindThreshold(
          shatterThreshold: 30.0,
          operationalLimit: 25.0,
          moistureDependent: true,
        ),
        rain: PrecipitationThreshold(
          lightRain: 5.0,
          heavyRain: 15.0,
          criticalAmount: 25.0,
          durationHours: 48,
        ),
        humidity: HumidityThreshold(
          optimal: 60.0,
          high: 80.0,
          critical: 90.0,
        ),
        other: {
          'dewPointDelta': 2.0, // Dew formation likely below wheat temp + 2°C
          'sproutingRisk': {
            'rainThreshold': 15.0,
            'humidityThreshold': 80.0,
            'duration': 48,
          },
        },
      ),
      quality: QualityFactors(
        factors: {
          'protein': ThresholdRange(min: 11.0, max: 15.0, unit: '%'),
          'fallingNumber': ThresholdRange(min: 300.0, unit: 'seconds'),
        },
        impacts: {
          'protein': 'High protein premium vs drying costs',
          'fallingNumber': 'Sprouting damage affects baking quality',
        },
      ),
    ),

    CropType.canola: CropThresholds(
      crop: CropType.canola,
      moisture: MoistureThresholds(
        minOptimal: 8.0,
        maxOptimal: 10.0,
        storageMax: 8.0,
        criticalMax: 12.0,
      ),
      weather: WeatherThresholds(
        frost: TemperatureThreshold(
          threshold: -3.0,
          description: 'Locks in green seed',
          impact: 'Grade penalty',
        ),
        wind: WindThreshold(
          shatterThreshold: 25.0,
          operationalLimit: 20.0,
          moistureDependent: true,
        ),
        rain: PrecipitationThreshold(
          lightRain: 2.0,
          heavyRain: 10.0,
          criticalAmount: 20.0,
        ),
        humidity: HumidityThreshold(
          optimal: 50.0,
          high: 70.0,
          critical: 85.0,
        ),
      ),
      quality: QualityFactors(
        factors: {
          'seedColorChange': ThresholdRange(min: 60.0, max: 90.0, unit: '%'),
          'greenSeed': ThresholdRange(max: 2.0, unit: '%'),
          'oilContent': ThresholdRange(min: 40.0, unit: '%'),
        },
        impacts: {
          'seedColorChange': 'Optimal harvest timing window',
          'greenSeed': 'Grade penalty above 2%',
          'oilContent': 'Oil quality and premium',
        },
      ),
      specificFactors: {
        'shatterRate': {
          'baseRate': 1.0, // % per day after optimal
          'windMultiplier': 2.5,
          'moistureMultiplier': 1.5,
        },
      },
    ),

    CropType.barley: CropThresholds(
      crop: CropType.barley,
      moisture: MoistureThresholds(
        minOptimal: 13.5,
        maxOptimal: 18.0,
        storageMax: 13.5,
        criticalMax: 20.0,
      ),
      weather: WeatherThresholds(
        rain: PrecipitationThreshold(
          lightRain: 10.0,
          heavyRain: 20.0,
          criticalAmount: 30.0,
          durationHours: 24,
        ),
        heatStress: TemperatureThreshold(
          threshold: 25.0,
          description: 'Kernel staining risk',
          impact: 'Malting quality loss',
        ),
        humidity: HumidityThreshold(
          optimal: 65.0,
          high: 70.0,
          critical: 80.0,
        ),
      ),
      quality: QualityFactors(
        factors: {
          'protein': ThresholdRange(min: 10.5, max: 12.5, unit: '%'), // Malting
          'germination': ThresholdRange(min: 95.0, unit: '%'),
        },
        impacts: {
          'protein': 'Critical for malting quality',
          'germination': 'Malting premium depends on viability',
        },
      ),
      specificFactors: {
        'maltingPremium': true,
        'preGermination': {
          'rainThreshold': 20.0,
          'duration': 24,
        },
      },
    ),

    CropType.oats: CropThresholds(
      crop: CropType.oats,
      moisture: MoistureThresholds(
        minOptimal: 14.0,
        maxOptimal: 16.0,
        storageMax: 14.0,
        criticalMax: 18.0,
      ),
      weather: WeatherThresholds(
        rain: PrecipitationThreshold(
          lightRain: 15.0,
          heavyRain: 25.0,
          criticalAmount: 35.0,
          durationHours: 48,
        ),
        wind: WindThreshold(
          shatterThreshold: 40.0,
          operationalLimit: 35.0,
        ),
        humidity: HumidityThreshold(
          optimal: 65.0,
          high: 75.0,
          critical: 85.0,
        ),
      ),
      quality: QualityFactors(
        factors: {
          'testWeight': ThresholdRange(min: 240.0, unit: 'g/0.5L'), // Milling
          'groatPercentage': ThresholdRange(min: 75.0, unit: '%'),
        },
        impacts: {
          'testWeight': 'Milling premium threshold',
          'groatPercentage': 'Processing quality factor',
        },
      ),
      specificFactors: {
        'millingPremium': {
          'testWeightMin': 240.0,
          'groatMin': 75.0,
        },
      },
    ),
  };

  /// Get crop-specific thresholds  
  static CropThresholds? getThresholds(CropType crop) {
    return _cropThresholds[crop];
  }
  
  /// Static access to CropThresholds.getThresholds for backward compatibility
  static CropThresholds? getCropThresholds(CropType crop) {
    return getThresholds(crop);
  }

  /// Analyze weather data against crop-specific thresholds
  static WeatherThresholdAnalysis analyzeWeatherThresholds({
    required CropType crop,
    required WeatherData weather,
    required List<WeatherData> forecast,
    Map<String, dynamic>? currentFieldConditions,
  }) {
    final thresholds = getThresholds(crop);
    if (thresholds == null) {
      throw ArgumentError('No thresholds defined for crop: $crop');
    }

    final violations = <ThresholdViolation>[];
    final warnings = <ThresholdWarning>[];
    final opportunities = <ThresholdOpportunity>[];
    final analysisDetails = <String, dynamic>{};

    // Analyze current weather against thresholds
    _analyzeTemperature(weather, thresholds, violations, opportunities, analysisDetails);
    _analyzePrecipitation(weather, thresholds, violations, warnings, analysisDetails);
    _analyzeWind(weather, thresholds, violations, warnings, analysisDetails);
    _analyzeHumidity(weather, thresholds, violations, opportunities, analysisDetails);
    _analyzeCropSpecificFactors(crop, weather, thresholds, violations, opportunities, analysisDetails);

    // Analyze forecast for warnings and opportunities
    _analyzeForecast(forecast, thresholds, warnings, opportunities, analysisDetails);

    // Calculate overall risk score
    final riskScore = _calculateOverallRiskScore(violations, warnings, analysisDetails);

    return WeatherThresholdAnalysis(
      crop: crop,
      violations: violations,
      warnings: warnings,
      opportunities: opportunities,
      overallRiskScore: riskScore,
      analysisDetails: analysisDetails,
      analyzedAt: DateTime.now(),
    );
  }

  static void _analyzeTemperature(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    final temp = weather.temperature ?? weather.temperatureMax ?? 20.0;
    final tempMin = weather.temperatureMin ?? temp;

    // Frost risk
    if (thresholds.weather.frost != null) {
      final frostThreshold = thresholds.weather.frost!.threshold;
      if (tempMin <= frostThreshold) {
        violations.add(ThresholdViolation(
          factor: 'Frost Temperature',
          currentValue: tempMin,
          threshold: frostThreshold,
          severity: tempMin <= frostThreshold - 2 ? 'critical' : 'high',
          impact: thresholds.weather.frost!.impact,
          recommendation: 'Immediate harvest required if crop is mature',
        ));
      }
    }

    // Heat stress
    if (thresholds.weather.heatStress != null) {
      final heatThreshold = thresholds.weather.heatStress!.threshold;
      if (temp >= heatThreshold) {
        violations.add(ThresholdViolation(
          factor: 'Heat Stress',
          currentValue: temp,
          threshold: heatThreshold,
          severity: temp >= heatThreshold + 5 ? 'high' : 'medium',
          impact: thresholds.weather.heatStress!.impact,
          recommendation: 'Consider early morning or evening harvest',
        ));
      } else if (temp >= heatThreshold - 3) {
        opportunities.add(ThresholdOpportunity(
          factor: 'Temperature Window',
          currentValue: temp,
          advantage: 'Optimal temperature for harvest operations',
          recommendation: 'Good conditions for extended harvest hours',
        ));
      }
    }

    details['temperature'] = {
      'current': temp,
      'minimum': tempMin,
      'frostRisk': tempMin <= (thresholds.weather.frost?.threshold ?? -10.0),
      'heatStress': temp >= (thresholds.weather.heatStress?.threshold ?? 35.0),
    };
  }

  static void _analyzePrecipitation(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdWarning> warnings,
    Map<String, dynamic> details,
  ) {
    final precipitation = weather.precipitation ?? 0.0;

    if (thresholds.weather.rain != null) {
      final rainThresholds = thresholds.weather.rain!;

      if (precipitation >= rainThresholds.criticalAmount) {
        violations.add(ThresholdViolation(
          factor: 'Heavy Precipitation',
          currentValue: precipitation,
          threshold: rainThresholds.criticalAmount,
          severity: 'critical',
          impact: 'Harvest operations must cease',
          recommendation: 'Wait for field conditions to improve',
        ));
      } else if (precipitation >= rainThresholds.heavyRain) {
        violations.add(ThresholdViolation(
          factor: 'Moderate Precipitation',
          currentValue: precipitation,
          threshold: rainThresholds.heavyRain,
          severity: 'high',
          impact: 'Harvest efficiency significantly reduced',
          recommendation: 'Consider postponing harvest operations',
        ));
      } else if (precipitation >= rainThresholds.lightRain) {
        warnings.add(ThresholdWarning(
          factor: 'Light Precipitation',
          currentValue: precipitation,
          threshold: rainThresholds.lightRain,
          timeToViolation: 'Current',
          recommendation: 'Monitor conditions closely, reduce harvest speed',
        ));
      }
    }

    details['precipitation'] = {
      'current': precipitation,
      'riskLevel': precipitation >= (thresholds.weather.rain?.heavyRain ?? 20.0) ? 'high' : 'low',
    };
  }

  static void _analyzeWind(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdWarning> warnings,
    Map<String, dynamic> details,
  ) {
    final windSpeed = weather.windSpeed ?? 0.0;

    if (thresholds.weather.wind != null) {
      final windThresholds = thresholds.weather.wind!;

      if (windSpeed >= windThresholds.shatterThreshold) {
        violations.add(ThresholdViolation(
          factor: 'High Wind Speed',
          currentValue: windSpeed,
          threshold: windThresholds.shatterThreshold,
          severity: 'high',
          impact: 'Significant crop shattering risk',
          recommendation: 'Cease harvest operations until wind subsides',
        ));
      } else if (windSpeed >= windThresholds.operationalLimit) {
        warnings.add(ThresholdWarning(
          factor: 'Elevated Wind Speed',
          currentValue: windSpeed,
          threshold: windThresholds.operationalLimit,
          timeToViolation: 'Current',
          recommendation: 'Reduce harvest speed, monitor crop losses',
        ));
      }
    }

    details['wind'] = {
      'speed': windSpeed,
      'direction': weather.windDirection,
      'shatterRisk': windSpeed >= (thresholds.weather.wind?.operationalLimit ?? 30.0),
    };
  }

  static void _analyzeHumidity(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    final humidity = weather.humidity ?? 50.0;

    if (thresholds.weather.humidity != null) {
      final humidityThresholds = thresholds.weather.humidity!;

      if (humidity >= humidityThresholds.critical) {
        violations.add(ThresholdViolation(
          factor: 'Critical Humidity',
          currentValue: humidity,
          threshold: humidityThresholds.critical,
          severity: 'high',
          impact: 'Crop moisture content too high for harvest',
          recommendation: 'Wait for humidity to decrease',
        ));
      } else if (humidity <= humidityThresholds.optimal) {
        opportunities.add(ThresholdOpportunity(
          factor: 'Optimal Humidity',
          currentValue: humidity,
          advantage: 'Ideal conditions for crop drying',
          recommendation: 'Excellent harvest window opportunity',
        ));
      }
    }

    details['humidity'] = {
      'relative': humidity,
      'dewPoint': weather.dewPoint,
      'leafWetness': weather.leafWetness,
    };
  }

  static void _analyzeCropSpecificFactors(
    CropType crop,
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    switch (crop) {
      case CropType.canola:
        _analyzeCanolarSpecificFactors(weather, thresholds, violations, opportunities, details);
        break;
      case CropType.wheat:
        _analyzeWheatSpecificFactors(weather, thresholds, violations, opportunities, details);
        break;
      case CropType.barley:
        _analyzeBarleySpecificFactors(weather, thresholds, violations, opportunities, details);
        break;
      default:
        break;
    }
  }

  static void _analyzeCanolarSpecificFactors(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    final shatterFactors = thresholds.specificFactors['shatterRate'] as Map<String, dynamic>?;
    if (shatterFactors != null) {
      final windSpeed = weather.windSpeed ?? 0.0;
      final baseRate = shatterFactors['baseRate'] as double;
      final windMultiplier = shatterFactors['windMultiplier'] as double;
      
      double shatterRisk = baseRate;
      if (windSpeed > 20.0) {
        shatterRisk *= windMultiplier;
        violations.add(ThresholdViolation(
          factor: 'Canola Shattering',
          currentValue: shatterRisk,
          threshold: baseRate,
          severity: 'high',
          impact: 'Accelerated crop loss due to wind',
          recommendation: 'Prioritize canola fields for immediate harvest',
        ));
      }

      details['canolaShatterRisk'] = shatterRisk;
    }
  }

  static void _analyzeWheatSpecificFactors(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    final sproutingRisk = thresholds.weather.other['sproutingRisk'] as Map<String, dynamic>?;
    if (sproutingRisk != null) {
      final rainThreshold = sproutingRisk['rainThreshold'] as double;
      final humidityThreshold = sproutingRisk['humidityThreshold'] as double;
      final precipitation = weather.precipitation ?? 0.0;
      final humidity = weather.humidity ?? 50.0;

      if (precipitation >= rainThreshold && humidity >= humidityThreshold) {
        violations.add(ThresholdViolation(
          factor: 'Pre-harvest Sprouting Risk',
          currentValue: precipitation,
          threshold: rainThreshold,
          severity: 'critical',
          impact: 'Falling number degradation, grade loss',
          recommendation: 'Immediate harvest required if physiologically mature',
        ));
      }

      details['sproutingRisk'] = {
        'precipitation': precipitation,
        'humidity': humidity,
        'riskLevel': (precipitation >= rainThreshold && humidity >= humidityThreshold) ? 'high' : 'low',
      };
    }
  }

  static void _analyzeBarleySpecificFactors(
    WeatherData weather,
    CropThresholds thresholds,
    List<ThresholdViolation> violations,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    final preGermination = thresholds.specificFactors['preGermination'] as Map<String, dynamic>?;
    if (preGermination != null) {
      final rainThreshold = preGermination['rainThreshold'] as double;
      final precipitation = weather.precipitation ?? 0.0;

      if (precipitation >= rainThreshold) {
        violations.add(ThresholdViolation(
          factor: 'Pre-germination Risk',
          currentValue: precipitation,
          threshold: rainThreshold,
          severity: 'critical',
          impact: 'Loss of malting premium',
          recommendation: 'Immediate harvest if malting barley',
        ));
      }

      details['preGerminationRisk'] = precipitation >= rainThreshold;
    }
  }

  static void _analyzeForecast(
    List<WeatherData> forecast,
    CropThresholds thresholds,
    List<ThresholdWarning> warnings,
    List<ThresholdOpportunity> opportunities,
    Map<String, dynamic> details,
  ) {
    for (int i = 0; i < forecast.length && i < 7; i++) {
      final weather = forecast[i];
      final daysAhead = i + 1;

      // Check for upcoming precipitation
      final precipitation = weather.precipitation ?? 0.0;
      if (thresholds.weather.rain != null) {
        final rainThreshold = thresholds.weather.rain!.heavyRain;
        if (precipitation >= rainThreshold) {
          warnings.add(ThresholdWarning(
            factor: 'Forecast Heavy Rain',
            currentValue: precipitation,
            threshold: rainThreshold,
            timeToViolation: '$daysAhead day(s)',
            recommendation: 'Consider advancing harvest schedule',
          ));
        }
      }

      // Check for frost warnings
      final tempMin = weather.temperatureMin ?? weather.temperature ?? 20.0;
      if (thresholds.weather.frost != null) {
        final frostThreshold = thresholds.weather.frost!.threshold;
        if (tempMin <= frostThreshold + 2) {
          warnings.add(ThresholdWarning(
            factor: 'Forecast Frost Risk',
            currentValue: tempMin,
            threshold: frostThreshold,
            timeToViolation: '$daysAhead day(s)',
            recommendation: 'Complete harvest before frost if crop is mature',
          ));
        }
      }

      // Identify optimal harvest windows
      if (_isOptimalWeatherWindow(weather, thresholds)) {
        opportunities.add(ThresholdOpportunity(
          factor: 'Optimal Weather Window',
          currentValue: 0.0,
          advantage: 'Ideal conditions forecast',
          recommendation: 'Plan harvest operations for this window',
          windowStart: weather.timestamp,
          windowEnd: weather.timestamp.add(const Duration(hours: 24)),
        ));
      }
    }
  }

  static bool _isOptimalWeatherWindow(WeatherData weather, CropThresholds thresholds) {
    final temp = weather.temperature ?? 20.0;
    final precipitation = weather.precipitation ?? 0.0;
    final humidity = weather.humidity ?? 50.0;
    final windSpeed = weather.windSpeed ?? 0.0;

    // Check all conditions are within optimal ranges
    bool tempOk = true;
    bool precipOk = precipitation < (thresholds.weather.rain?.lightRain ?? 5.0);
    bool humidityOk = humidity <= (thresholds.weather.humidity?.high ?? 80.0);
    bool windOk = windSpeed < (thresholds.weather.wind?.operationalLimit ?? 25.0);

    if (thresholds.weather.frost != null) {
      tempOk = tempOk && temp > thresholds.weather.frost!.threshold + 3;
    }
    if (thresholds.weather.heatStress != null) {
      tempOk = tempOk && temp < thresholds.weather.heatStress!.threshold;
    }

    return tempOk && precipOk && humidityOk && windOk;
  }

  static double _calculateOverallRiskScore(
    List<ThresholdViolation> violations,
    List<ThresholdWarning> warnings,
    Map<String, dynamic> details,
  ) {
    double riskScore = 0.0;

    // Critical violations add significant risk
    for (final violation in violations) {
      switch (violation.severity) {
        case 'critical':
          riskScore += 0.4;
          break;
        case 'high':
          riskScore += 0.25;
          break;
        case 'medium':
          riskScore += 0.1;
          break;
      }
    }

    // Warnings add moderate risk
    riskScore += warnings.length * 0.05;

    return min(riskScore, 1.0);
  }

  /// Get harvest readiness score based on crop thresholds
  static double calculateHarvestReadiness({
    required CropType crop,
    required WeatherData weather,
    Map<String, dynamic>? fieldConditions,
  }) {
    final analysis = analyzeWeatherThresholds(
      crop: crop,
      weather: weather,
      forecast: [],
      currentFieldConditions: fieldConditions,
    );

    // Start with perfect readiness
    double readiness = 1.0;

    // Reduce readiness based on violations
    for (final violation in analysis.violations) {
      switch (violation.severity) {
        case 'critical':
          readiness -= 0.5;
          break;
        case 'high':
          readiness -= 0.3;
          break;
        case 'medium':
          readiness -= 0.15;
          break;
      }
    }

    // Reduce readiness based on warnings
    readiness -= analysis.warnings.length * 0.05;

    // Increase readiness based on opportunities
    readiness += analysis.opportunities.length * 0.1;

    return max(0.0, min(1.0, readiness));
  }

  /// Generate crop-specific harvest recommendations
  static List<String> generateCropRecommendations({
    required CropType crop,
    required WeatherThresholdAnalysis analysis,
    Map<String, dynamic>? fieldConditions,
  }) {
    final recommendations = <String>[];

    // Add violation-based recommendations
    for (final violation in analysis.violations) {
      recommendations.add('⚠️ ${violation.recommendation}');
    }

    // Add warning-based recommendations
    for (final warning in analysis.warnings) {
      recommendations.add('⏰ ${warning.recommendation}');
    }

    // Add opportunity-based recommendations
    for (final opportunity in analysis.opportunities) {
      recommendations.add('✅ ${opportunity.recommendation}');
    }

    // Add crop-specific general recommendations
    final thresholds = getThresholds(crop);
    if (thresholds != null) {
      switch (crop) {
        case CropType.canola:
          if (analysis.overallRiskScore < 0.3) {
            recommendations.add('🌾 Monitor seed color change - optimal harvest window at 60-90% brown seeds');
          }
          break;
        case CropType.wheat:
          if (analysis.overallRiskScore < 0.3) {
            recommendations.add('🌾 Consider straight cutting at 16-20% moisture for optimal quality');
          }
          break;
        case CropType.barley:
          if (analysis.overallRiskScore < 0.3 && (thresholds.specificFactors['maltingPremium'] as bool? ?? false)) {
            recommendations.add('🍺 Preserve malting quality - harvest at 13.5-14.5% moisture');
          }
          break;
        default:
          break;
      }
    }

    // Add economic considerations
    if (analysis.violations.isNotEmpty) {
      recommendations.add('💰 Current conditions may result in grade penalties - weigh costs vs waiting');
    } else if (analysis.opportunities.isNotEmpty) {
      recommendations.add('💰 Excellent conditions for maintaining premium grade');
    }

    return recommendations;
  }
}