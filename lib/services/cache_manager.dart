import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart'; // For Uint8List and consolidateHttpClientResponseBytes

class CustomCacheManager {
  // Singleton instance
  static final CustomCacheManager _instance = CustomCacheManager._internal();

  // Factory constructor to return the singleton instance
  factory CustomCacheManager() {
    return _instance;
  }

  // Private internal constructor for singleton implementation
  CustomCacheManager._internal();

  // Cache manager instance
  final CacheManager _cacheManager = DefaultCacheManager();

  // Initialize the logger
  final Logger _logger = Logger();

  // Cache statistics
  int cacheHits = 0;
  int cacheMisses = 0;
  int dataSavedByCaching = 0;

  /// Fetch data from cache or download it if not cached
  /// Supports optional compression for reduced size
  Future<String?> getCachedData(String url, {bool enableCompression = false}) async {
    try {
      _logger.i('Fetching file from URL: $url');

      // Check if the file exists in cache
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        cacheHits++;
        _logger.i('Cache hit for URL: $url');
        return fileInfo.file.path;
      }

      cacheMisses++;
      _logger.w('Cache miss for URL: $url');

      // Download the file and optionally compress it
      final Uint8List fileBytes = await _downloadFile(url);
      final List<int> dataToCache = enableCompression
          ? await _compressFile(fileBytes)
          : fileBytes;

      // Save the file to cache
      final File file = await _cacheManager.putFile(url, Uint8List.fromList(dataToCache));
      dataSavedByCaching += fileBytes.length - dataToCache.length;

      _logger.i('File cached at: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Error fetching or caching file from URL: $url', e);
      return null;
    }
  }

  /// Retrieve file information from cache without downloading
  Future<String?> getCacheOnly(String url) async {
    try {
      _logger.i('Attempting to retrieve file from cache: $url');

      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        _logger.i('File retrieved from cache: ${fileInfo.file.path}');
        return fileInfo.file.path;
      }

      _logger.w('File not found in cache: $url');
      return null;
    } catch (e) {
      _logger.e('Error retrieving file from cache: $url', e);
      return null;
    }
  }

  /// Compress file bytes
  Future<List<int>> _compressFile(Uint8List fileBytes) async {
    _logger.i('Compressing file...');
    return await FlutterImageCompress.compressWithList(
      fileBytes,
      quality: 70, // Compression quality
    );
  }

  /// Download file bytes
  Future<Uint8List> _downloadFile(String url) async {
    _logger.i('Downloading file from URL: $url');
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(Uri.parse(url));
    final HttpClientResponse response = await request.close();
    return await consolidateHttpClientResponseBytes(response);
  }

  /// Clear all files in the cache
  Future<void> clearCache() async {
    try {
      _logger.i('Clearing cache...');
      await _cacheManager.emptyCache();
      _logger.i('Cache cleared successfully.');
    } catch (e) {
      _logger.e('Error clearing cache', e);
    }
  }

  /// Calculate the total size of the cache
  Future<int> getCacheSize() async {
    try {
      _logger.i('Calculating cache size...');
      final cacheDirectory = await _getCacheDirectory();
      int totalSize = 0;

      if (cacheDirectory.existsSync()) {
        cacheDirectory.listSync(recursive: true).forEach((file) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        });
      }

      _logger.i('Total cache size: $totalSize bytes');
      return totalSize;
    } catch (e) {
      _logger.e('Error calculating cache size', e);
      return 0;
    }
  }

  /// Get metadata for all cached files
  Future<List<Map<String, dynamic>>> getCachedFilesMetadata() async {
    try {
      _logger.i('Fetching cached files metadata...');
      final cacheDirectory = await _getCacheDirectory();
      List<Map<String, dynamic>> metadata = [];

      if (cacheDirectory.existsSync()) {
        cacheDirectory.listSync(recursive: true).forEach((file) {
          if (file is File) {
            metadata.add({
              'path': file.path,
              'size': file.lengthSync(),
              'lastModified': file.lastModifiedSync().toIso8601String(),
            });
          }
        });
      }

      return metadata;
    } catch (e) {
      _logger.e('Error fetching cached files metadata', e);
      return [];
    }
  }

  /// Delete a specific file from the cache
  Future<void> deleteCachedFile(String url) async {
    try {
      _logger.i('Deleting file from cache: $url');
      await _cacheManager.removeFile(url);
      _logger.i('File deleted successfully from cache.');
    } catch (e) {
      _logger.e('Error deleting file from cache: $url', e);
    }
  }

  /// Provide a summary of the cache
  Future<Map<String, dynamic>> getCacheSummary() async {
    try {
      final totalSize = await getCacheSize();
      final cacheFiles = await getCachedFilesMetadata();

      return {
        'totalSize': totalSize,
        'fileCount': cacheFiles.length,
        'files': cacheFiles,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'dataSavedByCaching': dataSavedByCaching,
      };
    } catch (e) {
      _logger.e('Error fetching cache summary', e);
      return {};
    }
  }

  /// Retrieve the cache directory path
  Future<Directory> _getCacheDirectory() async {
    final Directory cacheDirectory = await getTemporaryDirectory();
    final Directory customCacheDirectory = Directory('${cacheDirectory.path}/cache');
    if (!customCacheDirectory.existsSync()) {
      customCacheDirectory.createSync(recursive: true);
    }
    return customCacheDirectory;
  }
}
