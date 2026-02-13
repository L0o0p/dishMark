import 'package:isar/isar.dart';

import 'package:dishmark/data/store.dart';

part 'dish_mark.g.dart';

enum Flavor { spicy, sweet, savory, sour, bitter, fresh, greasy }

@collection
class DishMark {
  Id id = Isar.autoIncrement;

  late String dishName;
  final store = IsarLink<Store>();

  double? priceLevel;
  @enumerated
  List<Flavor> flavors = [];

  String? experienceNote;

  String imagePath = '';

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? lastTastedAt;
}
