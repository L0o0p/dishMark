import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../data/dish_mark.dart';
import '../data/store.dart';

class IsarService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open([DishMarkSchema, StoreSchema], directory: dir.path);
  }
}
