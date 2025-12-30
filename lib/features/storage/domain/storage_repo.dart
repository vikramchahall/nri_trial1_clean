import 'dart:typed_data';

abstract class StorageRepo {
  // We use Uint8List because it works for both Mobile and Web
  Future<String?> uploadPostImageMobile(Uint8List bytes, String fileName);
}