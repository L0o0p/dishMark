import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class DishMarkList extends StatefulWidget {
  const DishMarkList({super.key});

  @override
  State<DishMarkList> createState() => _DishMarkListState();
}

class _DishMarkListState extends State<DishMarkList> {
  List<DishMark> marks = [];

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'null';
    }
    return value.toLocal().toIso8601String();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await IsarService.isar.dishMarks.where().findAll();
    await Future.wait(data.map((m) => m.store.load()));
    if (!mounted) {
      return;
    }
    setState(() {
      marks = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DishMark")),
      body: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: marks.length,
        itemBuilder: (context, index) {
          final mark = marks[index];
          final store = mark.store.value;
          final flavors =
              mark.flavors.isEmpty
                  ? '(empty)'
                  : mark.flavors.map((f) => f.name).join(', ');

          return ListTile(
            title: Text('${mark.id}. ${mark.dishName}'),
            onTap: () async {
              final deleted = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => DishMarkDetail(markId: mark.id),
                ),
              );
              if (deleted == true) {
                loadData();
              }
            },

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('id: ${mark.id}'),
                Text('dishName: ${mark.dishName}'),
                Text('storeId: ${store?.id ?? 'null'}'),
                Text('storeName: ${store?.storeName ?? 'null'}'),
                Text('storeQueueLevel: ${store?.queueLevel.name ?? 'null'}'),
                Text('storeLatitude: ${store?.latitude ?? 'null'}'),
                Text('storeLongitude: ${store?.longitude ?? 'null'}'),
                Text('storeCreatedAt: ${_formatDate(store?.createdAt)}'),
                Text('storeUpdatedAt: ${_formatDate(store?.updatedAt)}'),
                Text('storeDeletedAt: ${_formatDate(store?.deletedAt)}'),
                Text('priceLevel: ${mark.priceLevel ?? 'null'}'),
                Text('flavors: $flavors'),
                Text('experienceNote: ${mark.experienceNote ?? 'null'}'),
                Text(
                  'imagePath: ${mark.imagePath.isEmpty ? '(empty)' : mark.imagePath}',
                ),
                Text('createdAt: ${_formatDate(mark.createdAt)}'),
                Text('updatedAt: ${_formatDate(mark.updatedAt)}'),
                Text('deletedAt: ${_formatDate(mark.deletedAt)}'),
                Text('lastTastedAt: ${_formatDate(mark.lastTastedAt)}'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateDishMark()),
          );
          loadData();
        },
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        // shape: customizations[index].$3,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
