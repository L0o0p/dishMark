import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dishmark/data/collection.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/service/wechat_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fluwx/fluwx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showCollectionShareSheet({
  required BuildContext context,
  required DishCollection collection,
  required List<DishMark> dishes,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _CollectionShareSheet(collection: collection, dishes: dishes),
  );
}

class _CollectionShareSheet extends StatefulWidget {
  const _CollectionShareSheet({required this.collection, required this.dishes});

  final DishCollection collection;
  final List<DishMark> dishes;

  @override
  State<_CollectionShareSheet> createState() => _CollectionShareSheetState();
}

class _CollectionShareSheetState extends State<_CollectionShareSheet> {
  static const int _wechatSessionIndex = 0;
  static const int _wechatTimelineIndex = 1;
  static const Duration _systemShareDebounce = Duration(milliseconds: 800);

  static const List<List<Color>> _templateGradients = <List<Color>>[
    <Color>[Color(0xFFFFF8EE), Color(0xFFF7E7D2)],
    <Color>[Color(0xFF2D2F35), Color(0xFF23252B)],
  ];

  final PageController _pageController = PageController();
  late final List<GlobalKey> _cardBoundaryKeys = List<GlobalKey>.generate(
    _templateGradients.length,
    (_) => GlobalKey(),
  );
  late final _CollectionShareData _shareData = _buildShareData();

  int _currentTemplate = 0;
  int? _activeWeChatChannel;
  DateTime? _lastSystemShareAt;

  _CollectionShareData _buildShareData() {
    final List<DishMark> dishes = widget.dishes
        .where((DishMark dish) => dish.deletedAt == null)
        .toList(growable: false);
    final Map<int, _StoreBucket> bucketMap = <int, _StoreBucket>{};
    final List<String> topDishNames = <String>[];
    int missingLocationDishCount = 0;

    for (final DishMark dish in dishes) {
      final String dishName = dish.dishName.trim();
      if (dishName.isNotEmpty && topDishNames.length < 3) {
        topDishNames.add(dishName);
      }

      final Store? store = dish.store.value;
      final double? lat = store?.latitude;
      final double? lng = store?.longitude;
      if (store == null || lat == null || lng == null) {
        missingLocationDishCount++;
        continue;
      }

      final int storeId = store.id;
      final _StoreBucket bucket = bucketMap.putIfAbsent(storeId, () {
        return _StoreBucket(
          id: storeId,
          storeName: store.storeName.trim().isNotEmpty
              ? store.storeName
              : '未知店铺',
          latitude: lat,
          longitude: lng,
        );
      });
      bucket.dishes.add(dish);
    }

    final List<_StorePoint> points =
        bucketMap.values
            .map(
              (bucket) => _StorePoint(
                id: bucket.id,
                storeName: bucket.storeName,
                latitude: bucket.latitude,
                longitude: bucket.longitude,
                dishCount: bucket.dishes.length,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final int dishCompare = b.dishCount.compareTo(a.dishCount);
            if (dishCompare != 0) {
              return dishCompare;
            }
            return a.storeName.compareTo(b.storeName);
          });

    const int maxVisiblePoints = 22;
    final int hiddenPointCount = points.length > maxVisiblePoints
        ? points.length - maxVisiblePoints
        : 0;
    final List<_StorePoint> visiblePoints = points
        .take(maxVisiblePoints)
        .toList(growable: false);

    return _CollectionShareData(
      collectionName: widget.collection.name.trim(),
      description: (widget.collection.description ?? '').trim(),
      dishCount: dishes.length,
      storeCount: points.length,
      missingLocationDishCount: missingLocationDishCount,
      hiddenPointCount: hiddenPointCount,
      points: visiblePoints,
      topDishNames: topDishNames,
    );
  }

  bool _beginWeChatShare(int channel) {
    if (_activeWeChatChannel != null) {
      return false;
    }
    setState(() {
      _activeWeChatChannel = channel;
    });
    return true;
  }

