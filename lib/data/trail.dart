import 'package:isar/isar.dart';

import 'package:dishmark/data/dish_mark.dart';

part 'trail.g.dart';

@collection
class Trail {
  Id id = Isar.autoIncrement;

  final dishMark = IsarLink<DishMark>();

  String? note;
  int? rating;

  late DateTime visitedAt;
  late DateTime createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
}
