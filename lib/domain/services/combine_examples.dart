/**
 * Combine Capability Examples for FieldFirst
 * Demonstrates how different combine models (X9 1100, Case IH 8250) 
 * affect harvest window recommendations based on equipment capabilities
 */

import '../models/combine_models.dart';
import '../models/harvest_models.dart';

/// Example combine specifications with harvest-specific data
class CombineExamples {
  
  /// John Deere X9 1100 - Premium high-capacity combine
  static CombineSpec createJohnDeereX9_1100() {
    return CombineSpec(
      id: 'jd_x9_1100_example',
      brand: 'john_deere',
      model: 'x9_1100',
      modelVariants: ['X9 1100', 'X9-1100', 'x91100'],
      year: 2023,
      userId: 'example_user',
      moistureTolerance: MoistureTolerance(
        min: 12.0,
        max: 18.0, // High moisture tolerance
        optimal: 15.0,
        confidence: ConfidenceLevel.high,
      ),
      toughCropAbility: ToughCropAbility(
        rating: 9, // Excellent tough crop handling
        crops: ['corn', 'soybeans', 'wheat', 'canola'],
        limitations: ['Steep slopes >15 degrees'],
        confidence: ConfidenceLevel.high,
        cropSpecificRatings: {
          'corn': 10,
          'soybeans': 9,
          'wheat': 8,
          'canola': 8,
        },
        handlesHighMoisture: true,
        handlesLodgedCrops: true,
        handlesGreenStem: true,
      ),
      sourceData: SourceData(
        userReports: 45,
        manufacturerSpecs: true,
        expertValidation: true,
        lastUpdated: DateTime.now(),
      ),
      region: 'ontario',
      isPublic: true,
      harvestCapabilities: HarvestCapabilities(
        operatingSpeedKmh: 12.0, // High operating speed
        grainTankCapacityL: 16800, // Large grain tank
        unloadingRateLS: 140.0, // Fast unloading
        fuelConsumptionLh: 45.0,
        dailyCapacityHa: 120.0, // High daily capacity
        hasYieldMapping: true,
        hasMoistureMapping: true,
        hasAutomaticAdjustments: true,
        weatherLimitations: {
          'maxWindSpeed': 45.0, // Can handle higher winds
          'maxMoisture': 18.0,
          'minTemperature': -2.0,
        },
        reliabilityRating: 9, // Very reliable
        maintenanceComplexity: 7, // Moderate complexity
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Case IH Axial Flow 8250 - Standard production combine
  static CombineSpec createCaseIH_8250() {
    return CombineSpec(
      id: 'cih_af8250_example',
      brand: 'case_ih',
      model: 'af_8250',
      modelVariants: ['8250', 'AF8250', 'Axial Flow 8250'],
      year: 2022,
      userId: 'example_user',
      moistureTolerance: MoistureTolerance(
        min: 12.0,
        max: 16.0, // Standard moisture tolerance
        optimal: 14.0,
        confidence: ConfidenceLevel.medium,
      ),
      toughCropAbility: ToughCropAbility(
        rating: 6, // Good but not exceptional
        crops: ['corn', 'soybeans', 'wheat'],
        limitations: ['High moisture crops', 'Very lodged conditions'],
        confidence: ConfidenceLevel.medium,
        cropSpecificRatings: {
          'corn': 7,
          'soybeans': 6,
          'wheat': 6,
          'canola': 5,
        },
        handlesHighMoisture: false,
        handlesLodgedCrops: false, // Limited tough crop capability
        handlesGreenStem: false,
      ),
      sourceData: SourceData(
        userReports: 23,
        manufacturerSpecs: true,
        expertValidation: false,
        lastUpdated: DateTime.now(),
      ),
      region: 'ontario',
      isPublic: true,
      harvestCapabilities: HarvestCapabilities(
        operatingSpeedKmh: 8.5, // Moderate operating speed
        grainTankCapacityL: 12800, // Standard grain tank
        unloadingRateLS: 95.0, // Standard unloading rate
        fuelConsumptionLh: 38.0,
        dailyCapacityHa: 85.0, // Standard daily capacity
        hasYieldMapping: true,
        hasMoistureMapping: false, // No moisture mapping
        hasAutomaticAdjustments: false, // Manual adjustments
        weatherLimitations: {
          'maxWindSpeed': 35.0, // Lower wind tolerance
          'maxMoisture': 16.0,
          'minTemperature': 0.0,
        },
        reliabilityRating: 7, // Good reliability
        maintenanceComplexity: 5, // Lower complexity
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Example demonstrating how combine capabilities affect harvest windows
  static List<HarvestWindow> demonstrateCapabilityImpact() {
    // Create example weather conditions (marginal for harvest)
    final marginalWeather = WeatherData(
      locationId: 'example_field',
      timestamp: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      temperatureMin: 2.0, // Cool morning
      temperatureMax: 18.0,
      temperature: 12.0,
      humidity: 78.0, // High humidity
      precipitation: 0.5, // Light precipitation
      windSpeed: 25.0, // Moderate winds
      windDirection: 270.0,
      dewPoint: 8.0,
      leafWetness: 6.0, // Elevated leaf wetness
      evapotranspiration: 2.5,
      condition: WeatherCondition.cloudy,
      description: 'Overcast with light drizzle',
    );

    // Get capabilities for both combines
    final x9Capability = CombineCapability.fromCombineSpec(createJohnDeereX9_1100());
    final caseCapability = CombineCapability.fromCombineSpec(createCaseIH_8250());

    // Create harvest windows for corn crop
    final x9Window = HarvestWindow.create(
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      weather: marginalWeather,
      combineCapability: x9Capability,
      crop: CropType.corn,
    );

    final caseWindow = HarvestWindow.create(
      startTime: DateTime.now().add(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      weather: marginalWeather,
      combineCapability: caseCapability,
      crop: CropType.corn,
    );

    return [x9Window, caseWindow];
  }

  /// Analysis of how equipment affects harvest decisions
  static String analyzeCapabilityImpact() {
    final windows = demonstrateCapabilityImpact();
    final x9Window = windows[0];
    final caseWindow = windows[1];

    final analysis = StringBuffer();
    analysis.writeln('=== Combine Capability Impact Analysis ===\n');

    analysis.writeln('Weather Conditions: Marginal (High humidity, light precipitation, moderate winds)\n');

    analysis.writeln('John Deere X9 1100 Results:');
    analysis.writeln('  - Recommendation: ${x9Window.recommendation.name.toUpperCase()}');
    analysis.writeln('  - Confidence Score: ${(x9Window.confidenceScore * 100).toStringAsFixed(1)}%');
    analysis.writeln('  - Combine-Weather Multiplier: ${x9Window.combineWeatherMultiplier.toStringAsFixed(2)}');
    analysis.writeln('  - Priority: ${x9Window.priority}/10');
    analysis.writeln('  - Key Advantages:');
    analysis.writeln('    * 18% moisture tolerance vs 16% standard');
    analysis.writeln('    * Excellent tough crop ability (9/10)');
    analysis.writeln('    * Can handle marginal conditions');
    analysis.writeln('    * Higher wind tolerance (45 km/h vs 35 km/h)');
    analysis.writeln('');

    analysis.writeln('Case IH 8250 Results:');
    analysis.writeln('  - Recommendation: ${caseWindow.recommendation.name.toUpperCase()}');
    analysis.writeln('  - Confidence Score: ${(caseWindow.confidenceScore * 100).toStringAsFixed(1)}%');
    analysis.writeln('  - Combine-Weather Multiplier: ${caseWindow.combineWeatherMultiplier.toStringAsFixed(2)}');
    analysis.writeln('  - Priority: ${caseWindow.priority}/10');
    analysis.writeln('  - Limitations:');
    analysis.writeln('    * 16% moisture tolerance limitation');
    analysis.writeln('    * Moderate tough crop ability (6/10)');
    analysis.writeln('    * Struggles in marginal conditions');
    analysis.writeln('    * Lower wind tolerance');
    analysis.writeln('');

    final difference = x9Window.combineWeatherMultiplier - caseWindow.combineWeatherMultiplier;
    analysis.writeln('Impact Analysis:');
    analysis.writeln('  - Capability Multiplier Difference: ${difference.toStringAsFixed(2)}');
    analysis.writeln('  - The X9\'s superior capabilities allow it to:');
    analysis.writeln('    * Start harvesting ${(difference * 100).toStringAsFixed(0)}% earlier in marginal conditions');
    analysis.writeln('    * Handle challenging weather with greater confidence');
    analysis.writeln('    * Extend harvest windows beyond standard equipment limits');
    analysis.writeln('    * Reduce weather-related downtime');

    if (x9Window.recommendation != caseWindow.recommendation) {
      analysis.writeln('');
      analysis.writeln('CRITICAL DIFFERENCE:');
      analysis.writeln('  The X9 receives a "${x9Window.recommendation.name}" recommendation');
      analysis.writeln('  while the 8250 receives "${caseWindow.recommendation.name}"');
      analysis.writeln('  This demonstrates how equipment capability directly impacts');
      analysis.writeln('  harvest timing decisions and operational efficiency.');
    }

    return analysis.toString();
  }

  /// Cost-benefit analysis of equipment capabilities
  static Map<String, dynamic> analyzeCostBenefit() {
    final x9Spec = createJohnDeereX9_1100();
    final caseSpec = createCaseIH_8250();
    
    final x9Capability = CombineCapability.fromCombineSpec(x9Spec);
    final caseCapability = CombineCapability.fromCombineSpec(caseSpec);

    // Example cost assumptions (would be based on real data)
    const x9DailyCost = 2800.0; // Higher operating cost
    const caseDailyCost = 2200.0; // Lower operating cost

    final x9DailyCapacity = x9Spec.harvestCapabilities!.dailyCapacityHa;
    final caseDailyCapacity = caseSpec.harvestCapabilities!.dailyCapacityHa;

    final x9CostPerHa = x9DailyCost / x9DailyCapacity;
    final caseCostPerHa = caseDailyCost / caseDailyCapacity;

    // Calculate weather utilization advantage
    const marginalWeatherDays = 5; // Days with marginal conditions per season
    const totalHarvestDays = 25; // Total harvest season days
    
    final x9WeatherUtilization = 0.8; // Can work 80% of marginal days
    final caseWeatherUtilization = 0.4; // Can only work 40% of marginal days

    final x9EffectiveDays = totalHarvestDays - marginalWeatherDays + 
                           (marginalWeatherDays * x9WeatherUtilization);
    final caseEffectiveDays = totalHarvestDays - marginalWeatherDays +
                             (marginalWeatherDays * caseWeatherUtilization);

    return {
      'combines': {
        'x9_1100': {
          'dailyCost': x9DailyCost,
          'dailyCapacity': x9DailyCapacity,
          'costPerHa': x9CostPerHa,
          'effectiveHarvestDays': x9EffectiveDays,
          'seasonalCapacity': x9DailyCapacity * x9EffectiveDays,
        },
        'case_8250': {
          'dailyCost': caseDailyCost,
          'dailyCapacity': caseDailyCapacity,
          'costPerHa': caseCostPerHa,
          'effectiveHarvestDays': caseEffectiveDays,
          'seasonalCapacity': caseDailyCapacity * caseEffectiveDays,
        },
      },
      'weatherAdvantage': {
        'marginalDaysPerSeason': marginalWeatherDays,
        'x9UtilizationRate': x9WeatherUtilization,
        'caseUtilizationRate': caseWeatherUtilization,
        'additionalWorkingDays': x9EffectiveDays - caseEffectiveDays,
      },
      'analysis': {
        'costPerHaDifference': x9CostPerHa - caseCostPerHa,
        'capacityAdvantage': x9DailyCapacity - caseDailyCapacity,
        'weatherDaysAdvantage': (x9WeatherUtilization - caseWeatherUtilization) * marginalWeatherDays,
        'recommendation': x9CostPerHa < caseCostPerHa ? 
          'X9 provides better value despite higher daily cost due to efficiency and weather capability' :
          'Cost-benefit depends on field size and weather patterns',
      },
    };
  }

  /// Generate comparison report
  static String generateComparisonReport() {
    final costBenefit = analyzeCostBenefit();
    final capabilityAnalysis = analyzeCapabilityImpact();
    
    final report = StringBuffer();
    report.writeln('=== FieldFirst Combine Capability Report ===\n');
    report.writeln('Date: ${DateTime.now().toIso8601String().split('T')[0]}\n');
    
    report.writeln(capabilityAnalysis);
    report.writeln('\n=== Economic Analysis ===\n');
    
    final x9Data = costBenefit['combines']['x9_1100'];
    final caseData = costBenefit['combines']['case_8250'];
    final weather = costBenefit['weatherAdvantage'];
    
    report.writeln('Operating Economics:');
    report.writeln('  John Deere X9 1100:');
    report.writeln('    - Daily Operating Cost: \$${x9Data['dailyCost']}');
    report.writeln('    - Daily Capacity: ${x9Data['dailyCapacity']} ha');
    report.writeln('    - Cost per hectare: \$${x9Data['costPerHa'].toStringAsFixed(2)}');
    report.writeln('    - Effective harvest days: ${x9Data['effectiveHarvestDays'].toStringAsFixed(1)}');
    report.writeln('');
    report.writeln('  Case IH 8250:');
    report.writeln('    - Daily Operating Cost: \$${caseData['dailyCost']}');
    report.writeln('    - Daily Capacity: ${caseData['dailyCapacity']} ha');
    report.writeln('    - Cost per hectare: \$${caseData['costPerHa'].toStringAsFixed(2)}');
    report.writeln('    - Effective harvest days: ${caseData['effectiveHarvestDays'].toStringAsFixed(1)}');
    report.writeln('');
    
    report.writeln('Weather Utilization Advantage:');
    report.writeln('  - X9 can work ${(weather['x9UtilizationRate'] * 100).toStringAsFixed(0)}% of marginal weather days');
    report.writeln('  - Case IH can work ${(weather['caseUtilizationRate'] * 100).toStringAsFixed(0)}% of marginal weather days');
    report.writeln('  - X9 gains ${weather['additionalWorkingDays'].toStringAsFixed(1)} additional working days per season');
    report.writeln('');
    
    report.writeln('Recommendation:');
    report.writeln('  ${costBenefit['analysis']['recommendation']}');
    
    return report.toString();
  }
}

/// Extended examples for different crop types
class CropSpecificExamples {
  
  /// High moisture corn scenario
  static HarvestWindow highMoistureCornExample() {
    final highMoistureWeather = WeatherData(
      locationId: 'high_moisture_field',
      timestamp: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      temperatureMin: 5.0,
      temperatureMax: 15.0,
      temperature: 10.0,
      humidity: 85.0, // Very high humidity
      precipitation: 2.0, // Recent precipitation
      windSpeed: 15.0,
      windDirection: 180.0,
      dewPoint: 12.0,
      leafWetness: 9.0, // Very high leaf wetness
      evapotranspiration: 1.0,
      condition: WeatherCondition.fog,
      description: 'Heavy fog with high moisture content',
    );

    final x9Capability = CombineCapability.fromCombineSpec(
      CombineExamples.createJohnDeereX9_1100()
    );

    return HarvestWindow.create(
      startTime: DateTime.now().add(const Duration(hours: 4)), // Wait for conditions to improve
      endTime: DateTime.now().add(const Duration(hours: 8)),
      weather: highMoistureWeather,
      combineCapability: x9Capability,
      crop: CropType.corn,
    );
  }

  /// Lodged crop scenario
  static HarvestWindow lodgedCropExample() {
    final moderateWeather = WeatherData(
      locationId: 'lodged_crop_field',
      timestamp: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      temperatureMin: 8.0,
      temperatureMax: 22.0,
      temperature: 15.0,
      humidity: 65.0,
      precipitation: 0.0,
      windSpeed: 20.0,
      windDirection: 270.0,
      dewPoint: 5.0,
      leafWetness: 3.0,
      evapotranspiration: 4.0,
      condition: WeatherCondition.cloudy,
      description: 'Overcast but dry conditions',
    );

    final x9Capability = CombineCapability.fromCombineSpec(
      CombineExamples.createJohnDeereX9_1100()
    );

    // Modify for lodged crop handling
    final enhancedCapability = CombineCapability(
      combineSpecId: x9Capability.combineSpecId,
      moistureToleranceScore: x9Capability.moistureToleranceScore,
      toughCropScore: 10.0, // Maximum tough crop score for lodged conditions
      reliabilityScore: x9Capability.reliabilityScore,
      speedScore: x9Capability.speedScore * 0.7, // Reduced speed for lodged crops
      overallScore: x9Capability.overallScore,
      cropSpecificScores: {
        ...x9Capability.cropSpecificScores,
        CropType.soybeans: 10.0, // Excellent for lodged soybeans
      },
      calculatedAt: DateTime.now(),
    );

    return HarvestWindow.create(
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      weather: moderateWeather,
      combineCapability: enhancedCapability,
      crop: CropType.soybeans,
    );
  }
}

/// Utility functions for demonstrations
class HarvestDemonstrationUtils {
  
  /// Create a series of weather scenarios for testing
  static List<WeatherData> createWeatherScenarios(String locationId) {
    return [
      // Optimal conditions
      WeatherData(
        locationId: locationId,
        timestamp: DateTime.now(),
        provider: WeatherProvider.tomorrowIo,
        temperatureMin: 10.0,
        temperatureMax: 25.0,
        temperature: 18.0,
        humidity: 55.0,
        precipitation: 0.0,
        windSpeed: 12.0,
        windDirection: 270.0,
        dewPoint: 8.0,
        leafWetness: 2.0,
        evapotranspiration: 4.5,
        condition: WeatherCondition.clear,
        description: 'Clear sunny conditions',
      ),
      // Marginal conditions
      WeatherData(
        locationId: locationId,
        timestamp: DateTime.now().add(const Duration(days: 1)),
        provider: WeatherProvider.tomorrowIo,
        temperatureMin: 2.0,
        temperatureMax: 16.0,
        temperature: 12.0,
        humidity: 78.0,
        precipitation: 0.5,
        windSpeed: 28.0,
        windDirection: 180.0,
        dewPoint: 8.0,
        leafWetness: 6.0,
        evapotranspiration: 2.0,
        condition: WeatherCondition.cloudy,
        description: 'Cool and damp with moderate winds',
      ),
      // Poor conditions
      WeatherData(
        locationId: locationId,
        timestamp: DateTime.now().add(const Duration(days: 2)),
        provider: WeatherProvider.tomorrowIo,
        temperatureMin: 0.0,
        temperatureMax: 8.0,
        temperature: 4.0,
        humidity: 95.0,
        precipitation: 8.0,
        windSpeed: 45.0,
        windDirection: 225.0,
        dewPoint: 6.0,
        leafWetness: 10.0,
        evapotranspiration: 0.5,
        condition: WeatherCondition.rain,
        description: 'Heavy rain with strong winds',
      ),
    ];
  }

  /// Compare multiple combines across different scenarios
  static Map<String, List<HarvestWindow>> compareAcrossScenarios() {
    final scenarios = createWeatherScenarios('demo_field');
    final x9Spec = CombineExamples.createJohnDeereX9_1100();
    final caseSpec = CombineExamples.createCaseIH_8250();
    
    final x9Capability = CombineCapability.fromCombineSpec(x9Spec);
    final caseCapability = CombineCapability.fromCombineSpec(caseSpec);

    final results = <String, List<HarvestWindow>>{
      'x9_1100': [],
      'case_8250': [],
    };

    for (int i = 0; i < scenarios.length; i++) {
      final weather = scenarios[i];
      final startTime = DateTime.now().add(Duration(days: i, hours: 8));
      final endTime = startTime.add(const Duration(hours: 10));

      results['x9_1100']!.add(HarvestWindow.create(
        startTime: startTime,
        endTime: endTime,
        weather: weather,
        combineCapability: x9Capability,
        crop: CropType.corn,
      ));

      results['case_8250']!.add(HarvestWindow.create(
        startTime: startTime,
        endTime: endTime,
        weather: weather,
        combineCapability: caseCapability,
        crop: CropType.corn,
      ));
    }

    return results;
  }
}