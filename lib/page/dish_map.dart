import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:amap_flutter_map_plus/amap_flutter_map_plus.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_list.dart';
import 'package:dishmark/service/event_bus.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:dishmark/widgets/dialogs.dart';
import 'package:dishmark/widgets/draggable_scrollable_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';

class DishMap extends StatefulWidget {
  const DishMap({super.key});

  @override
  State<DishMap> createState() => _DishMapState();
}

class _DishMapState extends State<DishMap> {
  static const String _dishIconAssetPath = 'assets/logo.png';
  static const int _dishIconSizePx = 72;
  static const bool _showPoiDebugPanel = false;
  static const List<double> _appearScales = <double>[
    0.20,
    0.34,
    0.48,
    0.64,
    0.80,
    0.95,
    1.06,
    1.02,
    1.00,
  ];
  static const List<int> _appearFrameDelaysMs = <int>[
    45,
    45,
    45,
    45,
    45,
    45,
    70,
    70,
    90,
  ];
  static const List<double> _disappearScales = <double>[
    1.00,
    1.05,
    1.10,
    1.06,
    1.00,
    0.95,
    0.88,
    0.80,
    0.70,
    0.64,
    0.54,
    0.48,
    0.40,
    0.34,
    0.28,
    0.20,
    0.14,
    0.10,
  ];
  static const List<int> _disappearFrameDelaysMs = <int>[
    90,
    90,
    90,
    80,
    80,
    75,
    70,
    70,
    65,
    60,
    55,
    50,
    45,
    45,
    45,
    45,
    45,
    120,
  ];

