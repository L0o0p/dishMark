import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class DishMarkDetail extends StatefulWidget {
  final Id markId;

  const DishMarkDetail({super.key, required this.markId});

  @override
  State<DishMarkDetail> createState() => _DishMarkDetailState();
}

class _DishMarkDetailState extends State<DishMarkDetail> {
  DishMark? mark;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final m = await IsarService.isar.dishMarks.get(widget.markId);
    if (m != null) {
      await m.store.load();
      if (!mounted) return;
      setState(() {
        mark = m;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mark == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(mark!.dishName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Store: ${mark!.store.value?.storeName ?? '(no store)'}"),
            const SizedBox(height: 10),
            Text("Price Level: ${mark!.priceLevel ?? "-"}"),
            const SizedBox(height: 10),
            Text("Flavors: ${mark!.flavors.map((f) => f.name).join(", ")}"),
            const SizedBox(height: 20),
            Text("Note: ${mark!.experienceNote ?? ""}"),
          ],
        ),
      ),
    );
  }
}
