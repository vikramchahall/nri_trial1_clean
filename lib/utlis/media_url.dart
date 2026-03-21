class MediaUrl {
  static const String _base =
      'https://connectnri-media.sevapani08.workers.dev/storage/v1/object/public';

  static String postImage(String path) {
    final clean = path.split('?')[0];
    // Handle full URLs passed in
    if (clean.contains('supabase.co') || clean.contains('workers.dev')) {
      final uri = Uri.parse(clean);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('post_images');
      if (bucketIndex != -1) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        return '$_base/post_images/$filePath';
      }
    }
    return '$_base/post_images/$clean';
  }

  static String profileImage(String path) {
    final clean = path.split('?')[0]; // fixes your double ?v= bug
    if (clean.contains('supabase.co') || clean.contains('workers.dev')) {
      final uri = Uri.parse(clean);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('profile_images');
      if (bucketIndex != -1) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        return '$_base/profile_images/$filePath';
      }
    }
    return '$_base/profile_images/$clean';
  }

  static String officialMedia(String path) {
    final clean = path.split('?')[0];
    if (clean.contains('supabase.co') || clean.contains('workers.dev')) {
      final uri = Uri.parse(clean);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('official_media');
      if (bucketIndex != -1) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        return '$_base/official_media/$filePath';
      }
    }
    return '$_base/official_media/$clean';
  }

  // Converts ANY existing Supabase URL to Cloudflare URL
  // Use this as a safety net anywhere you're not sure
  static String convert(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    final clean = originalUrl.split('?')[0];
    if (!clean.contains('supabase.co')) return clean;
    final uri = Uri.parse(clean);
    final path = uri.path; // e.g. /storage/v1/object/public/post_images/...
    return 'https://connectnri-media.sevapani08.workers.dev$path';
  }
}