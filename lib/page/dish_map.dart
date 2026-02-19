import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:amap_flutter_map_plus/amap_flutter_map_plus.dart';
import 'package:dishmark/data/dish_mark.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_list.dart';
import 'package:dishmark/service/event_bus.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:dishmark/widgets/dialogs.dart';
import 'package:dishmark/widgets/draggable_scrollable_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';

class DishMap extends StatefulWidget {
  const DishMap({super.key});

  @override
  State<DishMap> createState() => _DishMapState();
}

class _DishMapState extends State<DishMap> {
  static const String _dishIconAssetPath = 'assets/logo.jpg';
  static const int _dishIconSizePx = 72;
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
  final Set<int> _pendingDeletedDishIds = <int>{};
  AMapController? _mapController;
  Set<Polyline> polylines = {};
  Set<Polygon> polygons = {};
  BitmapDescriptor _dishMarkerIcon = BitmapDescriptor.defaultMarker;
  final Map<int, BitmapDescriptor> _dishMarkerIconCache =
      <int, BitmapDescriptor>{};
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
      _dishMarkerIcon = await _getDishMarkerIconByScale(1.0);
    } catch (e) {
      debugPrint('Failed to build resized marker icon: $e');
      _dishMarkerIcon = BitmapDescriptor.defaultMarker;
    }
    await loadDishMarkers();
  }

  Future<BitmapDescriptor> _getDishMarkerIconByScale(double scale) async {
    final int targetSizePx =
        ((_dishIconSizePx * scale).round()).clamp(1, 1024) as int;
    final BitmapDescriptor? cachedIcon = _dishMarkerIconCache[targetSizePx];
    if (cachedIcon != null) {
      return cachedIcon;
    }

    final BitmapDescriptor icon = await _buildResizedMarkerIcon(
      assetPath: _dishIconAssetPath,
      targetSizePx: targetSizePx,
    );
    _dishMarkerIconCache[targetSizePx] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _buildResizedMarkerIcon({
    required String assetPath,
    required int targetSizePx,
  }) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List rawBytes = byteData.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: targetSizePx,
      targetHeight: targetSizePx,
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();

    final ByteData? pngData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    if (pngData == null) {
      throw StateError('Failed to encode marker icon to PNG bytes.');
    }
    return BitmapDescriptor.fromBytes(pngData.buffer.asUint8List());
  }

  Future<void> loadDishMarkers() async {
    final dishMarks = await IsarService.isar.dishMarks.where().findAll();
    final Map<int, Marker> nextMarkers = <int, Marker>{};
    int skippedWithoutLocation = 0;

    for (final dish in dishMarks) {
      await dish.store.load();
      final store = dish.store.value;
      if (store == null || store.latitude == null || store.longitude == null) {
        skippedWithoutLocation++;
        continue;
      }

      final marker = _buildDishMarker(
        dish: dish,
        latitude: store.latitude!,
        longitude: store.longitude!,
        storeName: store.storeName,
        icon: _dishMarkerIcon,
      );
      nextMarkers[dish.id] = marker;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dishMarkerMap
        ..clear()
        ..addAll(nextMarkers);
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

    for (int i = 0; i < _appearScales.length; i++) {
      final double scale = _appearScales[i];
      final BitmapDescriptor icon = await _getDishMarkerIconByScale(scale);

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
      return;
    }

    for (int i = 0; i < _disappearScales.length; i++) {
      if (!mounted || !_dishMarkerMap.containsKey(id)) {
        return;
      }
      final BitmapDescriptor icon = await _getDishMarkerIconByScale(
        _disappearScales[i],
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
      if (_myLocationMarker != null) _myLocationMarker!,
    };
    final bool hasOnlyMyLocationMarker =
        allMarkers.isEmpty ||
        (allMarkers.length == 1 && _myLocationMarker != null);

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
                          BitmapDescriptor.hueAzure,
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
              setState(() {
                _lastTapLatLng = latLng;
              });
              if (_isDishSheetOpen) {
                Navigator.of(context).maybePop();
              }
            },
            myLocationStyleOptions: MyLocationStyleOptions(
              true,
              circleFillColor: Colors.lightBlue,
              circleStrokeColor: Colors.blue,
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
          if (hasOnlyMyLocationMarker)
            const Positioned.fill(
              child: IgnorePointer(
                child: AppEmptyHint(message: "你还没有记录任何美食\n快去 mark 你的第一个吧 🍜"),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'POI: ${_lastPoiName ?? '（暂无）'}\nTap: ${_lastTapLatLng == null ? '（暂无）' : '${_lastTapLatLng!.latitude.toStringAsFixed(5)}, ${_lastTapLatLng!.longitude.toStringAsFixed(5)}'}\nMe: ${_myLatLng == null ? '（暂无）' : '${_myLatLng!.latitude.toStringAsFixed(5)}, ${_myLatLng!.longitude.toStringAsFixed(5)}'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'go_my_location_fab',
            onPressed: _goToMyLocation,
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'add_mark_fab',
            onPressed: () async {
              final DishMark? newDish = await Navigator.push<DishMark>(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateDishMark(
                    currentLocation: _lastTapLatLng ?? _myLatLng,
                    initialStoreName: _lastPoiName,
                  ),
                ),
              );
              if (newDish != null) {
                await _playAppearAnimation(newDish);
              }
            },
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'view_mark_list',
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
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            child: const Icon(Icons.list),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
