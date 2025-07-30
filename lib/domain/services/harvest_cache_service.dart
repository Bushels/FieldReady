/**
 * Harvest Cache Service for FieldReady
 * Implements intelligent caching for harvest operations
 */

import 'dart:async';
import '../models/harvest_models.dart';
import '../models/cache_models.dart';
import '../repositories/base_repositories.dart';
import 'harvest_intelligence.dart';

/// Harvest-specific caching service
class HarvestCacheService {
  final CacheRepository _cacheRepository;
  final Duration _defaultCacheDuration;
  final int _maxCacheSize;
  
  HarvestCacheService({
    required CacheRepository cacheRepository,
    Duration defaultCacheDuration = const Duration(hours: 1),
    int maxCacheSize = 1000,
  }) : _cacheRepository = cacheRepository,
       _defaultCacheDuration = defaultCacheDuration,
       _maxCacheSize = maxCacheSize;

  /// Cache weather forecast for a location
  Future<void> cacheWeatherForecast(
    FieldLocation location,
    WeatherForecast forecast,
  ) async {
    final key = 'weather_forecast_${location.id}';
    final entry = OfflineCache(
      id: key,
      userId: location.userId ?? 'system',
      key: key,
      data: forecast.toJson(),
      collection: 'weather_forecasts',
      documentId: location.id,
      expiresAt: DateTime.now().add(forecast.cacheDuration),
      dataSize: 1000, // Approximate size
      accessCount: 0,
      lastAccessed: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await _cacheRepository.setCacheEntry(key, location.userId ?? 'system', entry);
  }

  /// Get cached weather forecast
  Future<WeatherForecast?> getWeatherForecast(
    FieldLocation location,
    int days,
  ) async {
    final key = 'weather_forecast_${location.id}';
    final entry = await _cacheRepository.getCacheEntry(key, location.userId ?? 'system');
    
    if (entry == null || (entry.expiresAt?.isBefore(DateTime.now()) ?? false)) {
      return null;
    }
    
    try {
      return WeatherForecast.fromJson(entry.data);
    } catch (e) {
      // Invalid cache entry
      await _cacheRepository.delete(entry.id);
      return null;
    }
  }

  /// Cache combine capability assessment
  Future<void> cacheCombineCapability(
    String combineSpecId,
    CombineCapability capability,
  ) async {
    final key = 'combine_capability_$combineSpecId';
    final entry = OfflineCache(
      id: key,
      userId: 'system',
      key: key,
      data: capability.toJson(),
      collection: 'combine_capabilities',
      documentId: combineSpecId,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      dataSize: 500,
      accessCount: 0,
      lastAccessed: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await _cacheRepository.setCacheEntry(key, 'system', entry);
  }

  /// Get cached combine capability
  Future<CombineCapability?> getCombineCapability(String combineSpecId) async {
    final key = 'combine_capability_$combineSpecId';
    final entry = await _cacheRepository.getCacheEntry(key, 'system');
    
    if (entry == null || (entry.expiresAt?.isBefore(DateTime.now()) ?? false)) {
      return null;
    }
    
    try {
      return CombineCapability.fromJson(entry.data);
    } catch (e) {
      await _cacheRepository.delete(entry.id);
      return null;
    }
  }

  /// Cache harvest windows for a user
  Future<void> cacheHarvestWindows(
    String userId,
    List<FieldLocation> fields,
    CropType crop,
    List<HarvestWindow> windows,
  ) async {
    final fieldIds = fields.map((f) => f.id).join('_');
    final key = 'harvest_windows_${userId}_${crop.name}_$fieldIds';
    
    final entry = OfflineCache(
      id: key,
      userId: userId,
      key: key,
      data: {
        'windows': windows.map((w) => w.toJson()).toList(),
        'fieldIds': fields.map((f) => f.id).toList(),
        'crop': crop.name,
      },
      collection: 'harvest_windows',
      expiresAt: DateTime.now().add(_defaultCacheDuration),
      dataSize: 2000,
      accessCount: 0,
      lastAccessed: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    await _cacheRepository.setCacheEntry(key, userId, entry);
  }

  /// Get cached harvest windows
  Future<List<HarvestWindow>?> getHarvestWindows(
    String userId,
    List<FieldLocation> fields,
    CropType crop,
  ) async {
    final fieldIds = fields.map((f) => f.id).join('_');
    final key = 'harvest_windows_${userId}_${crop.name}_$fieldIds';
    
    final entry = await _cacheRepository.getCacheEntry(key, userId);
    
    if (entry == null || (entry.expiresAt?.isBefore(DateTime.now()) ?? false)) {
      return null;
    }
    
    try {
      final data = entry.data;
      final windowsData = data['windows'] as List;
      return windowsData.map((w) => HarvestWindow.fromJson(w)).toList();
    } catch (e) {
      await _cacheRepository.delete(entry.id);
      return null;
    }
  }

  /// Preload cache for a user
  Future<void> preloadCacheForUser(String userId) async {
    // This would typically load user's common locations and preferences
    // For now, just ensure cache is ready
    final stats = await _cacheRepository.getCacheStatistics(userId);
    if (stats.totalEntries > _maxCacheSize) {
      await performSmartEviction();
    }
  }

  /// Perform smart cache eviction
  Future<void> performSmartEviction() async {
    await _cacheRepository.clearExpiredEntries();
    
    // Additional smart eviction logic could be added here
    // e.g., remove least recently used entries
  }

  /// Get cache statistics
  CacheStatistics getStatistics() {
    // This would aggregate statistics from the repository
    // For now, return a new instance
    return CacheStatistics();
  }

  /// Clear all caches
  void clearAllCaches() {
    // This would clear all cache entries
    // Implementation depends on repository
  }
}