  void _endWeChatShare() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeWeChatChannel = null;
    });
  }

  String _buildShareText() {
    final String description = _shareData.description;
    final String dishes = _shareData.topDishNames.isEmpty
        ? '-'
        : _shareData.topDishNames.join(' / ');
    return '我在 Dishmark 收藏了「${_shareData.collectionName}」\n'
        '菜品：${_shareData.dishCount} 道\n'
        '店铺：${_shareData.storeCount} 家\n'
        '代表菜：$dishes\n'
        '说明：${description.isEmpty ? '-' : description}';
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
          '${directory.path}/dishmark_collection_${widget.collection.id}_${_currentTemplate}_$timestamp.png';
      final File outputFile = File(path);
      await outputFile.writeAsBytes(pngBytes, flush: true);
      return outputFile;
    } catch (error) {
      debugPrint('capture collection share image failed: $error');
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
      final int targetWidth = math.max(120, (sourceWidth * scale).round());
      final int targetHeight = math.max(120, (sourceHeight * scale).round());

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
    final int channel = scene == WeChatScene.session
        ? _wechatSessionIndex
        : _wechatTimelineIndex;
    if (!_beginWeChatShare(channel)) {
      return;
    }

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('拉起微信失败，请稍后重试')));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已拉起微信，请在$targetHint中完成发送')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分享失败，请稍后重试')));
      debugPrint('share collection image failed: $error');
    } finally {
      _endWeChatShare();
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
    final DateTime now = DateTime.now();
    final DateTime? lastShareAt = _lastSystemShareAt;
    if (lastShareAt != null &&
        now.difference(lastShareAt) < _systemShareDebounce) {
      return;
    }
    _lastSystemShareAt = now;

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

      await Share.shareXFiles(<XFile>[
        XFile(
          imageFile.path,
          name:
              'dishmark_collection_${widget.collection.id}_${_currentTemplate + 1}.png',
          mimeType: 'image/png',
        ),
      ], sharePositionOrigin: _getSharePositionOrigin());
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系统分享拉起失败，请稍后重试')));
      debugPrint('system collection share failed: $error');
    }
  }

  Widget _buildTag({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: SoftPalette.tagBackground,
        borderRadius: SoftRadius.tag,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SoftPalette.tagForeground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMapPreview({
    required Color background,
    required double height,
    double borderRadius = 22,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _CollectionMapPainter(points: _shareData.points),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildMapPosterTemplate(List<Color> gradientColors) {
    final String title = _shareData.collectionName.isEmpty
        ? '我的收藏地图'
        : _shareData.collectionName;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: SoftShadow.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 27,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: SoftPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_shareData.dishCount} 道菜 · ${_shareData.storeCount} 家店',
              style: const TextStyle(
                fontSize: 14,
                color: SoftPalette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildMapPreview(
                background: const Color(0xFFF3E2CB),
                height: double.infinity,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _buildTag(text: '可定位 ${_shareData.storeCount} 家'),
                if (_shareData.hiddenPointCount > 0)
                  _buildTag(text: '更多 ${_shareData.hiddenPointCount} 家'),
                if (_shareData.missingLocationDishCount > 0)
                  _buildTag(
                    text: '未定位 ${_shareData.missingLocationDishCount} 道',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteTemplate(List<Color> gradientColors) {
    final String title = _shareData.collectionName.isEmpty
        ? '我的收藏集合'
        : _shareData.collectionName;
    final String subtitle = _shareData.description.isEmpty
        ? '旅行规划，简单的事'
        : _shareData.description;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: SoftShadow.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Dishmark 邀请你查看',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.66),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${_shareData.dishCount} 道菜',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${_shareData.storeCount} 家店',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_shareData.missingLocationDishCount > 0)
                            Text(
                              '未定位 ${_shareData.missingLocationDishCount} 道',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 136,
                      height: double.infinity,
                      child: _buildMapPreview(
                        background: const Color(0xFF20242C),
                        borderRadius: 14,
                        height: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.route_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '圆周旅迹',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  'dishmark',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(int index) {
    if (index == 0) {
      return _buildMapPosterTemplate(_templateGradients[index]);
    }
    return _buildInviteTemplate(_templateGradients[index]);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableHeight =
        mediaQuery.size.height -
        mediaQuery.viewPadding.top -
        mediaQuery.viewPadding.bottom;
    final double sheetHeight = (availableHeight * 0.9)
        .clamp(420.0, 760.0)
        .toDouble();

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
                    '集合分享预览',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: SoftPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '左右滑动，挑一张适合的地图卡片',
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
                              ? SoftPalette.primary
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
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
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
                                  onPressed:
                                      _activeWeChatChannel ==
                                          _wechatSessionIndex
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
                                  onPressed:
                                      _activeWeChatChannel ==
                                          _wechatTimelineIndex
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

class _CollectionShareData {
  const _CollectionShareData({
    required this.collectionName,
    required this.description,
    required this.dishCount,
    required this.storeCount,
    required this.missingLocationDishCount,
    required this.hiddenPointCount,
    required this.points,
    required this.topDishNames,
  });

  final String collectionName;
  final String description;
  final int dishCount;
  final int storeCount;
  final int missingLocationDishCount;
  final int hiddenPointCount;
  final List<_StorePoint> points;
  final List<String> topDishNames;
}

class _StoreBucket {
  _StoreBucket({
    required this.id,
    required this.storeName,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String storeName;
  final double latitude;
  final double longitude;
  final List<DishMark> dishes = <DishMark>[];
}

class _StorePoint {
  const _StorePoint({
    required this.id,
    required this.storeName,
    required this.latitude,
    required this.longitude,
    required this.dishCount,
  });

  final int id;
  final String storeName;
  final double latitude;
  final double longitude;
  final int dishCount;
}

class _CollectionMapPainter extends CustomPainter {
  _CollectionMapPainter({required this.points});

  final List<_StorePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF8EBD9), Color(0xFFEDD8BE)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    _paintRoadPattern(canvas, size);

    if (points.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    final List<Offset> positions = _projectPoints(size);

    final Paint linkPaint = Paint()
      ..color = const Color(0xFFDFB282).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final Path linePath = Path();
    for (int i = 0; i < positions.length; i++) {
      final Offset position = positions[i];
      if (i == 0) {
        linePath.moveTo(position.dx, position.dy);
      } else {
        final Offset previous = positions[i - 1];
        final Offset control = Offset(
          (previous.dx + position.dx) / 2,
          math.min(previous.dy, position.dy) - 8,
        );
        linePath.quadraticBezierTo(
          control.dx,
          control.dy,
          position.dx,
          position.dy,
        );
      }
    }
    canvas.drawPath(linePath, linkPaint);

    for (int i = 0; i < positions.length; i++) {
      _paintMarker(
        canvas,
        center: positions[i],
        dishCount: points[i].dishCount,
      );
    }
  }

  void _paintRoadPattern(Canvas canvas, Size size) {
    final Paint roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Path road = Path()
      ..moveTo(size.width * 0.08, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.18,
        size.width * 0.52,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height * 0.43,
        size.width * 0.9,
        size.height * 0.35,
      )
      ..moveTo(size.width * 0.14, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.62,
        size.width * 0.86,
        size.height * 0.78,
      );
    canvas.drawPath(road, roadPaint);

    final Paint gridPaint = Paint()
      ..color = const Color(0xFF8E7E66).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final double y = size.height * (i / 5);
      canvas.drawLine(
        Offset(size.width * 0.06, y),
        Offset(size.width * 0.94, y),
        gridPaint,
      );
    }
    for (int i = 1; i <= 3; i++) {
      final double x = size.width * (i / 4);
      canvas.drawLine(
        Offset(x, size.height * 0.08),
        Offset(x, size.height * 0.92),
        gridPaint,
      );
    }
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    final TextPainter icon = TextPainter(
      text: const TextSpan(text: '📍', style: TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    )..layout();
    icon.paint(
      canvas,
      Offset(
        (size.width - icon.width) / 2,
        size.height * 0.38 - icon.height / 2,
      ),
    );

    final TextPainter text = TextPainter(
      text: TextSpan(
        text: '暂时还没有可定位的店铺',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6A5E4F).withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);
    text.paint(
      canvas,
      Offset(
        (size.width - text.width) / 2,
        size.height * 0.52 - text.height / 2,
      ),
    );
  }

  List<Offset> _projectPoints(Size size) {
    final List<double> lats = points
        .map((p) => p.latitude)
        .toList(growable: false);
    final List<double> lngs = points
        .map((p) => p.longitude)
        .toList(growable: false);
    final double minLat = lats.reduce(math.min);
    final double maxLat = lats.reduce(math.max);
    final double minLng = lngs.reduce(math.min);
    final double maxLng = lngs.reduce(math.max);

    final double latRange = (maxLat - minLat).abs() < 1e-8
        ? 1e-8
        : maxLat - minLat;
    final double lngRange = (maxLng - minLng).abs() < 1e-8
        ? 1e-8
        : maxLng - minLng;

    const double padding = 26;
    final double usableWidth = math.max(1, size.width - padding * 2);
    final double usableHeight = math.max(1, size.height - padding * 2);

    final List<Offset> result = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final _StorePoint point = points[i];
      final double x =
          padding + (point.longitude - minLng) / lngRange * usableWidth;
      final double y =
          padding + (1 - (point.latitude - minLat) / latRange) * usableHeight;
      result.add(Offset(x, y));
    }

    return result;
  }

  void _paintMarker(
    Canvas canvas, {
    required Offset center,
    required int dishCount,
  }) {
    final Paint shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(center.translate(0, 1.8), 10.2, shadowPaint);

    final Paint outerPaint = Paint()..color = const Color(0xFFF48A3A);
    canvas.drawCircle(center, 9.2, outerPaint);
    canvas.drawCircle(
      center,
      4.2,
      Paint()..color = Colors.white.withValues(alpha: 0.94),
    );

    if (dishCount > 1) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: '$dishCount',
          style: const TextStyle(
            color: Color(0xFF2E3138),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset badgeCenter = center + const Offset(8.5, -8.5);
      canvas.drawCircle(
        badgeCenter,
        6.5,
        Paint()..color = const Color(0xFFFFE5C8),
      );
      painter.paint(
        canvas,
        Offset(
          badgeCenter.dx - painter.width / 2,
          badgeCenter.dy - painter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CollectionMapPainter oldDelegate) {
    if (oldDelegate.points.length != points.length) {
      return true;
    }
    for (int i = 0; i < points.length; i++) {
      final _StorePoint a = oldDelegate.points[i];
      final _StorePoint b = points[i];
      if (a.id != b.id ||
          a.latitude != b.latitude ||
          a.longitude != b.longitude ||
          a.dishCount != b.dishCount) {
        return true;
      }
    }
    return false;
  }
}
