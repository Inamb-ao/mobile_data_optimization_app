import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final CustomCacheManager _instance = CustomCacheManager._internal();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._internal();

  final BaseCacheManager _cacheManager = DefaultCacheManager();

  // Fetch data from cache or network
  Future<String> getCachedData(String url) async {
    final file = await _cacheManager.getSingleFile(url);
    return file.path;
  }

  // Clear the cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}
