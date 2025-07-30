# Tomorrow.io Weather Integration with Advanced Caching

This document describes the comprehensive Tomorrow.io weather API integration with intelligent caching system for the FieldReady agriculture application.

## Overview

The system provides:
- **Tomorrow.io API Integration**: Primary weather data provider with MSC fallback
- **Intelligent Caching**: Multi-layer caching with location clustering
- **Cache Warming**: Proactive cache population strategies
- **Analytics & Monitoring**: Comprehensive performance tracking
- **Cost Optimization**: Minimize API calls through smart caching

## Architecture

### Core Components

1. **WeatherApiService** (`weather_api_service.dart`)
   - Primary interface to Tomorrow.io and MSC APIs
   - Circuit breaker pattern for failover
   - Rate limiting and retry logic
   - Integrated caching support

2. **HarvestCacheService** (`harvest_cache_service.dart`)
   - Multi-layer caching (memory + persistent)
   - Location clustering to reduce API calls
   - Smart eviction policies
   - Cache statistics tracking

3. **CacheWarmingService** (`cache_warming_service.dart`)
   - Scheduled and predictive cache warming
   - User activity-based warming
   - Seasonal optimization
   - Performance monitoring

4. **CacheAnalyticsService** (`cache_analytics_service.dart`)
   - Real-time performance monitoring
   - Trend analysis and predictions
   - Alert system for issues
   - Optimization recommendations

5. **IntegratedCacheService** (`integrated_cache_service.dart`)
   - Orchestrates all cache components
   - Unified API for the application
   - Auto-optimization capabilities
   - Health monitoring

## Key Features

### Weather API Integration

```dart
// Initialize weather service with cache integration
final weatherService = WeatherApiServiceImpl(
  config: WeatherApiConfig(
    tomorrowIoApiKey: 'your-api-key',
    requestTimeout: Duration(seconds: 30),
    maxRetries: 3,
    rateLimitPerMinute: 100,
  ),
  cacheService: harvestCacheService,
);

// Get weather forecast with automatic caching
final forecast = await weatherService.getForecast(location, 7);
```

### Intelligent Caching

```dart
// Configure caching behavior
final cacheConfig = HarvestCacheConfig(
  weatherCacheDuration: Duration(minutes: 15),
  capabilityCacheDuration: Duration(hours: 24),
  locationClusteringRadius: 2.0, // km
  enableSmartPrefetching: true,
);

// Initialize cache service
final cacheService = HarvestCacheService(
  cacheRepository: cacheRepository,
  config: cacheConfig,
);
```

### Cache Warming

```dart
// Schedule automatic cache warming
final warmingService = CacheWarmingService(
  cacheService: cacheService,
  weatherApiService: weatherService,
  cacheRepository: cacheRepository,
  config: CacheWarmingConfig(
    warmingInterval: Duration(hours: 6),
    maxConcurrentWarms: 3,
    enablePredictiveWarming: true,
  ),
);

// Manually warm cache for specific user
final result = await warmingService.warmCacheForUser('user123');
```

### Analytics & Monitoring

```dart
// Get comprehensive cache analytics
final analytics = await analyticsService.generatePerformanceReport();

print('Hit Rate: ${(analytics.harvestCacheStats.hitRate * 100).toStringAsFixed(1)}%');
print('Memory Usage: ${analytics.harvestCacheStats.memoryUsage} units');
print('API Calls Saved: ${analytics.weatherApiStats.apiCallReduction}');
```

## Integration Guide

### 1. Setup Dependencies

Add required repositories and services to your dependency injection:

```dart
// Repository layer
final cacheRepository = FirebaseCacheRepository();
final combineRepository = FirebaseCombineRepository();
final userCombineRepository = FirebaseUserCombineRepository();

// Initialize integrated cache service
final integratedCacheService = IntegratedCacheService(
  cacheRepository: cacheRepository,
  combineRepository: combineRepository,
  userCombineRepository: userCombineRepository,
  config: IntegratedCacheConfig(
    weatherApiConfig: WeatherApiConfig(
      tomorrowIoApiKey: 'your-tomorrow-io-api-key',
      preferPrimary: true,
    ),
  ),
);

await integratedCacheService.initialize();
```

### 2. Environment Configuration

Set up your environment variables:

```bash
TOMORROW_IO_API_KEY=your-api-key-here
MSC_API_KEY=optional-msc-key
CACHE_REDIS_URL=redis://localhost:6379  # Optional for Redis caching
```

### 3. Usage Examples

#### Get Weather Forecast with Caching

```dart
final locations = [
  FieldLocation(
    id: 'field1',
    name: 'North Field',
    latitude: 45.0,
    longitude: -93.0,
  ),
];

// This will automatically use caching
final forecast = await integratedCacheService.getWeatherForecast(
  locations.first,
  7, // days
);

print('Temperature: ${forecast.dailyForecasts.first.temperature}°C');
print('Condition: ${forecast.dailyForecasts.first.condition}');
```

#### Get Harvest Recommendations

```dart
final recommendations = await integratedCacheService.getHarvestRecommendations(
  userId: 'user123',
  fields: locations,
  crop: CropType.corn,
  forecastDays: 7,
  enableCacheWarming: true,
);

for (final window in recommendations.harvestWindows) {
  print('Window: ${window.startTime} - ${window.endTime}');
  print('Recommendation: ${window.recommendation}');
  print('Confidence: ${(window.confidenceScore * 100).toStringAsFixed(1)}%');
}
```

