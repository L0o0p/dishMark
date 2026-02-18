import 'dart:collection';

import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';

class CreateDishMark extends StatefulWidget {
  final LatLng? currentLocation;
  final String? initialStoreName;

  const CreateDishMark({
    super.key,
    this.currentLocation,
    this.initialStoreName,
  });

  @override
  State<CreateDishMark> createState() => _CreateDishMarkState();
}

class _CreateDishMarkState extends State<CreateDishMark> {
  final TextEditingController storeController = TextEditingController();
  final TextEditingController dishController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController flavorsController = TextEditingController();
  DishMark? newDishMark;
  List<Flavor> selectedFlavors = [];

  @override
  void initState() {
    super.initState();
    final String initialStoreName = widget.initialStoreName?.trim() ?? '';
    if (initialStoreName.isNotEmpty) {
      storeController.text = initialStoreName;
    }
  }

  Future<void> _selectFlavors() async {
    final result = await showDialog<List<Flavor>>(
      context: context,
      builder: (BuildContext context) {
        return _FlavorSelectionDialog(selectedFlavors: selectedFlavors);
      },
    );
    if (result != null) {
      setState(() {
        selectedFlavors = result;
      });
      flavorsController.text = selectedFlavors
          .map((flavor) => _getFlavorLabel(flavor))
          .join(', ');
    }
  }

  String _getFlavorLabel(Flavor flavor) {
    switch (flavor) {
      case Flavor.spicy:
        return '辛辣';
      case Flavor.sweet:
        return '甜';
      case Flavor.savory:
        return '咸鲜';
      case Flavor.sour:
        return '酸';
      case Flavor.bitter:
        return '苦';
      case Flavor.fresh:
        return '新鲜';
      case Flavor.greasy:
        return '油腻';
    }
  }

  Future<void> save() async {
    final currentLocation = widget.currentLocation;
    if (currentLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('尚未获取当前位置，请稍后重试')));
      return;
    }

    // 解析价格
    double? priceValue;
    final priceText = priceController.text.trim();
    if (priceText.isNotEmpty) {
      try {
        priceValue = double.parse(priceText);
        // 验证价格是否为有效数字（非 NaN 且非负）
        if (priceValue.isNaN || priceValue.isInfinite || priceValue < 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('价格必须是有效的非负数字')));
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('价格格式错误，请输入有效的数字')));
        return;
      }
    }

    await IsarService.isar.writeTxn(() async {
      final store = Store()
        ..storeName = storeController.text
        ..queueLevel = QueueLevel.noQueue
        ..latitude = currentLocation.latitude
        ..longitude = currentLocation.longitude
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await IsarService.isar.stores.put(store);

      final dish = DishMark()
        ..dishName = dishController.text
        ..store.value = store
        ..imagePath = "placeholder.jpg"
        ..priceLevel = priceValue
        ..flavors = selectedFlavors
        ..experienceNote = experienceController.text
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await IsarService.isar.dishMarks.put(dish);
      await dish.store.save();
      newDishMark = dish;
    });

    if (newDishMark != null) {
      Navigator.pop(context, newDishMark);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    storeController.dispose();
    dishController.dispose();
    priceController.dispose();
    experienceController.dispose();
    flavorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create DishMark")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: storeController,
              decoration: const InputDecoration(
                labelText: "Store Name | Location",
              ),
            ),
            TextField(
              controller: dishController,
              decoration: const InputDecoration(labelText: "Dish Name"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "价格 (Price Level)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: flavorsController,
              decoration: const InputDecoration(labelText: "口味 (Flavors)"),
              readOnly: true,
              onTap: _selectFlavors,
            ),
            TextField(
              controller: experienceController,
              decoration: const InputDecoration(
                labelText: "用餐体验 (Experience Note)",
                hintText: "输入您的用餐体验...",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.currentLocation == null
                    ? '当前位置: 未获取'
                    : '当前位置: ${widget.currentLocation!.latitude.toStringAsFixed(5)}, ${widget.currentLocation!.longitude.toStringAsFixed(5)}',
              ),
            ),
            ElevatedButton(onPressed: save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}

class _FlavorSelectionDialog extends StatefulWidget {
  final List<Flavor> selectedFlavors;

  const _FlavorSelectionDialog({required this.selectedFlavors});

  @override
  State<_FlavorSelectionDialog> createState() => _FlavorSelectionDialogState();
}

class _FlavorSelectionDialogState extends State<_FlavorSelectionDialog> {
  late List<Flavor> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = List<Flavor>.from(widget.selectedFlavors);
  }

  String _getFlavorLabel(Flavor flavor) {
    switch (flavor) {
      case Flavor.spicy:
        return '辛辣';
      case Flavor.sweet:
        return '甜';
      case Flavor.savory:
        return '咸鲜';
      case Flavor.sour:
        return '酸';
      case Flavor.bitter:
        return '苦';
      case Flavor.fresh:
        return '新鲜';
      case Flavor.greasy:
        return '油腻';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('选择口味', style: Theme.of(context).textTheme.titleLarge),
          ),
          ...Flavor.values.map(
            (flavor) => CheckboxListTile(
              title: Text(_getFlavorLabel(flavor)),
              value: _tempSelection.contains(flavor),
              onChanged: (isSelected) {
                setState(() {
                  if (isSelected == true) {
                    if (!_tempSelection.contains(flavor)) {
                      _tempSelection.add(flavor);
                    }
                  } else {
                    _tempSelection.remove(flavor);
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _tempSelection);
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
