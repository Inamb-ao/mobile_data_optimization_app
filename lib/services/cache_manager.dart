import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';

class CustomCacheManager {
  // Singleton instance
  static final CustomCacheManager _instance = CustomCacheManager._internal();

  // Factory constructor to return the singleton instance
  factory CustomCacheManager() {
    return _instance;
  }

  // Private internal constructor for singleton implementation
  CustomCacheManager._internal();

  // Cache manager instance (can be customized with a TTL or max cache size)
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  // Initialize the logger
  final Logger _logger = Logger();

  // Fetch data from cache or download it if not cached
  // Returns the file path of the cached or downloaded file
  Future<String?> getCachedData(String url) async {
    try {
      _logger.i('Fetching file from URL: $url');
      
      // Download and cache the file (or retrieve it from the cache if available)
      final file = await _cacheManager.getSingleFile(url);

      _logger.i('File cached at: ${file.path}');
      // Return the file path
      return file.path;
    } catch (e) {
      // Log the error
      _logger.e('Error fetching or caching file from URL: $url', e);
      return null;
    }
  }

  // Retrieve file information from cache without downloading
  // Returns the file path if the file is found in the cache
  Future<String?> getCacheOnly(String url) async {
    try {
      _logger.i('Attempting to retrieve file from cache: $url');
      
      // Check if the file is already in the cache
      final fileInfo = await _cacheManager.getFileFromCache(url);
      
      if (fileInfo != null) {
        _logger.i('File retrieved from cache: ${fileInfo.file.path}');
        // File found in cache, return its path
        return fileInfo.file.path;
      }
      
      _logger.w('File not found in cache: $url');
      return null;
    } catch (e) {
      // Log the error
      _logger.e('Error retrieving file from cache: $url', e);
      return null;
    }
  }

  // Clear all files in the cache
  Future<void> clearCache() async {
    try {
      _logger.i('Clearing cache...');
      
      // Empty the cache
      await _cacheManager.emptyCache();
      
      _logger.i('Cache cleared successfully.');
    } catch (e) {
      // Log the error
      _logger.e('Error clearing cache', e);
    }
  }

  // Optional: Fetch data with a customizable cache expiry duration (TTL)
  // TTL defines how long files should be kept in the cache before expiration
  Future<String?> getCachedDataWithTTL(String url, {Duration ttl = const Duration(days: 7)}) async {
    try {
      _logger.i('Fetching file with TTL from URL: $url (TTL: $ttl)');
      
      // Customize the cache with TTL (Time To Live)
      final cacheManager = CacheManager(
        Config(
          'customCacheKey', // Unique key for this cache
          stalePeriod: ttl, // Expiry duration
        ),
      );

      // Fetch or download the file
      final file = await cacheManager.getSingleFile(url);

      _logger.i('File cached with TTL at: ${file.path}');
      return file.path;
    } catch (e) {
      // Log the error
      _logger.e('Error fetching file with TTL from URL: $url', e);
      return null;
    }
  }
}
