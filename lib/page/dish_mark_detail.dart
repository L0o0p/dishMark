import 'dart:io';

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/event_bus.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class DishMarkDetail extends StatefulWidget {
  final Id markId;

  const DishMarkDetail({super.key, required this.markId});

  @override
  State<DishMarkDetail> createState() => _DishMarkDetailState();
}

class _DishMarkDetailState extends State<DishMarkDetail> {
  final ImagePicker _imagePicker = ImagePicker();
  DishMark? mark;

  Future<String?> _pickImageAndSaveToSandbox() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return null;
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory imageDir = Directory('${appDocDir.path}/dish_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    final String originalName = pickedFile.name;
    final int dotIndex = originalName.lastIndexOf('.');
    final String extension = dotIndex >= 0
        ? originalName.substring(dotIndex).toLowerCase()
        : '.jpg';
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String targetPath = '${imageDir.path}/dish_$timestamp$extension';
    await pickedFile.saveTo(targetPath);
    return targetPath;
  }

  Widget _buildImagePreview(String imagePath) {
    final String path = imagePath.trim();
    final String localFilePath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    final Widget fallback = Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      color: SoftPalette.surfaceElevated,
      child: const Text('图片加载失败'),
    );

    Widget image;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      image = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (path.startsWith('assets/')) {
      image = Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (localFilePath.isNotEmpty) {
      image = Image.file(
        File(localFilePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(height: 150, width: double.infinity, child: image),
    );
  }

  String _formatQueueLevel(QueueLevel? level) {
    switch (level) {
      case QueueLevel.noQueue:
        return '几乎不用排队';
      case QueueLevel.within30Min:
        return '小于 30 分钟';
      case QueueLevel.over1Hour:
        return '大于 1 小时';
      case QueueLevel.reservationNeeded:
        return '建议预约';
      case null:
        return '-';
    }
  }

  String _formatFlavor(Flavor flavor) {
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
        return '清新';
      case Flavor.greasy:
        return '油润';
    }
  }

  String _formatPrice(double? price) {
    if (price == null) {
      return '-';
    }
    if (price == price.roundToDouble()) {
      return '￥${price.toStringAsFixed(0)}';
    }
    return '￥${price.toStringAsFixed(1)}';
  }

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
          title: const Text('删除记录'),
          content: const Text('确认删除这条菜品记忆吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: SoftPalette.danger,
                foregroundColor: Colors.white,
              ),
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
    // 事件通知
    DishEvents.deletedDishId.value = widget.markId;

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
    final noteController = TextEditingController(
      text: current.experienceNote ?? '',
    );
    String editedImagePath = current.imagePath;
    bool isPickingImage = false;
    QueueLevel selectedQueueLevel =
        current.store.value?.queueLevel ?? QueueLevel.noQueue;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑记录'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: storeController,
                      decoration: const InputDecoration(labelText: '店名'),
                    ),
                    DropdownButtonFormField<QueueLevel>(
                      initialValue: selectedQueueLevel,
                      decoration: const InputDecoration(labelText: '排队时长'),
                      items: QueueLevel.values.map((QueueLevel level) {
                        return DropdownMenuItem<QueueLevel>(
                          value: level,
                          child: Text(_formatQueueLevel(level)),
                        );
                      }).toList(),
                      onChanged: (QueueLevel? value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedQueueLevel = value;
                        });
                      },
                    ),
                    TextField(
                      controller: dishController,
                      decoration: const InputDecoration(labelText: '菜名'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            editedImagePath.trim().isEmpty
                                ? '还没有选择图片'
                                : '已选择一张图片',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: isPickingImage
                              ? null
                              : () async {
                                  setDialogState(() {
                                    isPickingImage = true;
                                  });
                                  try {
                                    final String? pickedPath =
                                        await _pickImageAndSaveToSandbox();
                                    if (!context.mounted) {
                                      return;
                                    }
                                    if (pickedPath != null) {
                                      setDialogState(() {
                                        editedImagePath = pickedPath;
                                      });
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('选择图片失败: $error'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setDialogState(() {
                                        isPickingImage = false;
                                      });
                                    }
                                  }
                                },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(isPickingImage ? '选择中' : '换图'),
                        ),
                      ],
                    ),
                    if (editedImagePath.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      _buildImagePreview(editedImagePath),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: '人均价格'),
                    ),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '用餐感受'),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: SoftPalette.accentOrange,
                foregroundColor: Colors.white,
              ),
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
      if (priceValue == null ||
          priceValue.isNaN ||
          priceValue.isInfinite ||
          priceValue < 0) {
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
        ..imagePath = editedImagePath.trim()
        ..priceLevel = priceValue
        ..experienceNote = note.isEmpty ? null : note
        ..updatedAt = DateTime.now();

      final existingStore = m.store.value;
      if (existingStore == null) {
        if (storeName.isNotEmpty) {
          final newStore = Store()
            ..storeName = storeName
            ..queueLevel = selectedQueueLevel
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();
          await IsarService.isar.stores.put(newStore);
          m.store.value = newStore;
          await m.store.save();
        }
      } else {
        existingStore
          ..queueLevel = selectedQueueLevel
          ..updatedAt = DateTime.now();
        if (storeName.isNotEmpty) {
          existingStore.storeName = storeName;
        }
        await IsarService.isar.stores.put(existingStore);
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
    final String storeName =
        mark!.store.value?.storeName.trim().isNotEmpty == true
        ? mark!.store.value!.storeName
        : '还没有店名';
    final String note = (mark!.experienceNote ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(mark!.dishName),
        actions: [
          IconButton(
            onPressed: _editMark,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: SoftDecorations.floatingCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 $storeName',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '排队感受：${_formatQueueLevel(mark!.store.value?.queueLevel)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '人均：${_formatPrice(mark!.priceLevel)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mark!.flavors.map((flavor) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: const BoxDecoration(
                          color: SoftPalette.tagBackground,
                          borderRadius: SoftRadius.tag,
                        ),
                        child: Text(
                          _formatFlavor(flavor),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: SoftPalette.tagForeground,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.isEmpty ? '还没有留下感受' : note,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _deleteMark,
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
                style: FilledButton.styleFrom(
                  backgroundColor: SoftPalette.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
