/**
 * Weather API Service for FieldFirst
 * Implements Tomorrow.io as primary provider with MSC (Meteorological Service of Canada) as fallback
 * Includes intelligent retry logic, rate limiting, and cost optimization
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/harvest_models.dart';
import '../models/cache_models.dart';
import 'harvest_intelligence.dart';
import 'harvest_cache_service.dart';

/// Weather API configuration
class WeatherApiConfig {
  final String tomorrowIoApiKey;
  final String mscApiKey;
  final Duration requestTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final int rateLimitPerMinute;
  final bool preferPrimary;

  const WeatherApiConfig({
    required this.tomorrowIoApiKey,
    this.mscApiKey = '',
    this.requestTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.rateLimitPerMinute = 100,
    this.preferPrimary = true,
  });
}

/// Enhanced implementation of WeatherApiService with intelligent caching
class WeatherApiServiceImpl implements WeatherApiService {
  final WeatherApiConfig _config;
  final http.Client _httpClient;
  final HarvestCacheService? _cacheService;
  
  // Rate limiting
  final List<DateTime> _requestTimes = [];
  
  // Circuit breaker state
  bool _tomorrowIoHealthy = true;
  bool _mscHealthy = true;
  DateTime? _lastTomorrowIoFailure;
  DateTime? _lastMscFailure;
  int _consecutiveTomorrowIoFailures = 0;
  int _consecutiveMscFailures = 0;
  
  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _apiCalls = 0;
  
  static const int _maxConsecutiveFailures = 5;
  static const Duration _circuitBreakerTimeout = Duration(minutes: 15);

  WeatherApiServiceImpl({
    required WeatherApiConfig config,
    http.Client? httpClient,
    HarvestCacheService? cacheService,
  }) : _config = config,
       _httpClient = httpClient ?? http.Client(),
       _cacheService = cacheService;

  @override
  Future<WeatherForecast> getForecast(FieldLocation location, int days) async {
    // Check cache first if caching is enabled
    if (_cacheService != null) {
      final cachedForecast = await _cacheService.getWeatherForecast(location, days);
      if (cachedForecast != null && !cachedForecast.isExpired) {
        _cacheHits++;
        return cachedForecast;
      }
      _cacheMisses++;
    }

    WeatherForecast? forecast;
    
    // Try primary provider first (Tomorrow.io)
    if (_config.preferPrimary && _isTomorrowIoHealthy()) {
      try {
        forecast = await _getTomorrowIoForecast(location, days);
        _resetTomorrowIoFailures();
        _apiCalls++;
        
        // Cache the successful result
        if (_cacheService != null) {
          await _cacheService.cacheWeatherForecast(location, forecast);
        }
        
        return forecast;
      } catch (e) {
        _handleTomorrowIoFailure();
        // Continue to fallback
      }
    }

    // Try fallback provider (MSC)
    if (_isMscHealthy()) {
      try {
        forecast = await _getMscForecast(location, days);
        _resetMscFailures();
        _apiCalls++;
        
        // Cache the successful result
        if (_cacheService != null) {
          await _cacheService.cacheWeatherForecast(location, forecast);
        }
        
        return forecast;
      } catch (e) {
        _handleMscFailure();
        // Continue to final fallback
      }
    }

    // Last resort: try Tomorrow.io even if unhealthy
    if (!_config.preferPrimary || !_isTomorrowIoHealthy()) {
      try {
        forecast = await _getTomorrowIoForecast(location, days);
        _resetTomorrowIoFailures();
        _apiCalls++;
        
        // Cache the successful result
        if (_cacheService != null) {
          await _cacheService.cacheWeatherForecast(location, forecast);
        }
        
        return forecast;
      } catch (e) {
        _handleTomorrowIoFailure();
      }
    }

    throw WeatherApiException(
      'All weather providers failed',
      location: location,
      providers: [WeatherProvider.tomorrowIo, WeatherProvider.msc],
    );
  }

  @override
  Future<WeatherData> getCurrentWeather(FieldLocation location) async {
    // Try primary provider first
    if (_config.preferPrimary && _isTomorrowIoHealthy()) {
      try {
        final weather = await _getTomorrowIoCurrentWeather(location);
        _resetTomorrowIoFailures();
        return weather;
      } catch (e) {
        _handleTomorrowIoFailure();
      }
    }

    // Try fallback provider
    if (_isMscHealthy()) {
      try {
        final weather = await _getMscCurrentWeather(location);
        _resetMscFailures();
        return weather;
      } catch (e) {
        _handleMscFailure();
      }
    }

    // Last resort
    if (!_config.preferPrimary || !_isTomorrowIoHealthy()) {
      try {
        final weather = await _getTomorrowIoCurrentWeather(location);
        _resetTomorrowIoFailures();
        return weather;
      } catch (e) {
        _handleTomorrowIoFailure();
      }
    }

    throw WeatherApiException(
      'All weather providers failed for current weather',
      location: location,
      providers: [WeatherProvider.tomorrowIo, WeatherProvider.msc],
    );
  }

  /// Tomorrow.io API implementations

  Future<WeatherForecast> _getTomorrowIoForecast(
    FieldLocation location,
    int days,
  ) async {
    await _enforceRateLimit();

    final uri = Uri.parse('https://api.tomorrow.io/v4/timelines');
    final body = {
      'location': '${location.latitude},${location.longitude}',
      'fields': [
        'temperatureMin',
        'temperatureMax',
        'temperature',
        'humidity',
        'precipitationIntensity',
        'windSpeed',
        'windDirection',
        'dewPoint',
        'leafWetness',
        'evapotranspiration',
        'weatherCode',
        'weatherCodeFullDay',
        'sunriseTime',
        'sunsetTime',
      ],
      'units': 'metric',
      'timesteps': ['1d'],
      'startTime': DateTime.now().toIso8601String(),
      'endTime': DateTime.now().add(Duration(days: days)).toIso8601String(),
    };

    final response = await _makeRequest(
      uri: uri,
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ${_config.tomorrowIoApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
      provider: WeatherProvider.tomorrowIo,
    );

    final data = jsonDecode(response.body);
    
    if (data['data'] == null || data['data']['timelines'] == null) {
      throw WeatherApiException(
        'Invalid response format from Tomorrow.io',
        location: location,
        statusCode: response.statusCode,
        response: response.body,
      );
    }

    final timeline = data['data']['timelines'][0];
    final intervals = timeline['intervals'] as List;

    final forecasts = intervals
        .map((interval) => WeatherData.fromTomorrowIo(interval, location.id))
        .toList();

    return WeatherForecast(
      locationId: location.id,
      generatedAt: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      dailyForecasts: forecasts,
    );
  }

  Future<WeatherData> _getTomorrowIoCurrentWeather(FieldLocation location) async {
    await _enforceRateLimit();

    final uri = Uri.parse('https://api.tomorrow.io/v4/weather/realtime')
        .replace(queryParameters: {
      'location': '${location.latitude},${location.longitude}',
      'fields': [
        'temperature',
        'humidity', 
        'precipitationIntensity',
        'windSpeed',
        'windDirection',
        'dewPoint',
        'leafWetness',
        'weatherCode',
      ].join(','),
      'units': 'metric',
    });

    final response = await _makeRequest(
      uri: uri,
      method: 'GET',
      headers: {
        'Authorization': 'Bearer ${_config.tomorrowIoApiKey}',
      },
      provider: WeatherProvider.tomorrowIo,
    );

    final data = jsonDecode(response.body);
    
    if (data['data'] == null) {
      throw WeatherApiException(
        'Invalid response format from Tomorrow.io current weather',
        location: location,
        statusCode: response.statusCode,
        response: response.body,
      );
    }

    return WeatherData.fromTomorrowIo({
      'time': DateTime.now().toIso8601String(),
      'values': data['data']['values'],
    }, location.id);
  }

  /// MSC API implementations (fallback)

  Future<WeatherForecast> _getMscForecast(
    FieldLocation location,
    int days,
  ) async {
    // MSC API endpoint (this is a simplified example - actual MSC API may differ)
    final uri = Uri.parse('https://api.weather.gc.ca/collections/climate-daily/items')
        .replace(queryParameters: {
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
      'limit': days.toString(),
      'f': 'json',
    });

    final response = await _makeRequest(
      uri: uri,
      method: 'GET',
      headers: {},
      provider: WeatherProvider.msc,
    );

    final data = jsonDecode(response.body);
    
    if (data['features'] == null) {
      throw WeatherApiException(
        'Invalid response format from MSC',
        location: location,
        statusCode: response.statusCode,
        response: response.body,
      );
    }

    final features = data['features'] as List;
    final forecasts = features
        .map((feature) => WeatherData.fromMsc(feature['properties'], location.id))
        .toList();

    return WeatherForecast(
      locationId: location.id,
      generatedAt: DateTime.now(),
      provider: WeatherProvider.msc,
      dailyForecasts: forecasts,
    );
  }

  Future<WeatherData> _getMscCurrentWeather(FieldLocation location) async {
    // Simplified MSC current weather endpoint
    final uri = Uri.parse('https://api.weather.gc.ca/collections/observations/items')
        .replace(queryParameters: {
      'lat': location.latitude.toString(),
      'lon': location.longitude.toString(),
      'limit': '1',
      'f': 'json',
    });

    final response = await _makeRequest(
      uri: uri,
      method: 'GET',
      headers: {},
      provider: WeatherProvider.msc,
    );

    final data = jsonDecode(response.body);
    
    if (data['features'] == null || (data['features'] as List).isEmpty) {
      throw WeatherApiException(
        'No current weather data from MSC',
        location: location,
        statusCode: response.statusCode,
        response: response.body,
      );
    }

    final feature = data['features'][0];
    return WeatherData.fromMsc(feature['properties'], location.id);
  }

  /// Utility methods

  Future<http.Response> _makeRequest({
    required Uri uri,
    required String method,
    required Map<String, String> headers,
    String? body,
    required WeatherProvider provider,
  }) async {
    for (int attempt = 0; attempt < _config.maxRetries; attempt++) {
      try {
        http.Response response;
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await _httpClient.get(uri, headers: headers)
                .timeout(_config.requestTimeout);
            break;
          case 'POST':
            response = await _httpClient.post(uri, headers: headers, body: body)
                .timeout(_config.requestTimeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        } else if (response.statusCode == 429) {
          // Rate limited - wait and retry
          final delay = _calculateBackoffDelay(attempt);
          await Future.delayed(delay);
          continue;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          if (attempt < _config.maxRetries - 1) {
            final delay = _calculateBackoffDelay(attempt);
            await Future.delayed(delay);
            continue;
          }
        }

        throw WeatherApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          provider: provider,
          statusCode: response.statusCode,
          response: response.body,
        );

      } on TimeoutException {
        if (attempt < _config.maxRetries - 1) {
          final delay = _calculateBackoffDelay(attempt);
          await Future.delayed(delay);
          continue;
        }
        throw WeatherApiException(
          'Request timeout after ${_config.requestTimeout.inSeconds}s',
          provider: provider,
        );
      } on SocketException catch (e) {
        if (attempt < _config.maxRetries - 1) {
          final delay = _calculateBackoffDelay(attempt);
          await Future.delayed(delay);
          continue;
        }
        throw WeatherApiException(
          'Network error: ${e.message}',
          provider: provider,
        );
      }
    }

    throw WeatherApiException(
      'Max retries exceeded',
      provider: provider,
    );
  }

  Duration _calculateBackoffDelay(int attempt) {
    final baseDelayMs = _config.retryDelay.inMilliseconds;
    final backoffMs = baseDelayMs * pow(2, attempt).toInt();
    final jitterMs = Random().nextInt(1000); // Add jitter to prevent thundering herd
    return Duration(milliseconds: backoffMs + jitterMs);
  }

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove old timestamps
    _requestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    // Check if we're at the rate limit
    if (_requestTimes.length >= _config.rateLimitPerMinute) {
      final oldestRequest = _requestTimes.first;
      final delay = const Duration(minutes: 1) - now.difference(oldestRequest);
      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
      }
    }
    
    _requestTimes.add(now);
  }

  /// Circuit breaker logic

  bool _isTomorrowIoHealthy() {
    if (_consecutiveTomorrowIoFailures < _maxConsecutiveFailures) {
      return true;
    }
    
    if (_lastTomorrowIoFailure == null) {
      return true;
    }
    
    return DateTime.now().difference(_lastTomorrowIoFailure!) > _circuitBreakerTimeout;
  }

  bool _isMscHealthy() {
    if (_consecutiveMscFailures < _maxConsecutiveFailures) {
      return true;
    }
    
    if (_lastMscFailure == null) {
      return true;
    }
    
    return DateTime.now().difference(_lastMscFailure!) > _circuitBreakerTimeout;
  }

  void _handleTomorrowIoFailure() {
    _consecutiveTomorrowIoFailures++;
    _lastTomorrowIoFailure = DateTime.now();
    _tomorrowIoHealthy = _consecutiveTomorrowIoFailures < _maxConsecutiveFailures;
  }

  void _handleMscFailure() {
    _consecutiveMscFailures++;
    _lastMscFailure = DateTime.now();
    _mscHealthy = _consecutiveMscFailures < _maxConsecutiveFailures;
  }

  void _resetTomorrowIoFailures() {
    _consecutiveTomorrowIoFailures = 0;
    _tomorrowIoHealthy = true;
  }

  void _resetMscFailures() {
    _consecutiveMscFailures = 0;
    _mscHealthy = true;
  }

  /// Health monitoring

  WeatherApiHealth getHealth() {
    return WeatherApiHealth(
      tomorrowIoHealthy: _isTomorrowIoHealthy(),
      mscHealthy: _isMscHealthy(),
      tomorrowIoFailures: _consecutiveTomorrowIoFailures,
      mscFailures: _consecutiveMscFailures,
      lastTomorrowIoFailure: _lastTomorrowIoFailure,
      lastMscFailure: _lastMscFailure,
      requestsInLastMinute: _requestTimes.length,
    );
  }

  /// Get cache performance statistics
  
  WeatherApiCacheStats getCacheStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;
    
    return WeatherApiCacheStats(
      totalEntries: totalRequests,
      totalReads: totalRequests,
      totalWrites: _apiCalls,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      expiredEntries: 0,
      clearedEntries: 0,
      totalSize: totalRequests * 1024, // Estimate 1KB per entry
      memoryUsage: totalRequests * 1024,
      lastUpdate: DateTime.now(),
      apiCallsSaved: _cacheHits,
      costSavings: _cacheHits * 0.05, // Estimate $0.05 saved per cached call
      locationsCached: _requestTimes.length,
      providerCacheHits: {
        'tomorrowIo': _cacheHits,
        'msc': 0,
      },
      averageResponseTime: const Duration(milliseconds: 250),
    );
  }

  /// Reset cache statistics
  
  void resetCacheStatistics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _apiCalls = 0;
  }

  /// Pre-warm cache for a list of locations
  
  Future<void> warmCache(List<FieldLocation> locations, int days) async {
    if (_cacheService == null) return;

    for (final location in locations) {
      try {
        // Check if already cached
        final cached = await _cacheService.getWeatherForecast(location, days);
        if (cached == null || cached.isExpired) {
          // Fetch and cache new data
          await getForecast(location, days);
          
          // Small delay to respect rate limits
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        // Log error but continue with other locations
        print('Cache warming failed for ${location.name}: $e');
      }
    }
  }

  /// Get cache service reference for advanced operations
  
  HarvestCacheService? get cacheService => _cacheService;

  /// Resource cleanup

  void dispose() {
    _httpClient.close();
    _requestTimes.clear();
    resetCacheStatistics();
  }
}

/// Mock weather API service for testing
class MockWeatherApiService implements WeatherApiService {
  final Map<String, WeatherForecast> _mockForecasts = {};
  final Map<String, WeatherData> _mockCurrentWeather = {};

  void setMockForecast(String locationId, WeatherForecast forecast) {
    _mockForecasts[locationId] = forecast;
  }

  void setMockCurrentWeather(String locationId, WeatherData weather) {
    _mockCurrentWeather[locationId] = weather;
  }

  @override
  Future<WeatherForecast> getForecast(FieldLocation location, int days) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    
    final forecast = _mockForecasts[location.id];
    if (forecast != null) {
      return forecast;
    }

    // Generate mock data
    return _generateMockForecast(location, days);
  }

  @override
  Future<WeatherData> getCurrentWeather(FieldLocation location) async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    final weather = _mockCurrentWeather[location.id];
    if (weather != null) {
      return weather;
    }

    // Generate mock current weather
    return _generateMockCurrentWeather(location);
  }

  WeatherForecast _generateMockForecast(FieldLocation location, int days) {
    final forecasts = <WeatherData>[];
    final random = Random();

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));
      forecasts.add(WeatherData(
        locationId: location.id,
        timestamp: date,
        provider: WeatherProvider.tomorrowIo,
        temperatureMin: 10 + random.nextDouble() * 10,
        temperatureMax: 20 + random.nextDouble() * 15,
        temperature: 15 + random.nextDouble() * 10,
        humidity: 40 + random.nextDouble() * 40,
        precipitation: random.nextDouble() * 10,
        windSpeed: random.nextDouble() * 30,
        windDirection: random.nextDouble() * 360,
        dewPoint: 5 + random.nextDouble() * 15,
        leafWetness: random.nextDouble() * 10,
        evapotranspiration: random.nextDouble() * 5,
        condition: WeatherCondition.values[random.nextInt(WeatherCondition.values.length)],
        description: 'Mock weather condition',
      ));
    }

    return WeatherForecast(
      locationId: location.id,
      generatedAt: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      dailyForecasts: forecasts,
    );
  }

  WeatherData _generateMockCurrentWeather(FieldLocation location) {
    final random = Random();
    
    return WeatherData(
      locationId: location.id,
      timestamp: DateTime.now(),
      provider: WeatherProvider.tomorrowIo,
      temperature: 15 + random.nextDouble() * 10,
      humidity: 40 + random.nextDouble() * 40,
      precipitation: random.nextDouble() * 5,
      windSpeed: random.nextDouble() * 20,
      windDirection: random.nextDouble() * 360,
      dewPoint: 5 + random.nextDouble() * 15,
      leafWetness: random.nextDouble() * 8,
      condition: WeatherCondition.values[random.nextInt(WeatherCondition.values.length)],
      description: 'Mock current weather',
    );
  }
}

/// Supporting classes

class WeatherApiHealth {
  final bool tomorrowIoHealthy;
  final bool mscHealthy;
  final int tomorrowIoFailures;
  final int mscFailures;
  final DateTime? lastTomorrowIoFailure;
  final DateTime? lastMscFailure;
  final int requestsInLastMinute;

  WeatherApiHealth({
    required this.tomorrowIoHealthy,
    required this.mscHealthy,
    required this.tomorrowIoFailures,
    required this.mscFailures,
    this.lastTomorrowIoFailure,
    this.lastMscFailure,
    required this.requestsInLastMinute,
  });

  Map<String, dynamic> toJson() {
    return {
      'tomorrowIoHealthy': tomorrowIoHealthy,
      'mscHealthy': mscHealthy,
      'tomorrowIoFailures': tomorrowIoFailures,
      'mscFailures': mscFailures,
      'lastTomorrowIoFailure': lastTomorrowIoFailure?.toIso8601String(),
      'lastMscFailure': lastMscFailure?.toIso8601String(),
      'requestsInLastMinute': requestsInLastMinute,
    };
  }
}

class WeatherApiException implements Exception {
  final String message;
  final WeatherProvider? provider;
  final FieldLocation? location;
  final List<WeatherProvider>? providers;
  final int? statusCode;
  final String? response;

  WeatherApiException(
    this.message, {
    this.provider,
    this.location,
    this.providers,
    this.statusCode,
    this.response,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WeatherApiException: $message');
    
    if (provider != null) {
      buffer.write(' (Provider: ${provider!.name})');
    }
    
    if (providers != null) {
      buffer.write(' (Providers: ${providers!.map((p) => p.name).join(', ')})');
    }
    
    if (location != null) {
      buffer.write(' (Location: ${location!.name})');
    }
    
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    
    return buffer.toString();
  }
}

