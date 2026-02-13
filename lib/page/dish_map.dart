import 'package:amap_flutter_base_plus/amap_flutter_base_plus.dart';
import 'package:amap_flutter_map_plus/amap_flutter_map_plus.dart';
import 'package:dishmark/data/store.dart';
import 'package:dishmark/page/create_dish_mark.dart';
import 'package:dishmark/page/dish_list.dart';
import 'package:dishmark/service/isar_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class DishMap extends StatefulWidget {
  const DishMap({super.key});

  @override
  State<DishMap> createState() => _DishMapState();
}

class _DishMapState extends State<DishMap> {
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    loadStores();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AMapWidget(
        // Required by AMap iOS SDK >= 8.1.0, otherwise native code may assert and crash.
        privacyStatement: const AMapPrivacyStatement(
          hasContains: true,
          hasShow: true,
          hasAgree: true,
        ),
        // Redundant with iOS AppDelegate config, but passing it here guarantees the key
        // is set before the native map view asserts on startup.
        apiKey: const AMapApiKey(iosKey: '8dc446dcf3651779abbd5df092b607a7'),
        initialCameraPosition: const CameraPosition(
          target: LatLng(22.3193, 114.1694),
          zoom: 12,
        ),
        markers: markers,
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
