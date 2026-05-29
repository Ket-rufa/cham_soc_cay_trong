class Config {
  static const String backendHost = "wikipedia-stopper-frayed.ngrok-free.dev";
  static const String baseUrl = "https://$backendHost";
  static const String backendBaseUrl = baseUrl;
  static const String apiUrl = "$baseUrl/api";
  static const String imageBaseUrl = baseUrl;
  static const String plantNetApiKey = "2b109VgvlqVVbZXF5QrJDTbj";
  static const String ngrokSkipBrowserWarningHeader =
      "ngrok-skip-browser-warning";

  static const Map<String, String> apiHeaders = {
    'Accept': 'application/json',
    ngrokSkipBrowserWarningHeader: 'true',
  };

  static const Map<String, String> jsonHeaders = {
    ...apiHeaders,
    'Content-Type': 'application/json',
  };

  static const Map<String, String> imageHeaders = {
    'User-Agent': 'ChamSocCayTrong/1.0 (Flutter Android; image loader)',
    ngrokSkipBrowserWarningHeader: 'true',
    'Accept':
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  static const Map<String, String> wikimediaImageHeaders = {
    'User-Agent': 'ChamSocCayTrong/1.0 (Flutter Android; educational app)',
    'Referer': 'https://commons.wikimedia.org/',
    ngrokSkipBrowserWarningHeader: 'true',
    'Accept':
        'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  };

  static const List<String> _imageKeys = [
    'image_url',
    'image',
    'imageUrl',
    'image_path',
    'imagePath',
    'thumbnail',
    'thumbnail_url',
    'photo',
    'photo_url',
    'main_image_url',
    'avatar_url',
  ];

  static String getImageUrl(Object? value) {
    final raw = _stringValue(value);
    if (raw.isEmpty) return "";

    final normalized = raw.replaceAll('\\', '/');
    if (_isAssetPath(normalized)) return normalized;

    if (normalized.startsWith('//')) {
      return _normalizeAbsoluteUrl('https:$normalized');
    }

    if (_hasHttpScheme(normalized)) {
      return _normalizeAbsoluteUrl(normalized);
    }

    return _joinBackendUrl(_normalizeRelativePath(normalized));
  }

  static String getPlantImageSource(Map<dynamic, dynamic>? plant) {
    if (plant == null) return "";

    for (final key in _imageKeys) {
      final value = _stringValue(plant[key]);
      if (value.isNotEmpty) return value;
    }

    return "";
  }

  static String getPlantImageUrl(Map<dynamic, dynamic>? plant) {
    return getImageUrl(getPlantImageSource(plant));
  }

  static bool isValidImageUrl(Object? value) {
    final resolved = getImageUrl(value);
    return resolved.isNotEmpty &&
        (_isAssetPath(resolved) || _hasHttpScheme(resolved));
  }

  static bool isBackendUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return _isLegacyLocalBackendHost(uri.host) || uri.host == backendHost;
  }

  static bool canUseProxyFallback(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !_hasHttpScheme(url)) return false;
    return !isBackendUrl(url);
  }

  static String getImageProxyUrl(String url) {
    final resolved = getImageUrl(url);
    if (resolved.isEmpty) return "";
    return "$apiUrl/image-proxy?url=${Uri.encodeComponent(resolved)}";
  }

  static Map<String, String> getImageHeaders(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? "";
    if (host.endsWith('wikimedia.org') || host.endsWith('wikipedia.org')) {
      return wikimediaImageHeaders;
    }
    return imageHeaders;
  }

  static String _normalizeAbsoluteUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    if (!_isLegacyLocalBackendHost(uri.host)) return url;

    final replacement = Uri.parse(baseUrl).resolveUri(
      Uri(
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
        fragment: uri.hasFragment ? uri.fragment : null,
      ),
    );
    return replacement.toString();
  }

  static String _normalizeRelativePath(String path) {
    var value = path.trim();
    if (value.isEmpty) return "";

    final publicIndex = value.toLowerCase().lastIndexOf('/public/');
    if (publicIndex >= 0) {
      value = value.substring(publicIndex + '/public/'.length);
    }

    value = value.replaceFirst(RegExp(r'^public/+', caseSensitive: false), '');
    value = value.replaceFirst(
      RegExp(r'^storage/app/public/+', caseSensitive: false),
      'storage/',
    );
    value = value.replaceFirst(
      RegExp(r'^public/storage/+', caseSensitive: false),
      'storage/',
    );

    while (value.startsWith('/')) {
      value = value.substring(1);
    }

    return value;
  }

  static String _joinBackendUrl(String relativePath) {
    if (relativePath.isEmpty) return "";
    final encodedPath = Uri.encodeFull(relativePath);
    return "$backendBaseUrl/$encodedPath";
  }

  static bool _hasHttpScheme(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static bool _isAssetPath(String value) {
    return value.startsWith('assets/');
  }

  static bool _isLegacyLocalBackendHost(String host) {
    final lower = host.toLowerCase();
    return lower == 'localhost' ||
        lower == '127.0.0.1' ||
        lower == '0.0.0.0' ||
        lower == '10.0.2.2' ||
        lower == '::1' ||
        RegExp(r'^192\.168\.').hasMatch(lower);
  }

  static String _stringValue(Object? value) {
    if (value == null) return "";
    final text = value.toString().trim();
    if (text.isEmpty) return "";

    final lower = text.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || lower == 'none') {
      return "";
    }

    return text;
  }
}
