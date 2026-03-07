import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/collection_list.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/collection_service.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';

class DishMarkList extends StatefulWidget {
  const DishMarkList({super.key});

  @override
  State<DishMarkList> createState() => _DishMarkListState();
}

class _DishMarkListState extends State<DishMarkList> {
  List<DishMark> marks = <DishMark>[];
  final CollectionService _collectionService = CollectionService();
  final TextEditingController _collectionNameController =
      TextEditingController();
  final TextEditingController _collectionDescriptionController =
      TextEditingController();
  bool isSelectionMode = false;
  Set<int> selectedDishIds = {};

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

  Future<void> _showCreateCollectionSheet() async {
    if (selectedDishIds.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择要创建集合的美食记录'),
          backgroundColor: SoftPalette.accentOrange,
        ),
      );
      return;
    }

    _collectionNameController.clear();
    _collectionDescriptionController.clear();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Container(
            decoration: SoftDecorations.floatingCard(
              borderRadius: SoftRadius.largeCard,
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: SoftPalette.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '创建集合',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    '将加入 ${selectedDishIds.length} 道菜',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(color: SoftPalette.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _collectionNameController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: '集合名称 *',
                      hintText: '例如：本周想吃、川菜精选',
                    ),
                    validator: (String? value) {
                      final String text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return '请填写集合名称';
                      }
                      if (text.length > 50) {
                        return '集合名称不能超过 50 个字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _collectionDescriptionController,
                    maxLength: 200,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '描述（可选）',
                      hintText: '简单描述这个集合',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }
                        try {
                          await _collectionService.createCollection(
                            _collectionNameController.text,
                            _collectionDescriptionController.text,
                            selectedDishIds.toList(growable: false),
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, true);
                          }
                        } catch (error) {
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text('创建失败：$error')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('创建集合'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (created == true) {
      if (!mounted) {
        return;
      }
      setState(() {
        isSelectionMode = false;
        selectedDishIds.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('集合创建成功')));
    }
  }

  @override
  void dispose() {
    _collectionNameController.dispose();
    _collectionDescriptionController.dispose();
    super.dispose();
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
    final bool isSelected = selectedDishIds.contains(mark.id);

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          setState(() {
            if (isSelected) {
              selectedDishIds.remove(mark.id);
            } else {
              selectedDishIds.add(mark.id);
            }
          });
        } else {
          Navigator.pop<int>(context, mark.id);
        }
      },
      onLongPress: () async {
        if (isSelectionMode) {
          return;
        }
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
        decoration: BoxDecoration(
          color: isSelected
              ? SoftPalette.accentOrangeSoft.withValues(alpha: 0.3)
              : SoftPalette.surface,
          borderRadius: SoftRadius.card,
          border: Border.all(
            color: isSelected
                ? SoftPalette.accentOrange
                : SoftPalette.outline.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mark.dishName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (isSelectionMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SoftPalette.accentOrange
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? SoftPalette.accentOrange
                                  : SoftPalette.textSecondary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ],
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
      appBar: AppBar(
        title: Text(
          isSelectionMode ? '已选择 ${selectedDishIds.length} 个' : '美食记忆清单',
        ),
        actions: [
          if (!isSelectionMode)
            IconButton(
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const CollectionListPage()),
                );
              },
              icon: const Icon(Icons.folder_outlined),
              tooltip: '集合',
            ),
          if (!isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  isSelectionMode = true;
                });
              },
              child: const Text(
                '选择',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedDishIds.clear();
                });
              },
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
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
      floatingActionButton: isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _showCreateCollectionSheet,
              backgroundColor: SoftPalette.accentOrangeSoft,
              foregroundColor: SoftPalette.textPrimary,
              icon: const Icon(Icons.folder_outlined),
              label: const Text('创建集合'),
            )
          : _buildListActionButton(
              label: '添加',
              emphasized: true,
              icon: SvgPicture.asset(
                'assets/create_button.svg',
                width: SoftMapActionTokens.centerIconSize,
                height: SoftMapActionTokens.centerIconSize,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateDishMark()),
                );
                await loadData();
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildListActionButton({
    required String label,
    required Widget icon,
    required Future<void> Function() onPressed,
    bool emphasized = false,
  }) {
    final TextStyle defaultLabelStyle =
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildListActionButtonBody(
          onPressed: onPressed,
          emphasized: emphasized,
          child: icon,
        ),
        const SizedBox(height: SoftMapActionTokens.labelSpacing),
        Text(
          label,
          style: defaultLabelStyle.copyWith(
            color: SoftPalette.textPlaceholder,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildListActionButtonBody({
    required Widget child,
    required Future<void> Function() onPressed,
    bool emphasized = false,
  }) {
    final double size = emphasized
        ? SoftMapActionTokens.centerButtonSize
        : SoftMapActionTokens.sideButtonSize;
    final BorderRadius borderRadius = BorderRadius.circular(size / 2.5);

    return Container(
      width: size,
      height: size,
      decoration: SoftDecorations.mapActionShadow(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: SoftMapActionTokens.blurSigma,
            sigmaY: SoftMapActionTokens.blurSigma,
          ),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: SoftDecorations.mapActionGlassButton(
                borderRadius: borderRadius,
                emphasized: emphasized,
              ),
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: borderRadius,
                ),
                onTap: () {
                  unawaited(onPressed());
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: SoftDecorations.mapActionInnerHighlight(
                        borderRadius: borderRadius,
                      ),
                    ),
                    Center(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
