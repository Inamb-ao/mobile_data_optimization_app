import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Write data securely
  Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read secure data
  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  // Delete secure data
  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }
}
