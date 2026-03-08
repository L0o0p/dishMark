import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../data/collection.dart';
import '../data/dish_mark.dart';
import '../data/store.dart';
import '../data/trail.dart';

class IsarService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open([
      DishCollectionSchema,
      DishMarkSchema,
      StoreSchema,
      TrailSchema,
    ], directory: dir.path);
  }
}
