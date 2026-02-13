import 'package:isar/isar.dart';

part 'store.g.dart';

enum QueueLevel { noQueue, within30Min, over1Hour, reservationNeeded }

@collection
class Store {
  Id id = Isar.autoIncrement;

  late String storeName;

  @enumerated
  late QueueLevel queueLevel;

  double? latitude;
  double? longitude;

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
}
