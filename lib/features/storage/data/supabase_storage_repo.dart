import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/features/storage/domain/storage_repo.dart';


class SupabaseStorageRepo implements StorageRepo {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<String?> uploadPostImageMobile(
    Uint8List bytes,
    String filePath,
  ) async {
    try {
      // Upload image
      await _supabase.storage
          .from('post_images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );

      // Get public URL
      final url = _supabase.storage
          .from('post_images')
          .getPublicUrl(filePath);

      return url;
    } catch (e) {
      print("❌ SUPABASE UPLOAD ERROR: $e");
      return null;
    }
  }
}
