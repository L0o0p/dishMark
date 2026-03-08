import 'dart:io';

import 'package:dishmark/data/collection.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/collection_detail.dart';
import 'package:dishmark/service/collection_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:dishmark/widgets/share_collection_card.dart';
import 'package:flutter/material.dart';

class CollectionListPage extends StatefulWidget {
  const CollectionListPage({super.key});

  @override
  State<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends State<CollectionListPage> {
  final CollectionService _collectionService = CollectionService();
  List<DishCollection> _collections = <DishCollection>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final List<DishCollection> data = await _collectionService
        .getAllCollections();
    if (!mounted) {
      return;
    }
    setState(() {
      _collections = data;
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

  Widget _buildCover(String? imagePath) {
    final String path = (imagePath ?? '').trim();
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

  Future<void> _createCollection() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
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
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: '集合名称 *',
                      hintText: '例如：本周想吃、甜品收藏',
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
                    controller: descriptionController,
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
                            nameController.text,
                            descriptionController.text,
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

    nameController.dispose();
    descriptionController.dispose();

    if (created == true) {
      await _loadCollections();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('集合创建成功')));
    }
  }

  Future<bool> _confirmDelete(DishCollection collection) async {
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
    return confirmed == true;
  }

  Future<void> _shareCollection(DishCollection collection) async {
    final List<DishMark> dishes = collection.dishMarks
        .where((DishMark dish) => dish.deletedAt == null)
        .toList(growable: false);
    await Future.wait(dishes.map((DishMark dish) => dish.store.load()));
    if (!mounted) {
      return;
    }
    await showCollectionShareSheet(
      context: context,
      collection: collection,
      dishes: dishes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的集合'),
        actions: [
          IconButton(
            onPressed: _loadCollections,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 56,
                      color: SoftPalette.textSecondary.withValues(alpha: 0.75),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '还没有集合',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '创建一个集合来整理你的菜品记忆',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SoftPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _createCollection,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('创建集合'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: SoftPalette.accentOrange,
                onRefresh: _loadCollections,
                child: ListView.builder(
                  itemCount: _collections.length,
                  itemBuilder: (BuildContext itemContext, int index) {
                    final DishCollection collection = _collections[index];
                    return Dismissible(
                      key: ValueKey<int>(collection.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(collection),
                      onDismissed: (_) async {
                        await _collectionService.deleteCollection(
                          collection.id,
                        );
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _collections.removeWhere(
                            (c) => c.id == collection.id,
                          );
                        });
                        ScaffoldMessenger.of(
                          this.context,
                        ).showSnackBar(const SnackBar(content: Text('集合已删除')));
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: SoftPalette.danger.withValues(alpha: 0.85),
                          borderRadius: SoftRadius.card,
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: SoftDecorations.floatingCard(),
                        child: InkWell(
                          borderRadius: SoftRadius.card,
                          onTap: () async {
                            final bool? changed = await Navigator.push<bool>(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) => CollectionDetailPage(
                                  collectionId: collection.id,
                                ),
                              ),
                            );
                            if (changed == true) {
                              await _loadCollections();
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                                child: SizedBox(
                                  height: 118,
                                  width: double.infinity,
                                  child: _buildCover(collection.coverImagePath),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      collection.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        itemContext,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${collection.dishMarks.length} 道菜 · 创建于 ${_formatDate(collection.createdAt)}',
                                            style: Theme.of(itemContext)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      SoftPalette.textSecondary,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _shareCollection(collection),
                                          icon: const Icon(
                                            Icons.share_outlined,
                                            size: 20,
                                          ),
                                          splashRadius: 20,
                                          color: SoftPalette.textSecondary,
                                          tooltip: '分享集合',
                                        ),
                                      ],
                                    ),
                                    if ((collection.description ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        collection.description!.trim(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(itemContext)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: SoftPalette.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCollection,
        backgroundColor: SoftPalette.accentOrangeSoft,
        foregroundColor: SoftPalette.textPrimary,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('创建集合'),
      ),
    );
  }
}
