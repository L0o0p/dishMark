import 'dart:io';

import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/service/share_link_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  DishMark? newDishMark;
  List<Flavor> selectedFlavors = [];
  bool _isFlavorPanelExpanded = true;
  QueueLevel _selectedQueueLevel = QueueLevel.noQueue;
  int _queueUiIndex = 0;
  String? _selectedImagePath;
  bool _isPickingImage = false;
  String? _resolvedLocationLabel;
  static const List<String> _queueChoiceLabels = <String>[
    '不用排队',
    '< 30 min',
    '< 60 min',
    '> 60 min',
    '建议预约',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrapStoreName();
    _queueUiIndex = _queueLevelToUiIndex(_selectedQueueLevel);
  }

  Future<void> _bootstrapStoreName() async {
    final String coordinateFallbackLabel = _coordinateLocationLabel();
    if (coordinateFallbackLabel.isNotEmpty) {
      storeController.text = coordinateFallbackLabel;
    }

    final LatLng? location = widget.currentLocation;
    if (location == null) {
      _logGeocode('currentLocation is null, skip reverse geocode.');
      return;
    }

    final String? readableLocation = await _reverseGeocodeWithSystem(location);
    if (!mounted || readableLocation == null || readableLocation.isEmpty) {
      if (!mounted) {
        return;
      }
      _logGeocode(
        'reverse geocode fallback to coordinate label: "$coordinateFallbackLabel".',
      );
      return;
    }

    // 仅在用户尚未手动修改输入框时覆盖自动填充值。
    final String currentText = storeController.text.trim();
    final bool canOverwriteAutoText =
        currentText.isEmpty || currentText == coordinateFallbackLabel;

    _resolvedLocationLabel = readableLocation;
    if (canOverwriteAutoText) {
      storeController.text = readableLocation;
    }
    _logGeocode('resolved readable location: "$readableLocation".');
  }

  Future<String?> _reverseGeocodeWithSystem(LatLng location) async {
    _logGeocode(
      'start system reverse geocode, location=${location.latitude},${location.longitude}',
    );
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isEmpty) {
        _logGeocode('placemark list is empty.');
        return null;
      }

      final Placemark place = placemarks.first;
      final List<String> parts = <String>[
        if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          place.subLocality!.trim(),
        if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          place.administrativeArea!.trim(),
      ];
      final List<String> unique = <String>[];
      for (final String part in parts) {
        if (part.isEmpty || unique.contains(part)) {
          continue;
        }
        unique.add(part);
      }
      final String readable = unique.take(2).join(' · ');
      return readable.isEmpty ? null : readable;
    } catch (error) {
      _logGeocode('system reverse geocode exception: $error');
      return null;
    }
  }

  void _logGeocode(String message) {
    debugPrint('[LOC-GEOCODE] $message');
  }

  String _currentLocationStoreLabel() {
    final String suggestion = _resolvedLocationLabel ?? '';
    if (suggestion.isNotEmpty) {
      return suggestion;
    }
    return _coordinateLocationLabel();
  }

  String _coordinateLocationLabel() {
    final LatLng? location = widget.currentLocation;
    if (location == null) {
      return '';
    }
    return '当前位置 ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
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

  int _queueLevelToUiIndex(QueueLevel level) {
    switch (level) {
      case QueueLevel.noQueue:
        return 0;
      case QueueLevel.within30Min:
        return 1;
      case QueueLevel.over1Hour:
        return 3;
      case QueueLevel.reservationNeeded:
        return 4;
    }
  }

  QueueLevel _uiIndexToQueueLevel(int index) {
    switch (index) {
      case 0:
        return QueueLevel.noQueue;
      case 1:
      case 2:
        return QueueLevel.within30Min;
      case 3:
        return QueueLevel.over1Hour;
      case 4:
        return QueueLevel.reservationNeeded;
      default:
        return QueueLevel.noQueue;
    }
  }

  void _updateQueueByUiIndex(int index) {
    setState(() {
      _queueUiIndex = index.clamp(0, _queueChoiceLabels.length - 1).toInt();
      _selectedQueueLevel = _uiIndexToQueueLevel(_queueUiIndex);
    });
  }

  void _fillStoreNameByGpsSuggestion() {
    final String suggestion = _currentLocationStoreLabel();
    if (suggestion.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无可填入的附近店名')));
      return;
    }
    setState(() {
      storeController.text = suggestion;
    });
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

    final dishName = dishController.text.trim();
    if (dishName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少填写一个菜品名称')));
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
      final String storeName = storeController.text.trim();
      final String fallbackStoreName = _currentLocationStoreLabel();
      final store = Store()
        ..storeName = storeName.isEmpty ? fallbackStoreName : storeName
        ..queueLevel = _selectedQueueLevel
        // 保存时始终使用当前位置经纬度，不受店名编辑影响。
        ..latitude = currentLocation.latitude
        ..longitude = currentLocation.longitude
        ..createdAt = storeNow
        ..updatedAt = storeNow;

      await IsarService.isar.stores.put(store);

      final now = DateTime.now();
      final dish = DishMark()
        ..dishName = dishName
        ..store.value = store
        ..imagePath = imagePath
        ..priceLevel = priceValue
        ..flavors = selectedFlavors
        ..experienceNote = experienceController.text
        ..createdAt = now
        ..updatedAt = now
        ..lastTastedAt = now;

      await IsarService.isar.dishMarks.put(dish);
      dish.shareUrl = ShareLinkService.buildMomentShareUrlById(dish.id);
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
    super.dispose();
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.floatingCard(),
      child: child,
    );
  }

  Widget _buildTitledSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildSectionCard(child: child),
      ],
    );
  }

  void _toggleFlavor(Flavor flavor) {
    setState(() {
      if (selectedFlavors.contains(flavor)) {
        selectedFlavors.remove(flavor);
      } else {
        selectedFlavors.add(flavor);
      }
    });
  }

  Widget _buildFlavorOptionChip(Flavor flavor) {
    final bool isSelected = selectedFlavors.contains(flavor);
    return GestureDetector(
      onTap: () => _toggleFlavor(flavor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _getFlavorLabel(flavor),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : SoftPalette.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFlavorSection() {
    final String selectedText = selectedFlavors.isEmpty
        ? '暂无选择口味标签'
        : selectedFlavors.map((flavor) => _getFlavorLabel(flavor)).join('、');

    return _buildTitledSection(
      title: '口味标签',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SoftPalette.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _isFlavorPanelExpanded = !_isFlavorPanelExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '选择口味',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: SoftPalette.textSecondary),
                          ),
                        ),
                        Icon(
                          _isFlavorPanelExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: SoftPalette.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Flavor.values
                          .map(_buildFlavorOptionChip)
                          .toList(),
                    ),
                  ),
                  crossFadeState: _isFlavorPanelExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 160),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection() {
    return _buildTitledSection(
      title: '店名',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: storeController,
                  decoration: const InputDecoration(hintText: '搜索或输入店名'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: FilledButton.tonalIcon(
                  onPressed: _fillStoreNameByGpsSuggestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F2F2),
                    foregroundColor: SoftPalette.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.pin_drop_outlined, size: 16),
                  label: const Text('定位'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: SoftPalette.accentOrange,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '基于当前位置 GPS 位置自动填充',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SoftPalette.textSecondary,
                  ),
                ),
              ),
              // TextButton(
              //   onPressed: _fillStoreNameByGpsSuggestion,
              //   style: TextButton.styleFrom(
              //     foregroundColor: SoftPalette.accentOrange,
              //     padding: const EdgeInsets.symmetric(horizontal: 8),
              //     minimumSize: const Size(36, 28),
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //   ),
              //   child: const Text('填入'),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDishPriceRow(
    TextEditingController dishNameCtrl,
    TextEditingController priceCtrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: dishNameCtrl,
            decoration: const InputDecoration(hintText: '菜品名称'),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: TextField(
            controller: priceCtrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '¥',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDishAndPriceSection() {
    return _buildTitledSection(
      title: '菜品与价格',
      child: _buildDishPriceRow(dishController, priceController),
    );
  }

  Widget _buildQueueSection() {
    final selectedLabel = _queueChoiceLabels[_queueUiIndex];
    return _buildTitledSection(
      title: '排队时间',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '当前选择',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SoftPalette.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: SoftPalette.accentOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  selectedLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SoftPalette.accentOrange,
              inactiveTrackColor: SoftPalette.outline.withValues(alpha: 0.6),
              thumbColor: SoftPalette.surface,
              overlayColor: SoftPalette.accentOrange.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 5,
            ),
            child: Slider(
              value: _queueUiIndex.toDouble(),
              min: 0,
              max: (_queueChoiceLabels.length - 1).toDouble(),
              divisions: _queueChoiceLabels.length - 1,
              onChanged: (value) => _updateQueueByUiIndex(value.round()),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _queueChoiceLabels.asMap().entries.map((entry) {
              final int index = entry.key;
              final String label = entry.value;
              final bool selected = index == _queueUiIndex;
              final Color dotColor = selected
                  ? SoftPalette.accentOrange
                  : SoftPalette.outline;
              final Color textColor = selected
                  ? SoftPalette.accentOrange
                  : SoftPalette.textSecondary;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _updateQueueByUiIndex(index),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Column(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: dotColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildTitledSection(
      title: '图片',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _isPickingImage ? null : _pickImageAndSaveToSandbox,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _selectedImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(_selectedImagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 40,
                                  color: SoftPalette.accentOrange,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击添加图片',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: SoftPalette.textPlaceholder,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 40,
                            color: SoftPalette.accentOrange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击添加图片',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: SoftPalette.textPlaceholder),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _buildTitledSection(
      title: '简评',
      child: TextField(
        controller: experienceController,
        decoration: const InputDecoration(hintText: '留下一句记忆里的味道'),
        maxLines: 3,
      ),
    );
  }

  Widget _buildLocationSection() {
    return _buildTitledSection(
      title: '当前位置',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记录这一餐')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   '码住一次被记住的味道～',
              //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //     color: SoftPalette.textSecondary,
              //   ),
              // ),
              const SizedBox(height: 24),
              _buildStoreSection(),
              const SizedBox(height: 24),
              _buildDishAndPriceSection(),
              const SizedBox(height: 24),

              _buildImageSection(),
              const SizedBox(height: 24),
              _buildFlavorSection(),
              const SizedBox(height: 24),
              _buildExperienceSection(),
              const SizedBox(height: 24),
              _buildQueueSection(),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                _buildLocationSection(),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: save,
                  style: FilledButton.styleFrom(
                    backgroundColor: SoftPalette.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
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
