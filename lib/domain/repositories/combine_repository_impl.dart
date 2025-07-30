/**
 * Concrete implementation of CombineRepository
 * Provides a basic implementation for testing and development
 */

import '../models/combine_models.dart';
import 'combine_repository.dart';

/// Basic implementation of CombineRepository
class CombineRepositoryImpl extends CombineRepository {
  final Map<String, CombineSpec> _cache = {};
  
  @override
  Future<CombineSpec?> getById(String id) async {
    return _cache[id];
  }

  @override
  Future<List<CombineSpec>> getAll() async {
    return _cache.values.toList();
  }

  @override
  Future<String> create(CombineSpec item) async {
    _cache[item.id] = item;
    return item.id;
  }

  @override
  Future<void> update(String id, CombineSpec item) async {
    _cache[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
  }

  @override
  Future<void> syncWithRemote() async {
    // Basic implementation - would sync with Firebase in real app
  }

  @override
  Future<List<CombineSpec>> getByBrand(String brand) async {
    return _cache.values
        .where((spec) => spec.brand.toLowerCase() == brand.toLowerCase())
        .toList();
  }

  @override
  Future<List<CombineSpec>> getByModel(String brand, String model) async {
    return _cache.values
        .where((spec) => 
            spec.brand.toLowerCase() == brand.toLowerCase() &&
            spec.model.toLowerCase() == model.toLowerCase())
        .toList();
  }

  @override
  Future<List<CombineSpec>> getByRegion(String region) async {
    return _cache.values
        .where((spec) => spec.region?.toLowerCase() == region.toLowerCase())
        .toList();
  }

  @override
  Future<List<CombineSpec>> search(String query) async {
    final lowerQuery = query.toLowerCase();
    return _cache.values
        .where((spec) =>
            spec.brand.toLowerCase().contains(lowerQuery) ||
            spec.model.toLowerCase().contains(lowerQuery))
        .toList();
  }

  @override
  Future<List<CombineSpec>> getUserSpecs(String userId) async {
    return _cache.values
        .where((spec) => spec.userId == userId)
        .toList();
  }

  @override
  Future<List<CombineSpec>> getPublicSpecs({String? region, String? crop}) async {
    var specs = _cache.values.where((spec) => spec.isPublic);
    
    if (region != null) {
      specs = specs.where((spec) => spec.region?.toLowerCase() == region.toLowerCase());
    }
    
    // For crop filtering, we'd need to check if the spec supports the crop
    // This is a simplified implementation
    
    return specs.toList();
  }

  @override
  Future<void> updateMoistureTolerance(String specId, MoistureTolerance tolerance) async {
    final spec = _cache[specId];
    if (spec != null) {
      final updatedSpec = spec.copyWith(
        moistureTolerance: tolerance,
        updatedAt: DateTime.now(),
      );
      _cache[specId] = updatedSpec;
    }
  }

  @override
  Future<void> updateToughCropAbility(String specId, ToughCropAbility ability) async {
    final spec = _cache[specId];
    if (spec != null) {
      final updatedSpec = spec.copyWith(
        toughCropAbility: ability,
        updatedAt: DateTime.now(),
      );
      _cache[specId] = updatedSpec;
    }
  }

  @override
  Future<void> batchUpdate(List<CombineSpec> specs) async {
    for (final spec in specs) {
      _cache[spec.id] = spec;
    }
  }

  @override
  Future<List<CombineSpec>> getPendingSync() async {
    // In a real implementation, this would return specs that need syncing
    return [];
  }

  @override
  Future<void> markSynced(String specId) async {
    // Mark the spec as synced - in real implementation this would update sync status
  }
}

/// Basic implementation of UserCombineRepository
class UserCombineRepositoryImpl extends UserCombineRepository {
  final Map<String, UserCombine> _cache = {};

  @override
  Future<UserCombine?> getById(String id) async {
    return _cache[id];
  }

  @override
  Future<List<UserCombine>> getAll() async {
    return _cache.values.toList();
  }

  @override
  Future<String> create(UserCombine item) async {
    _cache[item.id] = item;
    return item.id;
  }

  @override
  Future<void> update(String id, UserCombine item) async {
    _cache[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
  }

  @override
  Future<List<UserCombine>> getByUserId(String userId) async {
    return _cache.values
        .where((combine) => combine.userId == userId)
        .toList();
  }

  @override
  Future<List<UserCombine>> getActiveCombines(String userId) async {
    return _cache.values
        .where((combine) => combine.userId == userId && combine.isActive)
        .toList();
  }

  @override
  Future<UserCombine?> getByNickname(String userId, String nickname) async {
    try {
      return _cache.values.firstWhere(
        (combine) => combine.userId == userId && combine.nickname == nickname,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateCustomSettings(String combineId, Map<String, dynamic> settings) async {
    final combine = _cache[combineId];
    if (combine != null) {
      final updated = combine.copyWith(
        customSettings: settings,
        updatedAt: DateTime.now(),
      );
      _cache[combineId] = updated;
    }
  }

  @override
  Future<void> addCropExperience(String combineId, String crop, int rating, String notes) async {
    // In a real implementation, this would add crop experience data
  }

  @override
  Future<void> setActive(String combineId, bool isActive) async {
    final combine = _cache[combineId];
    if (combine != null) {
      final updated = combine.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      _cache[combineId] = updated;
    }
  }

  @override
  Future<List<UserCombine>> getPendingSync() async {
    return [];
  }
}