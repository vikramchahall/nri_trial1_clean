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
      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      final String publicUrl =
          _supabase.storage.from(bucket).getPublicUrl(fileName);

      // 🔁 Cache-busting so updated images show immediately
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
