enum Flavor { spicy, sweet, savory, sour, bitter, fresh, greasy }

class DishMark {
  final String id;
  final String dishName;
  final String storeId; // 店铺或品牌名称
  final int tasteTimes;// 累计食用次数

  // 各种tag
  final int? priceLevel; // 1~5
  final List<Flavor> flavors;

  // 用餐体验
  final String? experienceNote; // 一句话描写用餐体验

  // 图片
  final String imagePath;
  // 日期
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime lastTastedAt;

  DishMark({
    required this.id,
    required this.dishName,
    required this.storeId,
    required this.tasteTimes,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.lastTastedAt,
    this.priceLevel,
    this.flavors = const [],
    this.experienceNote,
  });
}
