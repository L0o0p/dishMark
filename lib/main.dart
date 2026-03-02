import 'package:dishmark/page/dish_map.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/service/wechat_service.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await IsarService.init();
  await WeChatService.ensureInitialized();

  // 临时测试代码：写入测试数据
  // await _insertTestData();

  // 临时测试代码：读取测试数据
  await _readTestData();

  runApp(const MainApp());
}

/// 临时测试函数：插入测试数据
// Future<void> _insertTestData() async {
//   await IsarService.isar.writeTxn(() async {
//     final isar = IsarService.isar;

//     // 创建 Store 对象
//     final store = Store()
//       ..storeName = "Test Store"
//       ..queueLevel = QueueLevel.noQueue
//       ..createdAt = DateTime.now()
//       ..updatedAt = DateTime.now();

//     // 保存 Store 并获取其 ID
//     await isar.stores.put(store);

//     // 创建 DishMark 对象
//     final dishMark = DishMark()
//       ..dishName = "Test Dish"
//       ..flavors = [Flavor.spicy]
//       ..createdAt = DateTime.now()
//       ..updatedAt = DateTime.now();

//     dishMark.store.value = store;

//     // 保存 DishMark
//     await isar.dishMarks.put(dishMark);
//     await dishMark.store.save();
//   });
// }

/// 临时测试函数：读取测试数据
Future<void> _readTestData() async {
  final isar = IsarService.isar;

  final all = await isar.dishMarks.where().findAll();
  debugPrint('记录数量: ${all.length}');

  // 可选：遍历并打印每条记录的详细信息
  for (final mark in all) {
    await mark.store.load();
    final dishName = mark.dishName;
    final storeName = mark.store.value?.storeName ?? '(no store)';
    final flavors = mark.flavors;
    final createdAt = mark.createdAt;
    debugPrint(
      'DishMark: $dishName, StoreName: $storeName, Flavors: $flavors, CreatedAt: $createdAt',
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SoftSpatialTheme.build(),
      home: const DishMap(),
    );
  }
}
