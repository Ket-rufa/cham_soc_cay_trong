class Config {
  // static const String serverIp = "localhost";
  static const String serverIp = "192.168.1.10";
  // static const String serverIp = "192.168.1.4";
  static const String serverPort = "8000";
  static const String apiUrl = "http://$serverIp:8000/api";
  static const String imageBaseUrl = "http://$serverIp:$serverPort";
  static const String plantNetApiKey = "2b109VgvlqVVbZXF5QrJDTbj";

  static const Map<String, String> imageHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  };

  static String getImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return "";
    final trimmed = url.trim();

    // 1) URL tương đối: bắt đầu bằng '/' (vd: /storage/images/hoa.jpg)
    if (trimmed.startsWith('/')) {
      return 'http://$serverIp:$serverPort$trimmed';
    }

    // 2) localhost hoặc 127.0.0.1 -> thay bằng IP máy chủ thật
    if (trimmed.startsWith('http://localhost') ||
        trimmed.startsWith('http://127.0.0.1')) {
      return trimmed.replaceFirst(
        RegExp(r'http:\/\/(localhost|127\.0\.0\.1)(:\d+)?'),
        'http://$serverIp:$serverPort',
      );
    }

    // 3) Path không có scheme, không bắt đầu bằng '/' (vd: storage/images/hoa.jpg)
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'http://$serverIp:$serverPort/$trimmed';
    }

    // 4) URL đầy đủ hợp lệ -> trả về nguyên
    return trimmed;
  }

  /// Kiểm tra URL có hợp lệ để load ảnh không
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final resolved = getImageUrl(url);
    return resolved.startsWith('http://') || resolved.startsWith('https://');
  }
}
