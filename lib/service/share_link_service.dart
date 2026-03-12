import 'package:dishmark/data/dish_mark.dart';

class ShareLinkService {
  ShareLinkService._();

  static const String _fallbackBaseUrl = 'https://dishmark.app';
  static const String _shareBaseUrl = String.fromEnvironment(
    'SHARE_BASE_URL',
    defaultValue: _fallbackBaseUrl,
  );

  static Uri _resolveBaseUri() {
    final String trimmed = _shareBaseUrl.trim();
    final Uri candidate = Uri.tryParse(trimmed) ?? Uri.parse(_fallbackBaseUrl);
    final bool validScheme =
        candidate.scheme == 'https' || candidate.scheme == 'http';
    if (candidate.host.isEmpty || !validScheme) {
      return Uri.parse(_fallbackBaseUrl);
    }
    return candidate;
  }

  static String buildMomentShareUrlById(int momentId, {int? cacheVersion}) {
    final Uri base = _resolveBaseUri();
    final Map<String, String>? queryParameters = cacheVersion == null
        ? null
        : <String, String>{'v': '$cacheVersion'};
    return base
        .replace(path: '/m/$momentId', queryParameters: queryParameters)
        .toString();
  }

  static String resolveMomentShareUrl(DishMark dish, {int? cacheVersion}) {
    final String existing = (dish.shareUrl ?? '').trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    return buildMomentShareUrlById(dish.id, cacheVersion: cacheVersion);
  }
}
