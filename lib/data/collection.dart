import 'package:isar/isar.dart';

import 'package:dishmark/data/dish_mark.dart';

part 'collection.g.dart';

@collection
class DishCollection {
  Id id = Isar.autoIncrement;

  late String name;
  String? description;
  String? coverImagePath;

  final dishMarks = IsarLinks<DishMark>();

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
}