#### Monitor Cache Performance

```dart
final healthReport = await integratedCacheService.getHealthReport();

print('Overall Health: ${(healthReport.overallHealthScore * 100).toStringAsFixed(1)}%');
print('Active Alerts: ${healthReport.activeAlerts.length}');

if (healthReport.warnings.isNotEmpty) {
  print('Warnings:');
  healthReport.warnings.forEach(print);
}

if (healthReport.recommendations.isNotEmpty) {
  print('Recommendations:');
  healthReport.recommendations.forEach(print);
}
```

## Performance Optimization

### Location Clustering

The system automatically clusters nearby field locations to minimize API calls:

```dart
// Fields within 2km are clustered together
final config = HarvestCacheConfig(
  locationClusteringRadius: 2.0, // km
);

// Single API call for clustered locations
final forecast = await weatherService.getForecast(clusterRepresentative, 7);
```

### Smart Cache Warming

Cache warming strategies based on usage patterns:

```dart
// During harvest season, warm additional forecast days
if (isHarvestSeason) {
  await warmingService.warmCacheForLocations(userLocations, 10);
}

// Pre-warm cache before peak usage hours
await warmingService.executeWarmingStrategy(
  CacheWarmingStrategy(
    name: 'morning_prep',
    interval: Duration(hours: 6),
    collections: ['weatherForecasts', 'harvestWindows'],
  ),
);
```

### Cost Optimization

Track and optimize API costs:

```dart
final costSummary = harvestIntelligenceService.getCostSummary();

print('Total API Cost: \$${costSummary.totalCost.toStringAsFixed(2)}');
print('Cache Hit Rate: ${(costSummary.cacheHitRate * 100).toStringAsFixed(1)}%');
print('Cost Savings: \$${costSummary.totalCalls * 0.05 - costSummary.totalCost}');
```

## Monitoring & Alerts

### Performance Metrics

The system tracks key performance indicators:

- **Cache Hit Rate**: Percentage of requests served from cache
- **Response Time**: Average time to fulfill requests
- **Memory Usage**: Current cache memory consumption
- **API Call Reduction**: Percentage of API calls avoided
- **Error Rate**: Percentage of failed requests

### Automated Alerts

Configure alerts for performance issues:

```dart
final analyticsConfig = CacheAnalyticsConfig(
  alertThresholdHitRate: 0.7,     // Alert if hit rate < 70%
  alertThresholdResponseTime: 1000.0, // Alert if response > 1s
  enableRealTimeMonitoring: true,
);
```

### Health Scoring

The system provides a comprehensive health score (0-1):

- **0.9-1.0**: Excellent performance
- **0.7-0.9**: Good performance  
- **0.5-0.7**: Fair performance, optimization recommended
- **0.0-0.5**: Poor performance, immediate attention required

## Troubleshooting

### Common Issues

1. **Low Cache Hit Rate**
   - Check cache TTL settings
   - Verify location clustering is working
   - Review cache eviction policies

2. **High API Costs**
   - Increase cache duration for weather data
   - Enable more aggressive cache warming
   - Review location clustering radius

3. **Slow Response Times**
   - Check cache storage performance
   - Optimize cache size limits
   - Review network connectivity to APIs

4. **Memory Issues**
   - Adjust cache size limits
   - Enable more aggressive eviction
   - Monitor memory usage trends

### Debug Mode

Enable detailed logging for troubleshooting:

```dart
// Enable debug logging
final config = IntegratedCacheConfig(
  analyticsConfig: CacheAnalyticsConfig(
    enableRealTimeMonitoring: true,
  ),
);

// Monitor cache events
analyticsService.recordCacheEvent(CacheEvent(
  operation: 'debug_test',
  timestamp: DateTime.now(),
  success: true,
));
```

## API Rate Limits

### Tomorrow.io Limits

- **Free Tier**: 500 calls/day, 25 calls/hour
- **Developer Tier**: 10,000 calls/day, 100 calls/hour
- **Production Tier**: Custom limits

### Optimization Strategies

1. **Location Clustering**: Reduce API calls for nearby locations
2. **Extended Caching**: Longer TTL for stable data
3. **Smart Warming**: Pre-fetch during low-usage periods
4. **Fallback to MSC**: Use free Canadian weather service when possible

## Best Practices

1. **Initialize Early**: Set up the integrated cache service at app startup
2. **Monitor Performance**: Regularly check health reports and analytics
3. **Optimize Gradually**: Make incremental improvements based on data
4. **Plan for Growth**: Set appropriate cache limits for your user base
5. **Test Thoroughly**: Verify cache behavior under various conditions

## Future Enhancements

Planned improvements include:

- **Redis Integration**: External cache storage for better performance
- **GraphQL Support**: More efficient API queries
- **Machine Learning**: AI-powered cache optimization
- **Multi-Region**: Distributed caching for global applications
- **Advanced Analytics**: Deeper insights into usage patterns

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review cache analytics for performance insights  
3. Monitor system health reports for optimization opportunities
4. Contact the development team for advanced configuration needs

---

*This integration provides a robust, cost-effective solution for weather data caching in agricultural applications, optimized for the Tomorrow.io API while maintaining fallback capabilities.*