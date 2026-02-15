import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:amap_flutter_map_plus/amap_flutter_map_plus.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_list.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';

class DishMap extends StatefulWidget {
  const DishMap({super.key});

  @override
  State<DishMap> createState() => _DishMapState();
}

class _DishMapState extends State<DishMap> {
  Set<Marker> markers = {};
  AMapController? _mapController;
  Set<Polyline> polylines = {};
  Set<Polygon> polygons = {};
  String? _lastPoiName;
  String? _lastTap;
  LatLng? _myLatLng;
  Marker? _myLocationMarker;
  bool _hasCenteredOnMyLocation = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    loadStores();
  }

  void _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    debugPrint('locationWhenInUse permission: $status');
  }

  Future<void> loadStores() async {
    final stores = await IsarService.isar.stores.where().findAll();

    if (!mounted) {
      return;
    }

    setState(() {
      markers = stores
          .where((s) => s.latitude != null && s.longitude != null)
          .map(
            (store) => Marker(
              position: LatLng(store.latitude!, store.longitude!),
              infoWindow: InfoWindow(title: store.storeName),
            ),
          )
          .toSet();
    });
  }

  void _onMapCreated(AMapController c) => _mapController = c;

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

  @override
  Widget build(BuildContext context) {
    final Set<Marker> allMarkers = <Marker>{
      ...markers,
      if (_myLocationMarker != null) _myLocationMarker!,
    };

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
                _lastTap =
                    '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
              });
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
                  'POI: ${_lastPoiName ?? '（暂无）'}\nTap: ${_lastTap ?? '（暂无）'}\nMe: ${_myLatLng == null ? '（暂无）' : '${_myLatLng!.latitude.toStringAsFixed(5)}, ${_myLatLng!.longitude.toStringAsFixed(5)}'}',
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
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateDishMark()),
              );
              loadStores();
            },
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'view_mark_list',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DishMarkList()),
              );
              loadStores();
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
