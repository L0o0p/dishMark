import 'dart:io';

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class DishMarkList extends StatefulWidget {
  const DishMarkList({super.key});

  @override
  State<DishMarkList> createState() => _DishMarkListState();
}

class _DishMarkListState extends State<DishMarkList> {
  List<DishMark> marks = <DishMark>[];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final List<DishMark> data = await IsarService.isar.dishMarks
        .where()
        .findAll();
    await Future.wait(data.map((m) => m.store.load()));
    if (!mounted) {
      return;
    }
    setState(() {
      marks = data;
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
        return '清新';
      case Flavor.greasy:
        return '油润';
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final DateTime local = value.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Widget _buildDishImage(String imagePath) {
    final String path = imagePath.trim();
    final String localFilePath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    final Widget fallback = Image.asset('assets/logo.png', fit: BoxFit.cover);

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (localFilePath.isNotEmpty) {
      return Image.file(
        File(localFilePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }

  Widget _buildFlavorPills(DishMark mark) {
    if (mark.flavors.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: mark.flavors.take(3).map((Flavor flavor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: const BoxDecoration(
            color: SoftPalette.tagBackground,
            borderRadius: SoftRadius.tag,
          ),
          child: Text(
            _formatFlavor(flavor),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: SoftPalette.tagForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDishCard(DishMark mark) {
    final String storeName =
        mark.store.value?.storeName.trim().isNotEmpty == true
        ? mark.store.value!.storeName
        : '还没有店名';
    final String note = (mark.experienceNote ?? '').trim();

    return GestureDetector(
      onTap: () => Navigator.pop<int>(context, mark.id),
      onLongPress: () async {
        final bool? deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => DishMarkDetail(markId: mark.id)),
        );
        if (!mounted) {
          return;
        }
        if (deleted == true) {
          await loadData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: SoftDecorations.floatingCard(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 92,
                height: 92,
                child: _buildDishImage(mark.imagePath),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mark.dishName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 $storeName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFlavorPills(mark),
                  const SizedBox(height: 8),
                  Text(
                    note.isEmpty ? '还没有留下感受' : note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '记录于 ${_formatDate(mark.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('美食记忆清单')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: marks.isEmpty
            ? Center(
                child: Text(
                  '还没有记录，去地图里点一个地点开始吧',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SoftPalette.textSecondary,
                  ),
                ),
              )
            : RefreshIndicator(
                color: SoftPalette.accentOrange,
                onRefresh: loadData,
                child: ListView.builder(
                  itemCount: marks.length,
                  itemBuilder: (context, index) {
                    return _buildDishCard(marks[index]);
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateDishMark()),
          );
          await loadData();
        },
        backgroundColor: SoftPalette.accentOrangeSoft,
        foregroundColor: SoftPalette.textPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
