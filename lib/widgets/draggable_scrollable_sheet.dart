import 'dart:io';

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/event_bus.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

class DraggableScrollableSheetExample extends StatefulWidget {
  const DraggableScrollableSheetExample({super.key, required this.dishId});

  final Id dishId;

  @override
  State<DraggableScrollableSheetExample> createState() =>
      _DraggableScrollableSheetExampleState();
}

class _DraggableScrollableSheetExampleState
    extends State<DraggableScrollableSheetExample> {
  static const double _collapsedSize = 0.30;
  static const double _expandedSize = 1.0;

  DishMark? _dish;
  Store? _store;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDish();
  }

  Future<void> _loadDish({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final DishMark? mark = await IsarService.isar.dishMarks.get(widget.dishId);
    if (mark == null) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }
    await mark.store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _dish = mark;
      _store = mark.store.value;
      _isLoading = false;
    });
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
        return '新鲜';
      case Flavor.greasy:
        return '油腻';
    }
  }

  String _formatQueueLevel(QueueLevel? queueLevel) {
    switch (queueLevel) {
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

  String _formatPrice(double? price) {
    if (price == null) {
      return '-';
    }
    if (price == price.roundToDouble()) {
      return '￥${price.toStringAsFixed(0)}';
    }
    return '￥${price.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    final String hh = date.hour.toString().padLeft(2, '0');
    final String mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatNote(String? note) {
    final String trimmed = (note ?? '').trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }

  String _buildShareText() {
    final DishMark? mark = _dish;
    if (mark == null) {
      return '';
    }
    final String storeName = _store?.storeName.trim().isNotEmpty == true
        ? _store!.storeName
        : '未知店铺';
    final String tags = mark.flavors.take(4).map(_formatFlavor).join(' / ');
    final String note = (mark.experienceNote ?? '').trim();
    return '推荐菜：${mark.dishName}\n店铺：$storeName\n口味：${tags.isEmpty ? '-' : tags}\n备注：${note.isEmpty ? '-' : note}';
  }

  Future<void> _shareDish() async {
    final String text = _buildShareText();
    if (text.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享文案已复制到剪贴板')));
  }

  Future<void> _editDish() async {
    final DishMark? mark = _dish;
    if (mark == null) {
      return;
    }
    final bool? deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DishMarkDetail(markId: mark.id)),
    );
    if (!mounted) {
      return;
    }
    if (deleted == true) {
      Navigator.of(context).maybePop();
      return;
    }
    await _loadDish(showLoading: false);
  }

  Future<void> _deleteDish() async {
    final DishMark? mark = _dish;
    if (mark == null) {
      return;
    }
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('删除条目'),
          content: const Text('确认删除这条菜品记录吗？'),
          actions: <Widget>[
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
    if (shouldDelete != true) {
      return;
    }
    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.dishMarks.delete(mark.id);
    });
    DishEvents.deletedDishId.value = mark.id;
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }

  Widget _buildDishImage({
    required double width,
    required double height,
    required BorderRadius borderRadius,
  }) {
    final String imagePath = (_dish?.imagePath ?? '').trim();
    final String localFilePath = imagePath.startsWith('file://')
        ? Uri.parse(imagePath).toFilePath()
        : imagePath;
    final Widget fallback = Image.asset('assets/logo.jpg', fit: BoxFit.cover);
    Widget image;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      image = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (imagePath.startsWith('assets/')) {
      image = Image.asset(
        imagePath,
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
      image = fallback;
    }
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }

  Widget _buildFlavorPills({required int maxCount}) {
    final List<Flavor> flavors = _dish?.flavors ?? const <Flavor>[];
    if (flavors.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<Flavor> visible = flavors.take(maxCount).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visible.map((Flavor flavor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF4B00C9),
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          child: Text(
            _formatFlavor(flavor),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCollapsedLayout() {
    final DishMark? mark = _dish;
    if (mark == null) {
      return const SizedBox.shrink();
    }
    final String storeName = _store?.storeName.trim().isNotEmpty == true
        ? _store!.storeName
        : '未知店铺';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildDishImage(
          width: 84,
          height: 84,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                mark.dishName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '📍 $storeName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF7D7D7D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _buildFlavorPills(maxCount: 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedLayout() {
    final DishMark? mark = _dish;
    if (mark == null) {
      return const SizedBox.shrink();
    }
    final String storeName = _store?.storeName.trim().isNotEmpty == true
        ? _store!.storeName
        : '未知店铺';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                mark.dishName,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: _shareDish,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F1F1),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.ios_share_outlined),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '📍 $storeName',
          style: const TextStyle(
            fontSize: 20,
            color: Color(0xFF7D7D7D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildFlavorPills(maxCount: 4),
        const SizedBox(height: 16),
        _buildDishImage(
          width: double.infinity,
          height: 360,
          borderRadius: const BorderRadius.all(Radius.circular(28)),
        ),
        const SizedBox(height: 24),
        Text(
          '价格：${_formatPrice(mark.priceLevel)}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          '排队时长：${_formatQueueLevel(_store?.queueLevel)}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          '简评：${_formatNote(mark.experienceNote)}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          '上一次品尝：${_formatDate(mark.lastTastedAt)}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 12),
        // Text(
        //   '图片路径：${mark.imagePath.trim().isEmpty ? '-' : mark.imagePath.trim()}',
        //   style: const TextStyle(fontSize: 18),
        // ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _shareDish,
                icon: const Icon(Icons.share_outlined),
                label: const Text('分享'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _editDish,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('编辑'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _deleteDish,
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _onExtentChanged(DraggableScrollableNotification notification) {
    final bool nextExpanded = notification.extent > 0.55;
    if (nextExpanded != _isExpanded && mounted) {
      setState(() {
        _isExpanded = nextExpanded;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _onExtentChanged,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: _collapsedSize,
        minChildSize: _collapsedSize,
        maxChildSize: _expandedSize,
        snap: true,
        snapSizes: const <double>[_collapsedSize, _expandedSize],
        shouldCloseOnMinExtent: true,
        builder: (BuildContext context, ScrollController scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 64,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _isExpanded
                                ? _buildExpandedLayout()
                                : _buildCollapsedLayout(),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
