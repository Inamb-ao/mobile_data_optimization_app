import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:path/path.dart';


class CustomCacheManager {
  static final CustomCacheManager _instance = CustomCacheManager._internal();

  factory CustomCacheManager() => _instance;

  CustomCacheManager._internal();

  final CacheManager _cacheManager = DefaultCacheManager();
  final Logger _logger = Logger();

  // Persistent cache statistics (can be saved to shared preferences or database)
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _dataSavedByCaching = 0;

  /// Getters for cache statistics
  int get cacheHits => _cacheHits;
  int get cacheMisses => _cacheMisses;
  int get dataSavedByCaching => _dataSavedByCaching;

  /// Fetch data from cache or download it if not cached
  Future<String?> getCachedData(String url, {bool enableCompression = false, int compressionQuality = 70}) async {
    try {
      _logger.i('Fetching file from URL: $url');

      // Check cache
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null) {
        _cacheHits++;
        _logger.i('Cache hit for URL: $url');
        return fileInfo.file.path;
      }

      _cacheMisses++;
      _logger.w('Cache miss for URL: $url');

      // Download and optionally compress
      final Uint8List fileBytes = await _downloadFile(url);
      final List<int> dataToCache = enableCompression
          ? await _compressFile(fileBytes, quality: compressionQuality)
          : fileBytes;

      // Save file to cache
      final File file = await _cacheManager.putFile(url, Uint8List.fromList(dataToCache));
      _dataSavedByCaching += fileBytes.length - dataToCache.length;
      
      // Extract the file extension using the 'path' package
    String fileExtension = extension(file.path).toLowerCase().replaceFirst('.', '');

    // Insert the cache metadata into the database
    await DatabaseHelper().insertCacheMetadata({
      'url': url,
      'path': file.path,
      'size': file.lengthSync(),
      'creation_time': DateTime.now().toIso8601String(),
      'file_type': fileExtension,  // Store the file extension
    });

      _logger.i('File cached at: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Error fetching or caching file from URL: $url', e);
      return null;
    }
  }

  /// Fetch and return the contents of a cached file
  Future<String?> fetchAndReadCachedFile(String url, {bool enableCompression = false}) async {
    try {
      final filePath = await getCachedData(url, enableCompression: enableCompression);
      if (filePath != null) {
        final file = File(filePath);
        final fileContents = await file.readAsString();
        return fileContents;
      }
      return null;
    } catch (e) {
      _logger.e('Error reading cached file from URL: $url', e);
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

  /// Compress file bytes with customizable quality
  Future<List<int>> _compressFile(Uint8List fileBytes, {required int quality}) async {
    _logger.i('Compressing file...');
    return await FlutterImageCompress.compressWithList(
      fileBytes,
      quality: quality,
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
      _resetCacheMetrics();
    } catch (e) {
      _logger.e('Error clearing cache', e);
    }
  }

  /// Reset cache metrics
  void _resetCacheMetrics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _dataSavedByCaching = 0;
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
        'cacheHits': _cacheHits,
        'cacheMisses': _cacheMisses,
        'dataSavedByCaching': _dataSavedByCaching,
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
