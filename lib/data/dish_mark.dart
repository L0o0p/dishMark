import 'package:isar/isar.dart';

part 'dish_mark.g.dart';

enum Flavor { spicy, sweet, savory, sour, bitter, fresh, greasy }

@collection
class DishMark {
  Id id = Isar.autoIncrement;

  late String dishName;
  late String storeId;

  int? priceLevel;
  @enumerated
  List<Flavor> flavors = [];

  String? experienceNote;

  String imagePath = '';

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
  DateTime? lastTastedAt;
}