  final Map<int, Marker> _dishMarkerMap = <int, Marker>{};
  final Map<int, String> _dishMarkerImagePathMap = <int, String>{};
  final Set<int> _pendingDeletedDishIds = <int>{};
  AMapController? _mapController;
  Set<Polyline> polylines = {};
  Set<Polygon> polygons = {};
  final Map<Object, BitmapDescriptor> _dishMarkerIconCache =
      <Object, BitmapDescriptor>{};
  final Map<Object, Uint8List> _dishMarkerImageBytesCache =
      <Object, Uint8List>{};
  String? _lastPoiName;
  LatLng? _lastTapLatLng;
  LatLng? _myLatLng;
  Marker? _myLocationMarker;
  bool _hasCenteredOnMyLocation = false;
  bool _hasCenteredOnDishMarkers = false;
  bool _isDishSheetOpen = false;
  late final VoidCallback _onDeletedDishChanged;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initDishMarkerIcon();
    _onDeletedDishChanged = () {
      final id = DishEvents.deletedDishId.value;
      if (id != null) {
        if (_isMapRouteVisible()) {
          unawaited(_removeDishMarker(id));
        } else {
          _pendingDeletedDishIds.add(id);
        }
        DishEvents.deletedDishId.value = null;
      }
    };
    DishEvents.deletedDishId.addListener(_onDeletedDishChanged);
  }

  bool _isMapRouteVisible() {
    return ModalRoute.of(context)?.isCurrent ?? true;
  }

  void _consumePendingDeletedMarkersIfVisible() {
    if (!_isMapRouteVisible() || _pendingDeletedDishIds.isEmpty) {
      return;
    }
    final List<int> pendingIds = List<int>.from(_pendingDeletedDishIds);
    _pendingDeletedDishIds.clear();
    for (final int dishId in pendingIds) {
      unawaited(_removeDishMarker(dishId));
    }
  }

  void _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    debugPrint('locationWhenInUse permission: $status');
  }

  Future<void> _initDishMarkerIcon() async {
    try {
      await _getDishMarkerIconByScale(1.0);
    } catch (e) {
      debugPrint('Failed to build memory marker icon: $e');
    }
    await loadDishMarkers();
  }

  Future<BitmapDescriptor> _getDishMarkerIconByScale(
    double scale, {
    String? imagePath,
  }) async {
    final int targetSizePx = ((_dishIconSizePx * scale).round()).clamp(1, 1024);
    final String sourcePath = imagePath?.trim().isNotEmpty == true
        ? imagePath!.trim()
        : _dishIconAssetPath;
    final String iconCacheKey = '$sourcePath@$targetSizePx';
    final BitmapDescriptor? cachedIcon = _dishMarkerIconCache[iconCacheKey];
    if (cachedIcon != null) {
      return cachedIcon;
    }

    final Uint8List rawBytes = await _loadDishMarkerRawBytes(sourcePath);
    final BitmapDescriptor icon = await _buildMemoryMarkerIcon(
      rawBytes: rawBytes,
      targetSizePx: targetSizePx,
    );
    _dishMarkerIconCache[iconCacheKey] = icon;
    return icon;
  }

  Future<Uint8List> _loadDishMarkerRawBytes(String sourcePath) async {
    final Uint8List? cachedBytes = _dishMarkerImageBytesCache[sourcePath];
    if (cachedBytes != null) {
      return cachedBytes;
    }

    try {
      Uint8List rawBytes;
      if (sourcePath.startsWith('http://') ||
          sourcePath.startsWith('https://')) {
        final ByteData data = await NetworkAssetBundle(
          Uri.parse(sourcePath),
        ).load(sourcePath);
        rawBytes = data.buffer.asUint8List();
      } else if (sourcePath.startsWith('assets/')) {
        final ByteData data = await rootBundle.load(sourcePath);
        rawBytes = data.buffer.asUint8List();
      } else {
        final String filePath = sourcePath.startsWith('file://')
            ? Uri.parse(sourcePath).toFilePath()
            : sourcePath;
        final File file = File(filePath);
        if (!await file.exists()) {
          throw StateError('File does not exist: $filePath');
        }
        rawBytes = await file.readAsBytes();
      }
      _dishMarkerImageBytesCache[sourcePath] = rawBytes;
      return rawBytes;
    } catch (e) {
      if (sourcePath != _dishIconAssetPath) {
        debugPrint(
          'Failed to load marker image "$sourcePath", fallback to logo: $e',
        );
        final Uint8List fallbackBytes = await _loadDishMarkerRawBytes(
          _dishIconAssetPath,
        );
        _dishMarkerImageBytesCache[sourcePath] = fallbackBytes;
        return fallbackBytes;
      }
      rethrow;
    }
  }

  Future<BitmapDescriptor> _buildMemoryMarkerIcon({
    required Uint8List rawBytes,
    required int targetSizePx,
  }) async {
    final int photoSize = (targetSizePx * 0.66).round().clamp(1, 1024);

    final ui.Codec codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: photoSize,
      targetHeight: photoSize,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    final ui.Image photo = frame.image;

    final double size = targetSizePx.toDouble();
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final Paint shadowPaint = Paint()
      ..color = const Color(0x1A000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.08);
    canvas.drawCircle(
      Offset(size * 0.5, size * 0.62),
      size * 0.33,
      shadowPaint,
    );

    final RRect shell = RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.08, size * 0.08, size * 0.84, size * 0.84),
      Radius.circular(size * 0.28),
    );
    canvas.drawRRect(shell, Paint()..color = SoftPalette.surface);
    canvas.drawRRect(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.02
        ..color = SoftPalette.outline.withValues(alpha: 0.72),
    );

    final RRect tape = RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.36, size * 0.03, size * 0.28, size * 0.12),
      Radius.circular(size * 0.06),
    );
    canvas.drawRRect(tape, Paint()..color = const Color(0xFFE9D8C6));

    final Rect photoRect = Rect.fromLTWH(
      size * 0.18,
      size * 0.19,
      size * 0.64,
      size * 0.56,
    );
    final RRect photoClip = RRect.fromRectAndRadius(
      photoRect,
      Radius.circular(size * 0.18),
    );
    canvas.save();
    canvas.clipRRect(photoClip);
    canvas.drawImageRect(
      photo,
      Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
      photoRect,
      Paint(),
    );
    canvas.restore();

    canvas.drawCircle(
      Offset(size * 0.74, size * 0.74),
      size * 0.075,
      Paint()..color = SoftPalette.accentOrange,
    );
    canvas.drawCircle(
      Offset(size * 0.74, size * 0.74),
      size * 0.03,
      Paint()..color = Colors.white.withValues(alpha: 0.84),
    );

    final ui.Image marker = await recorder.endRecording().toImage(
      targetSizePx,
      targetSizePx,
    );

    final ByteData? pngData = await marker.toByteData(
      format: ui.ImageByteFormat.png,
    );
    photo.dispose();
    marker.dispose();
    if (pngData == null) {
      throw StateError('Failed to encode marker icon to PNG bytes.');
    }
    return BitmapDescriptor.fromBytes(pngData.buffer.asUint8List());
  }

  Future<void> loadDishMarkers() async {
    final dishMarks = await IsarService.isar.dishMarks.where().findAll();
    final Map<int, Marker> nextMarkers = <int, Marker>{};
    final Map<int, String> nextMarkerImagePathMap = <int, String>{};
    int skippedWithoutLocation = 0;

    for (final dish in dishMarks) {
      await dish.store.load();
      final store = dish.store.value;
      if (store == null || store.latitude == null || store.longitude == null) {
        skippedWithoutLocation++;
        continue;
      }

      final String imagePath = dish.imagePath.trim();
      final BitmapDescriptor icon = await _getDishMarkerIconByScale(
        1.0,
        imagePath: imagePath,
      );
      final marker = _buildDishMarker(
        dish: dish,
        latitude: store.latitude!,
        longitude: store.longitude!,
        storeName: store.storeName,
        icon: icon,
      );
      nextMarkers[dish.id] = marker;
      nextMarkerImagePathMap[dish.id] = imagePath;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dishMarkerMap
        ..clear()
        ..addAll(nextMarkers);
      _dishMarkerImagePathMap
        ..clear()
        ..addAll(nextMarkerImagePathMap);
    });
    debugPrint(
      'Dish markers loaded: ${_dishMarkerMap.length}, '
      'skipped without location: $skippedWithoutLocation',
    );
    for (final marker in _dishMarkerMap.values.take(5)) {
      debugPrint(
        'Dish marker at: '
        '${marker.position.latitude.toStringAsFixed(5)}, '
        '${marker.position.longitude.toStringAsFixed(5)}',
      );
    }
    _focusOnDishMarkersIfNeeded(Set<Marker>.of(_dishMarkerMap.values));
  }

  Future<void> _playAppearAnimation(DishMark dish) async {
    await dish.store.load();
    final store = dish.store.value;
    if (store == null || store.latitude == null || store.longitude == null) {
      return;
    }
    final String imagePath = dish.imagePath.trim();

    for (int i = 0; i < _appearScales.length; i++) {
      final double scale = _appearScales[i];
      final BitmapDescriptor icon = await _getDishMarkerIconByScale(
        scale,
        imagePath: imagePath,
      );

      final marker = _buildDishMarker(
        dish: dish,
        latitude: store.latitude!,
        longitude: store.longitude!,
        storeName: store.storeName,
        icon: icon,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _dishMarkerMap[dish.id] = marker;
        _dishMarkerImagePathMap[dish.id] = imagePath;
      });

      await Future<void>.delayed(
        Duration(milliseconds: _appearFrameDelaysMs[i]),
      );
    }
  }

  void _onMapCreated(AMapController c) {
    _mapController = c;
    debugPrint('DishMap onMapCreated');
    _focusOnDishMarkersIfNeeded(Set<Marker>.of(_dishMarkerMap.values));
  }

  void _focusOnDishMarkersIfNeeded(Set<Marker> dishMarkers) {
    if (_hasCenteredOnDishMarkers) {
      return;
    }
    if (dishMarkers.isEmpty || _mapController == null) {
      debugPrint(
        'Skip focus dish markers: empty=${dishMarkers.isEmpty}, '
        'controllerNull=${_mapController == null}',
      );
      return;
    }
    _hasCenteredOnDishMarkers = true;
    final target = dishMarkers.first.position;
    debugPrint(
      'Auto focus first dish marker: '
      '${target.latitude.toStringAsFixed(5)}, '
      '${target.longitude.toStringAsFixed(5)}',
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      _mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(target, 16),
        animated: true,
      );
    });
  }

  void _goToMyLocation() {
    final LatLng? latLng = _myLatLng;
    if (latLng == null) {
      debugPrint('No location yet');
      return;
    }
    _mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(latLng, 16),
      animated: true,
    );
  }

  Marker _buildDishMarker({
    required DishMark dish,
    required double latitude,
    required double longitude,
    required String storeName,
    required BitmapDescriptor icon,
  }) {
    return Marker(
      position: LatLng(latitude, longitude),
      icon: icon,
      zIndex: 10,
      infoWindow: InfoWindow(title: storeName, snippet: dish.dishName),
      onTap: (_) {
        unawaited(_showDishDraggableSheet(dish.id));
      },
    );
  }

  Widget _buildMapActionButton({
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

  Widget _buildMapActionItem({
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
        _buildMapActionButton(
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

  Future<void> _focusDishMarkerAndOpenSheet(int dishId) async {
    Marker? marker = _dishMarkerMap[dishId];
    if (marker == null) {
      await loadDishMarkers();
      marker = _dishMarkerMap[dishId];
    }
    if (!mounted || marker == null) {
      debugPrint('Dish marker not found for focus, id=$dishId');
      return;
    }

    _mapController?.moveCamera(
      CameraUpdate.newLatLngZoom(marker.position, 17),
      animated: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await _showDishDraggableSheet(dishId);
  }

  Future<void> _showDishDraggableSheet(int dishId) async {
    if (!mounted || _isDishSheetOpen) {
      return;
    }
    _isDishSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        elevation: 0,
        enableDrag: false,
        showDragHandle: false,
        builder: (_) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: DraggableScrollableSheetExample(dishId: dishId),
        ),
      );
    } finally {
      _isDishSheetOpen = false;
    }
  }

  // 删除mark
  Future<void> _removeDishMarker(int id) async {
    final Marker? marker = _dishMarkerMap[id];
    if (marker == null) {
      debugPrint('Dish marker not found for dish id: $id');
      _dishMarkerImagePathMap.remove(id);
      return;
    }
    final String imagePath = _dishMarkerImagePathMap[id] ?? '';

    for (int i = 0; i < _disappearScales.length; i++) {
      if (!mounted || !_dishMarkerMap.containsKey(id)) {
        return;
      }
      final BitmapDescriptor icon = await _getDishMarkerIconByScale(
        _disappearScales[i],
        imagePath: imagePath,
      );
      if (!mounted || !_dishMarkerMap.containsKey(id)) {
        return;
      }
      setState(() {
        _dishMarkerMap[id] = marker.copyWith(iconParam: icon);
      });
      await Future<void>.delayed(
        Duration(milliseconds: _disappearFrameDelaysMs[i]),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _dishMarkerMap.remove(id);
      _dishMarkerImagePathMap.remove(id);
    });
  }

  @override
  void dispose() {
    DishEvents.deletedDishId.removeListener(_onDeletedDishChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingDeletedDishIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _consumePendingDeletedMarkersIfVisible();
      });
    }

    final Set<Marker> allMarkers = <Marker>{
      ..._dishMarkerMap.values,
      if (_myLocationMarker case final Marker myLocationMarker)
        myLocationMarker,
    };
    final bool hasOnlyMyLocationMarker =
        allMarkers.isEmpty ||
        (allMarkers.length == 1 && _myLocationMarker != null);
    final int memoryCount = _dishMarkerMap.length;
    final String noteCountText = memoryCount > 99 ? '99+' : '$memoryCount';

    return Scaffold(
      body: Stack(
        children: [
          AMapWidget(
            onMapCreated: _onMapCreated,
            onPoiTouched: (poi) => setState(() => _lastPoiName = poi.name),
            onLocationChanged: (AMapLocation location) {
              final LatLng latLng = location.latLng;
              setState(() {
                _myLatLng = latLng;
                _myLocationMarker = (_myLocationMarker == null)
                    ? Marker(
                        position: latLng,
                        zIndex: 0,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        infoWindow: const InfoWindow(title: '当前位置'),
                      )
                    : _myLocationMarker!.copyWith(positionParam: latLng);
              });
              if (!_hasCenteredOnMyLocation) {
                _hasCenteredOnMyLocation = true;
                _mapController?.moveCamera(
                  CameraUpdate.newLatLngZoom(latLng, 16),
                  animated: true,
                );
              }
            },
            onTap: (latLng) {
              if (kDebugMode) {
                setState(() {
                  _lastTapLatLng = latLng;
                });
              }
              if (_isDishSheetOpen) {
                Navigator.of(context).maybePop();
              }
            },
            myLocationStyleOptions: MyLocationStyleOptions(
              true,
              circleFillColor: SoftPalette.accentOrangeSoft.withValues(
                alpha: 0.3,
              ),
              circleStrokeColor: SoftPalette.accentOrange.withValues(
                alpha: 0.6,
              ),
              circleStrokeWidth: 1,
            ),
            touchPoiEnabled: true,
            polylines: polylines,
            polygons: polygons,
            // Required by AMap iOS SDK >= 8.1.0, otherwise native code may assert and crash.
            privacyStatement: const AMapPrivacyStatement(
              hasContains: true,
              hasShow: true,
              hasAgree: true,
            ),
            // Redundant with iOS AppDelegate config, but passing it here guarantees the key
            // is set before the native map view asserts on startup.
            apiKey: const AMapApiKey(
              iosKey: '8dc446dcf3651779abbd5df092b607a7',
            ),
            initialCameraPosition: CameraPosition(
              target: _myLatLng ?? const LatLng(22.3193, 114.1694),
              zoom: _myLatLng == null ? 12 : 16,
            ),
            markers: allMarkers,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: SoftDecorations.floatingCard(
                  color: SoftPalette.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: SoftPalette.accentOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        memoryCount == 0
                            ? '今天想把哪一口味道记下来？'
                            : '已经留下 $memoryCount 条味觉记忆',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SoftPalette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasOnlyMyLocationMarker)
            const Positioned.fill(
              child: IgnorePointer(
                child: AppEmptyHint(message: "你还没有记录任何美食\n快去 mark 你的第一个吧 🍜"),
              ),
            ),
          if (_showPoiDebugPanel)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SoftPalette.textPrimary.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'POI: ${_lastPoiName ?? '（暂无）'}\nTap: ${_lastTapLatLng == null ? '（暂无）' : '${_lastTapLatLng!.latitude.toStringAsFixed(5)}, ${_lastTapLatLng!.longitude.toStringAsFixed(5)}'}\nMe: ${_myLatLng == null ? '（暂无）' : '${_myLatLng!.latitude.toStringAsFixed(5)}, ${_myLatLng!.longitude.toStringAsFixed(5)}'}',
                    style: const TextStyle(color: SoftPalette.surface),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMapActionItem(
            label: '定位',
            icon: Icon(
              Icons.gps_fixed_rounded,
              size: SoftMapActionTokens.sideIconSize,
              color: SoftPalette.textPrimary.withValues(alpha: 0.85),
            ),
            onPressed: () async {
              _goToMyLocation();
            },
          ),
          const SizedBox(width: 20),
          _buildMapActionItem(
            label: '添加',
            emphasized: true,
            icon: SvgPicture.asset(
              'assets/create_button.svg',
              width: SoftMapActionTokens.centerIconSize,
              height: SoftMapActionTokens.centerIconSize,
            ),
            onPressed: () async {
              final LatLng? createLocation = kDebugMode
                  ? (_lastTapLatLng ?? _myLatLng)
                  : _myLatLng;
              final String? createInitialStoreName = kDebugMode
                  ? _lastPoiName
                  : null;
              final DishMark? newDish = await Navigator.push<DishMark>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateDishMark(
                    currentLocation: createLocation,
                    initialStoreName: createInitialStoreName,
                  ),
                ),
              );
              if (newDish != null) {
                await _playAppearAnimation(newDish);
              }
            },
          ),
          const SizedBox(width: 20),
          _buildMapActionItem(
            label: '笔记',
            icon: Text(
              noteCountText,
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SoftPalette.accentOrange,
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SoftPalette.accentOrange,
                  ),
            ),
            onPressed: () async {
              final int? selectedDishId = await Navigator.push<int>(
                context,
                MaterialPageRoute(builder: (_) => DishMarkList()),
              );
              _consumePendingDeletedMarkersIfVisible();
              if (selectedDishId != null) {
                await _focusDishMarkerAndOpenSheet(selectedDishId);
              }
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
