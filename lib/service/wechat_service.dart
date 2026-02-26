import 'package:fluwx/fluwx.dart';
import 'package:flutter/foundation.dart';

class WeChatService {
  WeChatService._();

  static final Fluwx client = Fluwx();

  // Replace these defaults with your real WeChat Open Platform values,
  // or pass them via --dart-define at build time.
  // They also need to match the `fluwx` section in pubspec.yaml.
  static const String _appId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: 'wxad43d21e6da50817',
  );
  static const String _universalLink = String.fromEnvironment(
    'WECHAT_UNIVERSAL_LINK',
    defaultValue: 'https://dishmark.loopshen.top/',
  );

  static bool _initialized = false;
  static bool _isAvailable = false;
  static bool _subscriberAttached = false;

  static void _attachResponseLoggerOnce() {
    if (_subscriberAttached) {
      return;
    }
    _subscriberAttached = true;
    client.addSubscriber((WeChatResponse response) {
      debugPrint(
        'WeChatService response: ${response.runtimeType}, '
        'errCode=${response.errCode}, errStr=${response.errStr}',
      );
    });
  }

  static Future<bool> ensureInitialized() async {
    if (_initialized) {
      return _isAvailable;
    }
    _initialized = true;

    if (_appId.trim().isEmpty) {
      debugPrint('WeChatService: appId is empty, skip fluwx initialization.');
      _isAvailable = false;
      return _isAvailable;
    }
    if (!_appId.startsWith('wx')) {
      debugPrint(
        'WeChatService: appId="$_appId" is not a valid WeChat app id. '
        'Replace it in pubspec.yaml and/or --dart-define WECHAT_APP_ID.',
      );
      _isAvailable = false;
      return _isAvailable;
    }
    if (!_universalLink.startsWith('https://')) {
      debugPrint(
        'WeChatService: universalLink="$_universalLink" is invalid. '
        'It must start with https:// and match WeChat Open Platform settings.',
      );
      _isAvailable = false;
      return _isAvailable;
    }
    debugPrint(
      'WeChatService: initializing with appId=$_appId, universalLink=$_universalLink',
    );

    try {
      final bool registered = await client.registerApi(
        appId: _appId,
        universalLink: _universalLink,
        doOnAndroid: true,
        doOnIOS: true,
      );
      final bool installed = await client.isWeChatInstalled;
      _isAvailable = registered && installed;
      if (_isAvailable) {
        _attachResponseLoggerOnce();
      }
      debugPrint(
        'WeChatService initialized: registered=$registered, installed=$installed',
      );
    } catch (error) {
      _isAvailable = false;
      debugPrint('WeChatService init failed: $error');
    }
    return _isAvailable;
  }
}
