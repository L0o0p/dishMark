import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  String? _lastHandledUri;

  Future<void> start({
    required void Function(Uri uri) onUri,
  }) async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _dispatch(initialUri, onUri);
      }
    } catch (error) {
      debugPrint('DeepLinkService initial link failed: $error');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (Uri uri) => _dispatch(uri, onUri),
      onError: (Object error) {
        debugPrint('DeepLinkService stream failed: $error');
      },
    );
  }

  void _dispatch(Uri uri, void Function(Uri uri) onUri) {
    final String key = uri.toString();
    if (_lastHandledUri == key) {
      return;
    }
    _lastHandledUri = key;
    onUri(uri);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static int? parseDishMarkId(Uri uri) {
    final String? fromQuery = _queryId(uri);
    if (fromQuery != null) {
      return int.tryParse(fromQuery);
    }

    final String? fromPath = _pathId(uri);
    if (fromPath != null) {
      return int.tryParse(fromPath);
    }
    return null;
  }

  static String? _queryId(Uri uri) {
    final String? id = uri.queryParameters['id']?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  static String? _pathId(Uri uri) {
    if (uri.scheme == 'dishmark') {
      if (uri.host == 'moment' && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.first.trim();
      }
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'moment') {
        return uri.pathSegments[1].trim();
      }
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last.trim();
      }
      return null;
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'm') {
        return uri.pathSegments[1].trim();
      }
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'moment') {
        return uri.pathSegments[1].trim();
      }
    }

    return null;
  }
}
