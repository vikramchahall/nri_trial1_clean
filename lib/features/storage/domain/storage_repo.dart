import 'dart:typed_data';

abstract class StorageRepo {
  Future<String?> uploadPostImageMobile(Uint8List bytes, String fileName);
  Future<String?> uploadProfileImageMobile(Uint8List bytes, String fileName);

  Future<String?> uploadPostImageWeb(Uint8List bytes, String fileName);
  Future<String?> uploadProfileImageWeb(Uint8List bytes, String fileName);
}
