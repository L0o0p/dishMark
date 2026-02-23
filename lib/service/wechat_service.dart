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
    defaultValue: '123456',
  );
  static const String _universalLink = String.fromEnvironment(
    'WECHAT_UNIVERSAL_LINK',
    defaultValue: 'https://testdomain.com',
  );

  static bool _initialized = false;
  static bool _isAvailable = false;

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

    try {
      final bool registered = await client.registerApi(
        appId: _appId,
        universalLink: _universalLink,
        doOnAndroid: true,
        doOnIOS: true,
      );
      final bool installed = await client.isWeChatInstalled;
      _isAvailable = registered && installed;
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
