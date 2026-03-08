import 'package:isar/isar.dart';

import '../data/collection.dart';
import '../data/dish_mark.dart';
import 'isar_service.dart';

class CollectionService {
  CollectionService({Isar? isar}) : _isar = isar ?? IsarService.isar;

  final Isar _isar;

  Future<DishCollection> createCollection(
    String name,
    String? description, [
    List<Id> dishIds = const <Id>[],
  ]) async {
    final String normalizedName = _normalizeName(name);
    final String? normalizedDescription = _normalizeDescription(description);
    final DateTime now = DateTime.now();

    final DishCollection collection = DishCollection()
      ..name = normalizedName
      ..description = normalizedDescription
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.dishCollections.put(collection);
      if (dishIds.isNotEmpty) {
        final List<DishMark> dishes = await _findDishesByIds(dishIds);
        if (dishes.isNotEmpty) {
          collection.dishMarks.addAll(dishes);
          await collection.dishMarks.save();
        }
      }
      await _refreshCoverImage(collection);
      await _isar.dishCollections.put(collection);
    });

    await collection.dishMarks.load();
    return collection;
  }

  Future<List<DishCollection>> getAllCollections() async {
    final List<DishCollection> collections = await _isar.dishCollections
        .filter()
        .deletedAtIsNull()
        .sortByCreatedAtDesc()
        .findAll();

    for (final DishCollection collection in collections) {
      await collection.dishMarks.load();
    }
    return collections;
  }

  Future<DishCollection?> getCollectionById(Id id) async {
    final DishCollection? collection = await _isar.dishCollections.get(id);
    if (collection == null || collection.deletedAt != null) {
      return null;
    }
    await collection.dishMarks.load();
    return collection;
  }

  Future<void> updateCollection(DishCollection collection) async {
    final String normalizedName = _normalizeName(collection.name);
    final String? normalizedDescription = _normalizeDescription(
      collection.description,
    );

    await _isar.writeTxn(() async {
      collection
        ..name = normalizedName
        ..description = normalizedDescription
        ..updatedAt = DateTime.now();
      await _refreshCoverImage(collection);
      await _isar.dishCollections.put(collection);
    });
  }

  Future<void> deleteCollection(Id id) async {
    await _isar.writeTxn(() async {
      final DishCollection? collection = await _isar.dishCollections.get(id);
      if (collection == null || collection.deletedAt != null) {
        return;
      }
      await collection.dishMarks.load();
      collection.dishMarks.clear();
      await collection.dishMarks.save();
      collection
        ..deletedAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..coverImagePath = null;
      await _isar.dishCollections.put(collection);
    });
  }

  Future<void> addDishesToCollection(Id collectionId, List<Id> dishIds) async {
    if (dishIds.isEmpty) {
      return;
    }
    await _isar.writeTxn(() async {
      final DishCollection? collection = await _isar.dishCollections.get(
        collectionId,
      );
      if (collection == null || collection.deletedAt != null) {
        return;
      }
      final List<DishMark> dishes = await _findDishesByIds(dishIds);
      if (dishes.isEmpty) {
        return;
      }
      await collection.dishMarks.load();
      collection.dishMarks.addAll(dishes);
      await collection.dishMarks.save();
      collection.updatedAt = DateTime.now();
      await _refreshCoverImage(collection);
      await _isar.dishCollections.put(collection);
    });
  }

  Future<void> removeDishFromCollection(Id collectionId, Id dishId) async {
    await _isar.writeTxn(() async {
      final DishCollection? collection = await _isar.dishCollections.get(
        collectionId,
      );
      if (collection == null || collection.deletedAt != null) {
        return;
      }

      await collection.dishMarks.load();
      DishMark? targetDish;
      for (final DishMark dish in collection.dishMarks) {
        if (dish.id == dishId) {
          targetDish = dish;
          break;
        }
      }
      if (targetDish == null) {
        return;
      }

      collection.dishMarks.remove(targetDish);
      await collection.dishMarks.save();
      collection.updatedAt = DateTime.now();
      await _refreshCoverImage(collection);
      await _isar.dishCollections.put(collection);
    });
  }

  String _normalizeName(String name) {
    final String normalized = name.trim();
    if (normalized.isEmpty || normalized.length > 50) {
      throw ArgumentError('Collection name must be 1-50 characters.');
    }
    return normalized;
  }

  String? _normalizeDescription(String? description) {
    final String? normalized = description?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    if (normalized.length > 200) {
      throw ArgumentError('Collection description must be <= 200 characters.');
    }
    return normalized;
  }

  Future<List<DishMark>> _findDishesByIds(List<Id> dishIds) async {
    final List<Id> uniqueIds = dishIds.toSet().toList(growable: false);
    final List<DishMark?> dishes = await _isar.dishMarks.getAll(uniqueIds);
    return dishes.whereType<DishMark>().toList(growable: false);
  }

  Future<void> _refreshCoverImage(DishCollection collection) async {
    await collection.dishMarks.load();
    for (final DishMark dish in collection.dishMarks) {
      final String path = dish.imagePath.trim();
      if (path.isNotEmpty) {
        collection.coverImagePath = path;
        return;
      }
    }
    collection.coverImagePath = null;
  }
}
