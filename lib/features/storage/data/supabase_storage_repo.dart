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

      // Resize to max width 1080px
      final img.Image resized = img.copyResize(
        image,
        width: image.width > 1080 ? 1080 : image.width,
      );

      // Compress to JPG 70%
      return Uint8List.fromList(
        img.encodeJpg(resized, quality: 70),
      );
    } catch (e) {
      debugPrint("❌ Image compression failed: $e");
      return bytes;
    }
  }

  // ===============================
  // 🔁 SHARED UPLOAD HELPER (WEB + MOBILE)
  // ===============================
  Future<String?> _upload(
    Uint8List originalBytes,
    String bucket,
    String fileName,
  ) async {
    try {
      // 🔻 COMPRESS BEFORE UPLOAD
      final Uint8List bytes = await _compressImage(originalBytes);

      final String contentType = _getContentType(fileName);

      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      final String publicUrl =
          _supabase.storage.from(bucket).getPublicUrl(fileName);

      if (publicUrl.isEmpty || !publicUrl.startsWith('http')) {
        debugPrint("❌ Invalid public URL generated for $fileName");
        return null;
      }

      // 🔁 Cache busting
      return "$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e, stack) {
      debugPrint("❌ Supabase Upload Error: $e");
      debugPrintStack(stackTrace: stack);
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

  // ===============================
  // 🧠 MIME TYPE HELPER
  // ===============================
  String _getContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/png';
  }
}
