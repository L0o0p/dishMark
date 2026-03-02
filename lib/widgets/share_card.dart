import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/wechat_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluwx/fluwx.dart';
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
  const _DishShareSheet({required this.dish, required this.store});

  final DishMark dish;
  final Store? store;

  @override
  State<_DishShareSheet> createState() => _DishShareSheetState();
}

class _DishShareSheetState extends State<_DishShareSheet> {
  static const List<List<Color>> _templateGradients = <List<Color>>[
    <Color>[Color(0xFFFFF7EC), Color(0xFFFBE5CF)],
    <Color>[Color(0xFFFFF3E8), Color(0xFFF3E4D5)],
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
    final String tags = widget.dish.flavors
        .take(4)
        .map(_formatFlavor)
        .join(' / ');
    final String note = (widget.dish.experienceNote ?? '').trim();
    return '推荐菜：${widget.dish.dishName}\n'
        '店铺：$storeName\n'
        '口味：${tags.isEmpty ? '-' : tags}\n'
        '价格：${_formatPrice(widget.dish.priceLevel)}\n'
        '简评：${note.isEmpty ? '-' : note}';
  }

  Future<File?> _captureCurrentTemplateAsImage() async {
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      await WidgetsBinding.instance.endOfFrame;
      final RenderObject? renderObject = _cardBoundaryKeys[_currentTemplate]
          .currentContext
          ?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }

      if (renderObject.debugNeedsPaint) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      // A lower ratio keeps shared payload smaller and improves iOS WeChat handoff stability.
      final ui.Image image = await renderObject.toImage(pixelRatio: 1.2);
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

  Future<Uint8List> _shrinkImageBytesForWeChat(Uint8List sourceBytes) async {
    const int maxBytes = 240 * 1024;
    if (sourceBytes.lengthInBytes <= maxBytes) {
      return sourceBytes;
    }

    Uint8List currentBytes = sourceBytes;
    for (int i = 0; i < 5 && currentBytes.lengthInBytes > maxBytes; i++) {
      final ui.Codec probeCodec = await ui.instantiateImageCodec(currentBytes);
      final ui.FrameInfo probeFrame = await probeCodec.getNextFrame();
      final int sourceWidth = probeFrame.image.width;
      final int sourceHeight = probeFrame.image.height;
      probeFrame.image.dispose();
      probeCodec.dispose();

      final double ratio = (maxBytes / currentBytes.lengthInBytes).clamp(
        0.2,
        0.95,
      );
      final double scale = math.sqrt(ratio) * 0.92;
      final int targetWidth = math.max(
        120,
        (sourceWidth * scale).round(),
      );
      final int targetHeight = math.max(
        120,
        (sourceHeight * scale).round(),
      );

      final ui.Codec resizeCodec = await ui.instantiateImageCodec(
        currentBytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final ui.FrameInfo resizeFrame = await resizeCodec.getNextFrame();
      final ByteData? resizeData = await resizeFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      resizeFrame.image.dispose();
      resizeCodec.dispose();
      if (resizeData == null) {
        break;
      }
      currentBytes = resizeData.buffer.asUint8List();
    }

    return currentBytes;
  }

  Future<void> _shareCardImageToWeChat({
    required WeChatScene scene,
    required String targetHint,
  }) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享图片生成失败，请重试')));
        return;
      }

