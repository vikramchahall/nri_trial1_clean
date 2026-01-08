import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/storage_repo.dart';

class SupabaseStorageRepo implements StorageRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================
  // 🔁 SHARED UPLOAD HELPER (WEB + MOBILE)
  // ===============================
  Future<String?> _upload(
    Uint8List bytes,
    String bucket,
    String fileName,
  ) async {
    try {
      // 🧠 Detect correct MIME type
      final String contentType = _getContentType(fileName);

      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      // ✅ Get PUBLIC URL (required for Flutter Web)
      final String publicUrl =
          _supabase.storage.from(bucket).getPublicUrl(fileName);

      if (publicUrl.isEmpty || !publicUrl.startsWith('http')) {
        debugPrint("❌ Invalid public URL generated for $fileName");
        return null;
      }

      // 🔁 Cache-busting so updated images reflect immediately
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
    return 'image/png'; // default fallback
  }
}
