import 'dart:io';

import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  DishMark? newDishMark;
  List<Flavor> selectedFlavors = [];
  QueueLevel _selectedQueueLevel = QueueLevel.noQueue;
  String? _selectedImagePath;
  bool _isPickingImage = false;

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

  String _getQueueLevelLabel(QueueLevel level) {
    switch (level) {
      case QueueLevel.noQueue:
        return '几乎不用排队';
      case QueueLevel.within30Min:
        return '小于 30 分钟';
      case QueueLevel.over1Hour:
        return '大于 1 小时';
      case QueueLevel.reservationNeeded:
        return '建议预约';
    }
  }

  Future<void> _pickImageAndSaveToSandbox() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;

      final appDocDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDocDir.path}/dish_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final originalName = pickedFile.name;
      final dotIndex = originalName.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? originalName.substring(dotIndex).toLowerCase()
          : '.jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${imageDir.path}/dish_$timestamp$extension';

      await pickedFile.saveTo(targetPath);
      if (!mounted) return;
      setState(() {
        _selectedImagePath = targetPath;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
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

    final imagePath = _selectedImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择图片')));
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
      final storeNow = DateTime.now();
      final store = Store()
        ..storeName = storeController.text
        ..queueLevel = _selectedQueueLevel
        ..latitude = currentLocation.latitude
        ..longitude = currentLocation.longitude
        ..createdAt = storeNow
        ..updatedAt = storeNow;

      await IsarService.isar.stores.put(store);

      final now = DateTime.now();
      final dish = DishMark()
        ..dishName = dishController.text
        ..store.value = store
        ..imagePath = imagePath
        ..priceLevel = priceValue
        ..flavors = selectedFlavors
        ..experienceNote = experienceController.text
        ..createdAt = now
        ..updatedAt = now
        ..lastTastedAt = now;

      await IsarService.isar.dishMarks.put(dish);
      await dish.store.save();
      newDishMark = dish;
    });

    if (!mounted) return;
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.floatingCard(),
      child: child,
    );
  }

  Widget _buildFlavorPillsPreview() {
    if (selectedFlavors.isEmpty) {
      return Text(
        '还没有添加口味标签',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: SoftPalette.textSecondary),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selectedFlavors.map((Flavor flavor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: SoftPalette.tagBackground,
            borderRadius: SoftRadius.tag,
          ),
          child: Text(
            _getFlavorLabel(flavor),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: SoftPalette.tagForeground),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录这一餐')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('写下一次被记住的味道', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '轻轻记录，不需要一次写完',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SoftPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                child: Column(
                  children: [
                    TextField(
                      controller: storeController,
                      decoration: const InputDecoration(labelText: '店名 / 地点'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dishController,
                      decoration: const InputDecoration(labelText: '吃了什么'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<QueueLevel>(
                      initialValue: _selectedQueueLevel,
                      decoration: const InputDecoration(labelText: '排队感受'),
                      items: QueueLevel.values.map((level) {
                        return DropdownMenuItem<QueueLevel>(
                          value: level,
                          child: Text(_getQueueLevelLabel(level)),
                        );
                      }).toList(),
                      onChanged: (QueueLevel? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedQueueLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: '人均价格'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedImagePath == null ? '还没有选择图片' : '已选择一张图片',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: _isPickingImage
                              ? null
                              : _pickImageAndSaveToSandbox,
                          style: FilledButton.styleFrom(
                            backgroundColor: SoftPalette.accentOrangeSoft,
                            foregroundColor: SoftPalette.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(_isPickingImage ? '选择中' : '选图'),
                        ),
                      ],
                    ),
                    if (_selectedImagePath != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_selectedImagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              alignment: Alignment.center,
                              color: SoftPalette.surfaceElevated,
                              child: const Text('图片加载失败'),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: flavorsController,
                      decoration: const InputDecoration(
                        labelText: '口味标签',
                        hintText: '选择口味印象',
                        suffixIcon: Icon(Icons.chevron_right_rounded),
                      ),
                      readOnly: true,
                      onTap: _selectFlavors,
                    ),
                    const SizedBox(height: 10),
                    _buildFlavorPillsPreview(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: experienceController,
                      decoration: const InputDecoration(
                        labelText: '今日感受',
                        hintText: '留下一句记忆里的味道',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.currentLocation == null
                            ? '当前位置还没准备好'
                            : '当前位置 ${widget.currentLocation!.latitude.toStringAsFixed(5)}, ${widget.currentLocation!.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SoftPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: save,
                  style: FilledButton.styleFrom(
                    backgroundColor: SoftPalette.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('保存这段记忆'),
                ),
              ),
            ],
          ),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: SoftDecorations.floatingCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                '选择口味',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...Flavor.values.map(
              (flavor) => CheckboxListTile(
                activeColor: SoftPalette.accentOrange,
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
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _tempSelection);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: SoftPalette.accentOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