      final bool wechatReady = await WeChatService.ensureInitialized();
      if (!mounted) {
        return;
      }
      if (!wechatReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('微信不可用，请检查 fluwx 配置或微信安装状态')),
        );
        return;
      }

      final Uint8List imageBytes = await imageFile.readAsBytes();
      final Uint8List optimizedBytes = await _shrinkImageBytesForWeChat(
        imageBytes,
      );
      debugPrint(
        'WeChat share image bytes original=${imageBytes.length}, optimized=${optimizedBytes.length}',
      );
      final bool launched = await WeChatService.client.share(
        WeChatShareImageModel(
          WeChatImageToShare(uint8List: optimizedBytes),
          scene: scene,
        ),
      );
      if (!mounted) {
        return;
      }
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('拉起微信失败，请稍后重试')),
        );
        return;
      }
      final String message = '已拉起微信，请在$targetHint中完成发送';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分享失败，请稍后重试')));
      debugPrint('share image failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSharingImage = false;
        });
      }
    }
  }

  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享文案已复制到剪贴板')));
  }

  Rect? _getSharePositionOrigin() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    return null;
  }

  Future<void> _shareViaSystemSheet() async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分享图片生成失败，请重试')));
        return;
      }

      await Share.shareXFiles(
        <XFile>[XFile(imageFile.path)],
        text: _buildShareText(),
        subject: 'DishMark 分享：${widget.dish.dishName}',
        sharePositionOrigin: _getSharePositionOrigin(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系统分享拉起失败，请稍后重试')));
      debugPrint('system share failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSharingImage = false;
        });
      }
    }
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
      child: ClipRRect(borderRadius: borderRadius, child: image),
    );
  }

  Widget _buildFlavorPills({required int maxCount}) {
    final List<Flavor> flavors = widget.dish.flavors;
    if (flavors.isEmpty) {
      return Text(
        '还没有口味标签',
        style: const TextStyle(
          color: SoftPalette.textSecondary,
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
          decoration: const BoxDecoration(
            color: SoftPalette.tagBackground,
            borderRadius: SoftRadius.tag,
          ),
          child: Text(
            _formatFlavor(flavor),
            style: const TextStyle(
              color: SoftPalette.tagForeground,
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
          boxShadow: SoftShadow.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildDishImage()),
              const SizedBox(height: 12),
              Text(
                widget.dish.dishName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: SoftPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '📍 $storeName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: SoftPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildFlavorPills(maxCount: 2),
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
        boxShadow: SoftShadow.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '这顿很值得记住',
              style: const TextStyle(
                color: SoftPalette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: SoftPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SoftPalette.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '人均：${_formatPrice(widget.dish.priceLevel)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: SoftPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '简评：${_formatNote(widget.dish.experienceNote)}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SoftPalette.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFlavorPills(maxCount: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  height: 132,
                  child: _buildDishImage(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
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
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: SoftPalette.surfaceElevated,
        foregroundColor: SoftPalette.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableHeight =
        mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewPadding.bottom;
    final double sheetHeight = (availableHeight * 0.9).clamp(420.0, 760.0).toDouble();

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: SoftPalette.background,
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
                color: SoftPalette.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '分享卡片预览',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '左右滑动，挑一张最符合口味的卡片',
                    style: TextStyle(
                      fontSize: 13,
                      color: SoftPalette.textSecondary,
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
                              ? SoftPalette.accentOrange
                              : SoftPalette.outline,
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
              decoration: SoftDecorations.floatingCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '分享到',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      const double spacing = 8;
                      final double itemWidth =
                          (constraints.maxWidth - spacing) / 2;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: <Widget>[
                          SizedBox(
                            width: itemWidth,
                            child: _buildShareAction(
                              icon: Icons.chat_bubble_outline,
                              label: '微信',
                              onPressed: _isSharingImage
                                  ? null
                                  : () {
                                      _shareCardImageToWeChat(
                                        scene: WeChatScene.session,
                                        targetHint: '微信会话',
                                      );
                                    },
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildShareAction(
                              icon: Icons.groups_outlined,
                              label: '朋友圈',
                              onPressed: _isSharingImage
                                  ? null
                                  : () {
                                      _shareCardImageToWeChat(
                                        scene: WeChatScene.timeline,
                                        targetHint: '朋友圈',
                                      );
                                    },
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildShareAction(
                              icon: Icons.copy_all_outlined,
                              label: 'Copy',
                              onPressed: _copyShareText,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildShareAction(
                              icon: Icons.ios_share_outlined,
                              label: '其他',
                              onPressed: _shareViaSystemSheet,
                            ),
                          ),
                        ],
                      );
                    },
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
