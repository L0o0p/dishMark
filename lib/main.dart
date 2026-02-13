import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await IsarService.init();

  // 临时测试代码：写入测试数据
  // await _insertTestData();

  // 临时测试代码：读取测试数据
  await _readTestData();

  runApp(const MainApp());
}

/// 临时测试函数：插入测试数据
Future<void> _insertTestData() async {
  await IsarService.isar.writeTxn(() async {
    // 创建 Store 对象
    final store = Store()
      ..storeName = "Test Store"
      ..queueLevel = QueueLevel.noQueue
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    // 保存 Store 并获取其 ID
    final storeId = await IsarService.isar.stores.put(store);

    // 创建 DishMark 对象
    final dishMark = DishMark()
      ..dishName = "Test Dish"
      ..storeId = storeId.toString()
      ..flavors = [Flavor.spicy]
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    // 保存 DishMark
    await IsarService.isar.dishMarks.put(dishMark);
  });
}

/// 临时测试函数：读取测试数据
Future<void> _readTestData() async {
  final all = await IsarService.isar.dishMarks.where().findAll();
  print('记录数量: ${all.length}');

  // 可选：遍历并打印每条记录的详细信息
  for (final mark in all) {
    final dishName = mark.dishName;
    final storeId = mark.storeId;
    final flavors = mark.flavors;
    final createdAt = mark.createdAt;
    print(
      'DishMark: $dishName, StoreId: $storeId, Flavors: $flavors, CreatedAt: $createdAt',
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
