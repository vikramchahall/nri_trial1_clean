class UrlHelper {
  // This adds a unique number to every URL so the app thinks it's a "New" image
  static String getRefreshUrl(String url) {
    if (url.isEmpty) return url;
    return "$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}";
  }
}