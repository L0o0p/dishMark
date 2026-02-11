enum QueueLevel { noQueue, within30Min, over1Hour, reservationNeeded }

class Store {
  final String id;
  final String storeName; // 店铺或品牌名称

  // 排队时长
  final QueueLevel?
  queueLevel; // noQueue / within30Min / over1Hour / reservationNeeded

  // 位置信息
  final double? latitude;
  final double? longitude;

  // 日期
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Store({
    required this.id,
    required this.storeName,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.latitude,
    this.longitude,
    this.queueLevel,
  });
}
