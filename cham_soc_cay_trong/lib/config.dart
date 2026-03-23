class Config {
  // static const String serverIp = "localhost";
  // static const String serverIp = "172.31.98.126";
  static const String serverIp = "172.31.98.126";
  static const String serverPort = "8000";
  static const String apiUrl = "http://$serverIp:8000/api";
  static const String imageBaseUrl = "http://$serverIp:$serverPort";
  static const String plantNetApiKey = "2b109VgvlqVVbZXF5QrJDTbj";

  static String getImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http://localhost") || url.startsWith("http://127.0.0.1")) {
      return url.replaceFirst(RegExp(r'http:\/\/(localhost|127\.0\.0\.1)(:\d+)?'), 'http://$serverIp:$serverPort');
    }
    return url;
  }
}
