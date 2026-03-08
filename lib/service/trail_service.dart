import 'package:isar/isar.dart';

import '../data/dish_mark.dart';
import '../data/trail.dart';
import 'isar_service.dart';

class TrailService {
  TrailService({Isar? isar}) : _isar = isar ?? IsarService.isar;

  final Isar _isar;

  Future<Trail> addTrail({
    required DishMark dishMark,
    String? note,
    int? rating,
    DateTime? visitedAt,
  }) async {
    final DateTime now = DateTime.now();
    final Trail trail = Trail()
      ..visitedAt = visitedAt ?? now
      ..createdAt = now
      ..note = note
      ..rating = rating;

    await _isar.writeTxn(() async {
      await _isar.trails.put(trail);
      await trail.dishMark.load();
      trail.dishMark.value = dishMark;
      await trail.dishMark.save();
      await _isar.trails.put(trail);
    });

    await trail.dishMark.load();
    return trail;
  }

  Future<List<Trail>> getAllTrails() async {
    final List<Trail> trails = await _isar.trails
        .filter()
        .deletedAtIsNull()
        .sortByVisitedAtDesc()
        .findAll();

    for (final Trail trail in trails) {
      await trail.dishMark.load();
    }
    return trails;
  }

  Future<Trail?> getTrailById(Id id) async {
    final Trail? trail = await _isar.trails.get(id);
    if (trail == null || trail.deletedAt != null) {
      return null;
    }
    await trail.dishMark.load();
    return trail;
  }

  Future<List<Trail>> getTrailsByDishMarkId(Id dishMarkId) async {
    final List<Trail> trails = await _isar.trails
        .filter()
        .dishMark((q) => q.idEqualTo(dishMarkId))
        .and()
        .deletedAtIsNull()
        .findAll();

    for (final Trail trail in trails) {
      await trail.dishMark.load();
    }
    return trails;
  }

  Future<void> updateTrail(Trail trail) async {
    await _isar.writeTxn(() async {
      trail..updatedAt = DateTime.now();
      await _isar.trails.put(trail);
    });
  }

  Future<void> deleteTrail(Id id) async {
    await _isar.writeTxn(() async {
      final Trail? trail = await _isar.trails.get(id);
      if (trail == null || trail.deletedAt != null) {
        return;
      }
      await trail.dishMark.load();
      trail.dishMark.value = null;
      await trail.dishMark.save();
      trail
        ..deletedAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await _isar.trails.put(trail);
    });
  }

  Future<bool> hasTrailForDishMark(Id dishMarkId) async {
    final int count = await _isar.trails
        .filter()
        .dishMark((q) => q.idEqualTo(dishMarkId))
        .and()
        .deletedAtIsNull()
        .count();
    return count > 0;
  }
}
