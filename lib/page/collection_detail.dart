import 'dart:io';

import 'package:dishmark/data/collection.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/dish_mark_detail.dart';
import 'package:dishmark/service/collection_service.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:dishmark/widgets/share_collection_card.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class CollectionDetailPage extends StatefulWidget {
  const CollectionDetailPage({super.key, required this.collectionId});

  final Id collectionId;

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  final CollectionService _collectionService = CollectionService();

  DishCollection? _collection;
  List<DishMark> _dishes = <DishMark>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final DishCollection? collection = await _collectionService
        .getCollectionById(widget.collectionId);
    if (collection == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _collection = null;
        _dishes = <DishMark>[];
        _isLoading = false;
      });
      return;
    }

    final List<DishMark> dishes = collection.dishMarks
        .where((DishMark dish) => dish.deletedAt == null)
        .toList(growable: false);
    await Future.wait(dishes.map((DishMark dish) => dish.store.load()));

    if (!mounted) {
      return;
    }
    setState(() {
      _collection = collection;
      _dishes = dishes;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Widget _buildDishImage(String imagePath) {
    final String path = imagePath.trim();
    final Widget fallback = Image.asset('assets/logo.png', fit: BoxFit.cover);
    if (path.isEmpty) {
      return fallback;
    }
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
    final String localFilePath = path.startsWith('file://')
        ? Uri.parse(path).toFilePath()
        : path;
    return Image.file(
      File(localFilePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Future<void> _showEditCollectionSheet() async {
    final DishCollection? collection = _collection;
    if (collection == null) {
      return;
    }

    final TextEditingController nameController = TextEditingController(
      text: collection.name,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: collection.description ?? '',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final bool? updated = await showModalBottomSheet<bool>(
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
                          '编辑集合',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: '集合名称 *'),
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
                    controller: descriptionController,
                    maxLength: 200,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '描述（可选）'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }
                        collection
                          ..name = nameController.text
                          ..description = descriptionController.text;
                        await _collectionService.updateCollection(collection);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext, true);
                        }
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (updated == true) {
      await _loadData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('集合已更新')));
    }
  }

  Future<void> _deleteCollection() async {
    final DishCollection? collection = _collection;
    if (collection == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('删除集合'),
          content: Text('确认删除「${collection.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: SoftPalette.danger,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await _collectionService.deleteCollection(collection.id);
    if (!mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _removeDish(DishMark dish) async {
    final DishCollection? collection = _collection;
    if (collection == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('移除菜品'),
          content: Text('从集合中移除「${dish.dishName}」？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    await _collectionService.removeDishFromCollection(collection.id, dish.id);
    await _loadData();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已移除该菜品')));
  }

  Future<void> _showAddDishesSheet() async {
    final DishCollection? collection = _collection;
    if (collection == null) {
      return;
    }
    final List<DishMark> allDishes = await IsarService.isar.dishMarks
        .where()
        .findAll();
    await Future.wait(allDishes.map((DishMark dish) => dish.store.load()));

    final Set<Id> existingIds = _dishes.map((DishMark dish) => dish.id).toSet();
    final List<DishMark> candidates = allDishes
        .where(
          (DishMark dish) =>
              dish.deletedAt == null && !existingIds.contains(dish.id),
        )
        .toList(growable: false);

    if (!mounted) {
      return;
    }

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可添加的菜品')));
      return;
    }

    final Set<Id> selectedIds = <Id>{};
    final int? addedCount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setSheetState,
              ) {
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
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
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
                                '添加菜品',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '已选 ${selectedIds.length}',
                              style: Theme.of(sheetContext).textTheme.bodySmall
                                  ?.copyWith(color: SoftPalette.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: candidates.length,
                            itemBuilder: (BuildContext context, int index) {
                              final DishMark dish = candidates[index];
                              final bool checked = selectedIds.contains(
                                dish.id,
                              );
                              final String storeName =
                                  dish.store.value?.storeName
                                          .trim()
                                          .isNotEmpty ==
                                      true
                                  ? dish.store.value!.storeName
                                  : '还没有店名';
                              return CheckboxListTile(
                                value: checked,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  dish.dishName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onChanged: (_) {
                                  setSheetState(() {
                                    if (checked) {
                                      selectedIds.remove(dish.id);
                                    } else {
                                      selectedIds.add(dish.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: selectedIds.isEmpty
                                ? null
                                : () async {
                                    await _collectionService
                                        .addDishesToCollection(
                                          collection.id,
                                          selectedIds.toList(growable: false),
                                        );
                                    if (sheetContext.mounted) {
                                      Navigator.pop(
                                        sheetContext,
                                        selectedIds.length,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('完成'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );

    if (addedCount != null && addedCount > 0) {
      await _loadData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已添加 $addedCount 个菜品')));
    }
  }

  Future<void> _shareCollection() async {
    final DishCollection? collection = _collection;
    if (collection == null) {
      return;
    }
    await Future.wait(_dishes.map((DishMark dish) => dish.store.load()));
    if (!mounted) {
      return;
    }
    await showCollectionShareSheet(
      context: context,
      collection: collection,
      dishes: _dishes,
    );
  }

  Widget _buildDishCard(DishMark dish) {
    final String storeName =
        dish.store.value?.storeName.trim().isNotEmpty == true
        ? dish.store.value!.storeName
        : '还没有店名';
    return Dismissible(
      key: ValueKey<int>(dish.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _removeDish(dish);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: SoftPalette.danger.withValues(alpha: 0.85),
          borderRadius: SoftRadius.card,
        ),
        child: const Icon(Icons.remove_circle_outline, color: Colors.white),
      ),
      child: InkWell(
        borderRadius: SoftRadius.card,
        onTap: () async {
          final bool? deleted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => DishMarkDetail(markId: dish.id)),
          );
          if (deleted == true) {
            await _loadData();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: SoftDecorations.floatingCard(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: _buildDishImage(dish.imagePath),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.dishName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 $storeName',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: dish.flavors.take(3).map((Flavor flavor) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: SoftPalette.tagBackground,
                            borderRadius: SoftRadius.tag,
                          ),
                          child: Text(
                            _formatFlavor(flavor),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: SoftPalette.tagForeground),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final DishCollection? collection = _collection;
    if (collection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('集合详情')),
        body: Center(
          child: Text(
            '集合不存在或已删除',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: SoftPalette.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            onPressed: _shareCollection,
            icon: const Icon(Icons.share_outlined),
            tooltip: '分享',
          ),
          IconButton(
            onPressed: _showEditCollectionSheet,
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
          ),
          IconButton(
            onPressed: _deleteCollection,
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: SoftDecorations.floatingCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_dishes.length} 道菜 · 创建于 ${_formatDate(collection.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SoftPalette.textSecondary,
                    ),
                  ),
                  if ((collection.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      collection.description!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _dishes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 52,
                            color: SoftPalette.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '这个集合还没有菜品',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: SoftPalette.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showAddDishesSheet,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('添加菜品'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: SoftPalette.accentOrange,
                      onRefresh: _loadData,
                      child: ListView.builder(
                        itemCount: _dishes.length,
                        itemBuilder: (BuildContext context, int index) {
                          return _buildDishCard(_dishes[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: FilledButton.icon(
            onPressed: _showAddDishesSheet,
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text('添加菜品'),
          ),
        ),
      ),
    );
  }
}
