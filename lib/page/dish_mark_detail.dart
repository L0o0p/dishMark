import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
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

  Future<void> _deleteMark() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除条目'),
          content: const Text('确认删除这条菜品记录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.dishMarks.delete(widget.markId);
    });

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _editMark() async {
    final current = mark;
    if (current == null) return;

    final storeController = TextEditingController(
      text: current.store.value?.storeName ?? '',
    );
    final dishController = TextEditingController(text: current.dishName);
    final priceController = TextEditingController(
      text: current.priceLevel?.toString() ?? '',
    );
    final noteController = TextEditingController(text: current.experienceNote ?? '');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑条目'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: storeController,
                  decoration: const InputDecoration(labelText: 'Store Name'),
                ),
                TextField(
                  controller: dishController,
                  decoration: const InputDecoration(labelText: 'Dish Name'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '价格 (Price Level)'),
                ),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '用餐体验 (Note)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      storeController.dispose();
      dishController.dispose();
      priceController.dispose();
      noteController.dispose();
      return;
    }

    final storeName = storeController.text.trim();
    final dishName = dishController.text.trim();
    final note = noteController.text.trim();
    final priceText = priceController.text.trim();

    if (dishName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dish Name 不能为空')));
      }
      storeController.dispose();
      dishController.dispose();
      priceController.dispose();
      noteController.dispose();
      return;
    }

    double? priceValue;
    if (priceText.isNotEmpty) {
      priceValue = double.tryParse(priceText);
      if (priceValue == null || priceValue.isNaN || priceValue.isInfinite || priceValue < 0) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('价格必须是有效的非负数字')));
        }
        storeController.dispose();
        dishController.dispose();
        priceController.dispose();
        noteController.dispose();
        return;
      }
    }

    await IsarService.isar.writeTxn(() async {
      final m = await IsarService.isar.dishMarks.get(widget.markId);
      if (m == null) return;

      await m.store.load();

      m
        ..dishName = dishName
        ..priceLevel = priceValue
        ..experienceNote = note.isEmpty ? null : note
        ..updatedAt = DateTime.now();

      if (storeName.isNotEmpty) {
        final existingStore = m.store.value;
        if (existingStore == null) {
          final newStore = Store()
            ..storeName = storeName
            ..queueLevel = QueueLevel.noQueue
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await IsarService.isar.stores.put(newStore);
          m.store.value = newStore;
          await m.store.save();
        } else {
          existingStore
            ..storeName = storeName
            ..updatedAt = DateTime.now();
          await IsarService.isar.stores.put(existingStore);
        }
      }

      await IsarService.isar.dishMarks.put(m);
    });

    storeController.dispose();
    dishController.dispose();
    priceController.dispose();
    noteController.dispose();

    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (mark == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(mark!.dishName),
        actions: [
          IconButton(
            onPressed: _editMark, 
            icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
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
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _deleteMark,
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
