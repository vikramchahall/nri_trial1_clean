import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

import '../domain/storage_repo.dart';

class SupabaseStorageRepo implements StorageRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 🧠 IMAGE COMPRESSION
  // ===============================
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final img.Image resized = img.copyResize(
        image,
        width: image.width > 1080 ? 1080 : image.width,
      );

      return Uint8List.fromList(
        img.encodeJpg(resized, quality: 70),
      );
    } catch (e) {
      debugPrint("❌ Image compression failed: $e");
      return bytes;
    }
  }

  // ===============================
  // 🔁 SHARED UPLOAD HELPER (SMART VERSION)
  // ===============================
  Future<String?> _upload(
    Uint8List originalBytes,
    String bucket,
    String fileName,
  ) async {
    try {
      final lower = fileName.toLowerCase();

      // 1️⃣ SMART CONTENT TYPE DETECTION
      String contentType = 'image/jpeg'; // default
      bool isVideo = false;

      if (lower.endsWith(".mp4")) {
        contentType = 'video/mp4';
        isVideo = true;
      } else if (lower.endsWith(".mov")) {
        contentType = 'video/quicktime';
        isVideo = true;
      } else if (lower.endsWith(".png")) {
        contentType = 'image/png';
      } else if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) {
        contentType = 'image/jpeg';
      }

      // 2️⃣ BYTES (DO NOT COMPRESS VIDEOS)
      final Uint8List bytes =
          isVideo ? originalBytes : await _compressImage(originalBytes);

      // 3️⃣ UPLOAD TO SUPABASE WITH MIME
      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      // 4️⃣ GET PUBLIC URL
      final String publicUrl =
          _supabase.storage.from(bucket).getPublicUrl(fileName);

      // Cache busting to avoid browser issues
      return "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("❌ Supabase Upload Error: $e");
      return null;
    }
  }

  // ===============================
  // 📱 MOBILE
  // ===============================
  @override
  Future<String?> uploadPostImageMobile(
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(bytes, 'post_images', fileName);

  @override
  Future<String?> uploadProfileImageMobile(
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(bytes, 'profile_images', fileName);

  // ===============================
  // 🌐 WEB
  // ===============================
  @override
  Future<String?> uploadPostImageWeb(
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(bytes, 'post_images', fileName);

  @override
  Future<String?> uploadProfileImageWeb(
    Uint8List bytes,
    String fileName,
  ) =>
      _upload(bytes, 'profile_images', fileName);
}
