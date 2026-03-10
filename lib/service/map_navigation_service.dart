import 'dart:io';

import 'package:dishmark/data/store.dart';
import 'package:dishmark/theme/soft_spatial_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapNavigationService {
  static const MethodChannel _channel = MethodChannel('dishmark/navigation');

  static Future<void> showNavigationOptions({
    required BuildContext context,
    required Store? store,
    required String placeName,
  }) async {
    final double? latitude = store?.latitude;
    final double? longitude = store?.longitude;
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这个地点还没有经纬度，暂时无法导航')));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: SoftPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            color: SoftPalette.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ListTile(title: Text('选择地图应用')),
                ListTile(
                  leading: const Icon(Icons.navigation_outlined),
                  title: const Text('高德地图'),
                  subtitle: const Text('使用高德地图开始导航'),
                  onTap: () async {
                    await _dismissAndLaunch(
                      sheetContext: sheetContext,
                      context: context,
                      mapType: 'amap',
                      mapName: '高德地图',
                      latitude: latitude,
                      longitude: longitude,
                      placeName: placeName,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route_outlined),
                  title: const Text('腾讯地图'),
                  subtitle: const Text('使用腾讯地图开始导航'),
                  onTap: () async {
                    await _dismissAndLaunch(
                      sheetContext: sheetContext,
                      context: context,
                      mapType: 'tencent',
                      mapName: '腾讯地图',
                      latitude: latitude,
                      longitude: longitude,
                      placeName: placeName,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_rounded),
                  title: const Text('百度地图'),
                  subtitle: const Text('使用百度地图开始导航'),
                  onTap: () async {
                    await _dismissAndLaunch(
                      sheetContext: sheetContext,
                      context: context,
                      mapType: 'baidu',
                      mapName: '百度地图',
                      latitude: latitude,
                      longitude: longitude,
                      placeName: placeName,
                    );
                  },
                ),
                ListTile(
                  enabled: Platform.isIOS,
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('苹果地图'),
                  subtitle: Text(Platform.isIOS ? '使用苹果地图开始导航' : '仅 iOS 支持'),
                  onTap: Platform.isIOS
                      ? () async {
                          await _dismissAndLaunch(
                            sheetContext: sheetContext,
                            context: context,
                            mapType: 'apple',
                            mapName: '苹果地图',
                            latitude: latitude,
                            longitude: longitude,
                            placeName: placeName,
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _dismissAndLaunch({
    required BuildContext sheetContext,
    required BuildContext context,
    required String mapType,
    required String mapName,
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!context.mounted) {
      return;
    }
    await _launchByType(
      context: context,
      mapType: mapType,
      mapName: mapName,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
    );
  }

  static Future<void> _launchByType({
    required BuildContext context,
    required String mapType,
    required String mapName,
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    final bool launched = await _launchNavigation(
      mapType: mapType,
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开$mapName，请确认已安装')));
    }
  }

  static Future<bool> _launchNavigation({
    required String mapType,
    required double latitude,
    required double longitude,
    required String placeName,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      final bool? launched = await _channel
          .invokeMethod<bool>('launchNavigation', <String, dynamic>{
            'mapType': mapType,
            'latitude': latitude,
            'longitude': longitude,
            'placeName': placeName,
          });
      return launched ?? false;
    } catch (_) {
      return false;
    }
  }
}
