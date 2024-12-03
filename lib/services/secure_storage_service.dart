import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Write data securely
  Future<void> writeSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Failed to write secure data: $e');
    }
  }

  /// Read secure data
  Future<String?> readSecureData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw Exception('Failed to read secure data: $e');
    }
  }

  /// Read all secure data
  Future<Map<String, String>> readAllSecureData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw Exception('Failed to read all secure data: $e');
    }
  }

  /// Delete secure data
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete secure data: $e');
    }
  }

  /// Delete all secure data
  Future<void> deleteAllSecureData() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to delete all secure data: $e');
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw Exception('Failed to check key existence: $e');
    }
  }
}
