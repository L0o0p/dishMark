import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showDishShareSheet({
  required BuildContext context,
  required DishMark dish,
  Store? store,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DishShareSheet(dish: dish, store: store),
  );
}

class _DishShareSheet extends StatefulWidget {
  const _DishShareSheet({
    required this.dish,
    required this.store,
  });

  final DishMark dish;
  final Store? store;

  @override
  State<_DishShareSheet> createState() => _DishShareSheetState();
}

class _DishShareSheetState extends State<_DishShareSheet> {
  static const List<List<Color>> _templateGradients = <List<Color>>[
    <Color>[Color(0xFFFFF2DF), Color(0xFFFFD2A5)],
    <Color>[Color(0xFFEEF6FF), Color(0xFFCFE6FF)],
  ];

  final PageController _pageController = PageController();
  late final List<GlobalKey> _cardBoundaryKeys = List<GlobalKey>.generate(
    _templateGradients.length,
    (_) => GlobalKey(),
  );
  int _currentTemplate = 0;
  bool _isSharingImage = false;

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

  String _formatPrice(double? price) {
    if (price == null) {
      return '-';
    }
    if (price == price.roundToDouble()) {
      return '￥${price.toStringAsFixed(0)}';
    }
    return '￥${price.toStringAsFixed(2)}';
  }

  String _formatNote(String? note) {
    final String trimmed = (note ?? '').trim();
    if (trimmed.isEmpty) {
      return '-';
    }
    return trimmed;
  }

  String _buildShareText() {
    final String storeName = widget.store?.storeName.trim().isNotEmpty == true
        ? widget.store!.storeName
        : '未知店铺';
    final String tags = widget.dish.flavors.take(4).map(_formatFlavor).join(' / ');
    final String note = (widget.dish.experienceNote ?? '').trim();
    return '推荐菜：${widget.dish.dishName}\n'
        '店铺：$storeName\n'
        '口味：${tags.isEmpty ? '-' : tags}\n'
        '价格：${_formatPrice(widget.dish.priceLevel)}\n'
        '简评：${note.isEmpty ? '-' : note}';
  }

  Future<File?> _captureCurrentTemplateAsImage() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final GlobalKey boundaryKey = _cardBoundaryKeys[_currentTemplate];
      final BuildContext? boundaryContext = boundaryKey.currentContext;
      if (boundaryContext == null) {
        return null;
      }
      final RenderObject? renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      if (renderObject.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (byteData == null) {
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final Directory directory = await getTemporaryDirectory();
      final int timestamp = DateTime.now().microsecondsSinceEpoch;
      final String path =
          '${directory.path}/dishmark_${widget.dish.id}_${_currentTemplate}_$timestamp.png';
      final File outputFile = File(path);
      await outputFile.writeAsBytes(pngBytes, flush: true);
      return outputFile;
    } catch (error) {
      debugPrint('capture share image failed: $error');
      return null;
    }
  }

  Future<void> _shareCardImage({String? targetHint}) async {
    if (_isSharingImage) {
      return;
    }
    setState(() {
      _isSharingImage = true;
    });

    try {
      final File? imageFile = await _captureCurrentTemplateAsImage();
      if (!mounted) {
        return;
      }
      if (imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享图片生成失败，请重试')),
        );
        return;
      }

      await Share.shareXFiles(
        <XFile>[
          XFile(
            imageFile.path,
            name: 'dishmark_${widget.dish.id}_${_currentTemplate + 1}.png',
            mimeType: 'image/png',
          ),
        ],
        subject: '推荐菜：${widget.dish.dishName}',
      );
      if (!mounted) {
        return;
      }
      final String message = targetHint == null
          ? '已打开系统分享面板（图片）'
          : '已打开系统分享面板，请选择$targetHint（图片）';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分享失败，请稍后重试')),
      );
      debugPrint('share image failed: $error');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSharingImage = false;
      });
    }
  }

  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享文案已复制到剪贴板')),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDishImage({
    double? height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    final String imagePath = widget.dish.imagePath.trim();
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
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: image,
      ),
    );
  }

  Widget _buildFlavorPills({
    required Color background,
    required Color foreground,
    required int maxCount,
  }) {
    final List<Flavor> flavors = widget.dish.flavors;
    if (flavors.isEmpty) {
      return Text(
        '还没有口味标签',
        style: TextStyle(
          color: foreground.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flavors.take(maxCount).map((Flavor flavor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _formatFlavor(flavor),
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplateCard(int index) {
    final String storeName = widget.store?.storeName.trim().isNotEmpty == true
        ? widget.store!.storeName
        : '未知店铺';
    final List<Color> colors = _templateGradients[index];

    if (index == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildDishImage(height: 210),
              const SizedBox(height: 14),
              Text(
                widget.dish.dishName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '📍 $storeName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5C4B36),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildFlavorPills(
                background: const Color(0xFF4B00C9),
                foreground: Colors.white,
                maxCount: 3,
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'DishMark 推荐',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.dish.dishName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.65),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '人均：${_formatPrice(widget.dish.priceLevel)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '简评：${_formatNote(widget.dish.experienceNote)}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _buildDishImage(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildFlavorPills(
              background: const Color(0xFF1C2733),
              foreground: Colors.white,
              maxCount: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: const Color(0xFFF2F4F8),
          foregroundColor: const Color(0xFF253142),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double sheetHeight = (screenHeight * 0.82).clamp(520.0, 760.0).toDouble();
    final double topAreaHeight = (screenHeight * 0.46).clamp(290.0, 430.0).toDouble();

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: <Widget>[
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCCD2DA),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: topAreaHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '分享卡片预览',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '左右滑动切换模板',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _templateGradients.length,
                      onPageChanged: (int value) {
                        setState(() {
                          _currentTemplate = value;
                        });
                      },
                      itemBuilder: (_, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: RepaintBoundary(
                            key: _cardBoundaryKeys[index],
                            child: _buildTemplateCard(index),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(_templateGradients.length, (
                      int index,
                    ) {
                      final bool selected = index == _currentTemplate;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1E2B3D)
                              : const Color(0xFFBBC4CF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '系统分享渠道',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _buildShareAction(
                        icon: Icons.chat_bubble_outline,
                        label: '微信',
                        onPressed: _isSharingImage
                            ? null
                            : () {
                                _shareCardImage(targetHint: '微信');
                              },
                      ),
                      const SizedBox(width: 8),
                      _buildShareAction(
                        icon: Icons.groups_outlined,
                        label: '朋友圈',
                        onPressed: _isSharingImage
                            ? null
                            : () {
                                _shareCardImage(targetHint: '朋友圈');
                              },
                      ),
                      const SizedBox(width: 8),
                      _buildShareAction(
                        icon: Icons.copy_all_outlined,
                        label: 'Copy',
                        onPressed: _copyShareText,
                      ),
                    ],
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
