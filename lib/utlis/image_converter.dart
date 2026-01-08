import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Converts HEIC to JPEG on MOBILE ONLY.
/// On WEB, conversion is NOT possible → return original bytes.
Uint8List convertToJpegIfNeeded(
  Uint8List originalBytes,
  String fileName,
) {
  final lower = fileName.toLowerCase();

  // ✅ Already safe formats
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp')) {
    return originalBytes;
  }

  // 🌐 WEB: HEIC decoding NOT supported
  if (kIsWeb) {
    debugPrint(
        "⚠️ HEIC conversion skipped on Web (not supported)");
    return originalBytes;
  }

  // 📱 MOBILE ONLY: Convert HEIC → JPG
  try {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception("Unsupported image format");
    }

    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: 85),
    );
  } catch (e) {
    debugPrint("❌ Image conversion failed: $e");
    rethrow;
  }
}
