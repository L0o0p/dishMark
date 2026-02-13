import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class DishMap extends StatefulWidget {
  const DishMap({super.key});

  @override
  State<DishMap> createState() => _DishMapState();
}

class _DishMapState extends State<DishMap> {
  List<DishMark> marks = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await IsarService.isar.dishMarks.where().findAll();
    await Future.wait(data.map((m) => m.store.load()));
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
          return ListTile(
            title: Text(mark.dishName),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DishMarkDetail(markId: mark.id),
                ),
              );
            },

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Store: ${mark.store.value?.storeName ?? '(no store)'}"),
                Text("Price Level: ${mark.priceLevel ?? 'N/A'}"),
                Text("Flavors: ${mark.flavors.map((f) => f.name).join(', ')}"),
                Text("Created: ${mark.createdAt.toLocal()}"),
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
        child: const Icon(Icons.navigation),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
