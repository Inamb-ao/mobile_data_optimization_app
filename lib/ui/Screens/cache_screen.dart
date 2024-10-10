import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Provides Uint8List and kIsWeb
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';  // For mobile/desktop

class CacheScreen extends StatefulWidget {
  const CacheScreen({super.key});

  @override
  CacheScreenState createState() => CacheScreenState();
}

class CacheScreenState extends State<CacheScreen> {
  final Logger logger = Logger();  // Logger for logging events
  Uint8List? cachedFileBytes;  // Store the raw bytes of the cached file (for mobile/desktop)
  Uint8List? webImageCache;  // In-memory cache for web
  final String url = 'https://cdn.shopify.com/s/files/1/0263/6270/8027/files/tenshi-Nike-logo.jpg?v=1584898573';  // Image URL
  bool isValidMedia = false;
  double downloadProgress = 0.0;  // Variable to track download progress

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _showSnackBar('Downloading and caching file...');
                _downloadAndCacheFileWithProgress();
              },
              child: const Text('Cache File'),
            ),
            ElevatedButton(
              onPressed: () {
                _showSnackBar('Retrieving cached file...');
                _retrieveFile();
              },
              child: const Text('Retrieve Cached File'),
            ),
            ElevatedButton(
              onPressed: () {
                _showSnackBar('Clearing cache...');
                _clearCache();
              },
              child: const Text('Clear Cache'),
            ),
            const SizedBox(height: 20),
            if (downloadProgress > 0 && downloadProgress < 1)
              Column(
                children: [
                  const Text('Downloading...'),
                  LinearProgressIndicator(value: downloadProgress),
                  Text('${(downloadProgress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            if (isValidMedia && webImageCache != null)
              Column(
                children: [
                  const Text('Retrieved Cached Image:'),
                  Image.memory(
                    webImageCache!,
                    fit: BoxFit.cover,
                  ),  // Show image from memory cache
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Async method to download and cache the file with progress tracking
  Future<void> _downloadAndCacheFileWithProgress() async {
    try {
      logger.i('Downloading file from URL...');
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        int totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;
        List<int> bytes = [];

        response.stream.listen(
          (chunk) {
            bytes.addAll(chunk);
            receivedBytes += chunk.length;

            if (totalBytes > 0 && mounted) {
              setState(() {
                downloadProgress = receivedBytes / totalBytes;
              });
            }
          },
          onDone: () async {
            Uint8List fileBytes = Uint8List.fromList(bytes);
            if (kIsWeb) {
              // Cache the image in memory on web
              setState(() {
                webImageCache = fileBytes;
                isValidMedia = true;  // Ensure that we mark the media as valid after caching
              });
              logger.i('Web image cached in memory');
              _showSnackBar('Web image cached successfully!');
            } else {
              // Cache the file on mobile/desktop
              final filePath = await DefaultCacheManager().putFile(url, fileBytes);
              logger.i('File cached at: $filePath');
              if (mounted) {
                setState(() {
                  cachedFileBytes = fileBytes;
                  downloadProgress = 1.0;
                });
              }
              _showSnackBar('File cached successfully!');
            }
          },
          onError: (e) {
            logger.e('Error downloading file: $e');
            _showSnackBar('Error downloading file.');
          },
          cancelOnError: true,
        );
      } else {
        logger.e('Failed to download file, status code: ${response.statusCode}');
        _showSnackBar('Failed to download file.');
      }
    } catch (e) {
      logger.e('Error downloading or caching file: $e');
      _showSnackBar('Error downloading or caching file.');
    }
  }

  // Async method to retrieve cached file and display it
  Future<void> _retrieveFile() async {
    if (kIsWeb) {
      // Display the cached image from memory on web
      if (webImageCache != null) {
        setState(() {
          isValidMedia = true;
        });
        _showSnackBar('Web image loaded from memory cache.');
      } else {
        _showSnackBar('No image found in memory cache.');
      }
      return;
    }

    // Mobile/Desktop logic for retrieving cached file
    // Add your mobile/desktop logic here (this part has been omitted for simplicity)
  }

  // Async method to clear the cache
  Future<void> _clearCache() async {
    if (kIsWeb) {
      setState(() {
        webImageCache = null;  // Clear in-memory cache for web
      });
      _showSnackBar('In-memory cache cleared (Web).');
      return;
    }

    // Mobile/Desktop logic for clearing cache
    // Add your mobile/desktop logic here (this part has been omitted for simplicity)
  }

  // Show a SnackBar to provide feedback to the user
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
