import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import 'dart:io'; // For file operations
import 'package:intl/intl.dart'; // For date formatting
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/services/cache_manager.dart'; 

class CacheScreen extends StatefulWidget {
  const CacheScreen({super.key});

  @override
  CacheScreenState createState() => CacheScreenState();
}

class CacheScreenState extends State<CacheScreen> {
  final Logger logger = Logger();
  final DatabaseHelper dbHelper = DatabaseHelper();
  final CustomCacheManager cacheManager = CustomCacheManager();
  int totalCacheSize = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int dataSaved = 0;
  List<Map<String, dynamic>> cachedFiles = [];
  bool isLoading = true;
  final TextEditingController urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCacheSummary();
  }

  Future<void> _loadCacheSummary() async {
    setState(() => isLoading = true);
    try {
      final metadata = await cacheManager.getCachedFilesMetadata();
      logger.i("Fetched cache metadata: $metadata");

      if (metadata.isNotEmpty) {
        final cacheSummary = await _calculateCacheStatistics(metadata);
        if (mounted) {
          setState(() {
            totalCacheSize = cacheSummary['totalSize'] ?? 0;
            cacheHits = cacheManager.cacheHits;
            cacheMisses = cacheManager.cacheMisses;
            dataSaved = cacheManager.dataSavedByCaching;
            cachedFiles = metadata;
          });
        }
      } else {
        logger.w("No cache metadata found.");
      }
    } catch (e) {
      logger.e('Error loading cache summary: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _calculateCacheStatistics(
      List<Map<String, dynamic>> metadata) async {
    int totalSize = 0;
    for (var file in metadata) {
      final fileSize = (file['size'] as num?)?.toInt() ?? 0;
      totalSize += fileSize;
    }

    return {
      'totalSize': totalSize,
    };
  }

  Future<void> _addFileToCache(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL cannot be empty.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final filePath = await cacheManager.getCachedData(url);
     if (filePath != null) {
  // Check if the widget is still mounted before showing the SnackBar
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File cached successfully.')),
    );
  }
  await _loadCacheSummary();
} else {
  // Check if the widget is still mounted before showing the SnackBar
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to cache the file.')),
    );
  }
      }
    } catch (e) {
      logger.e('Error adding file to cache: $e');
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
  }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _previewFile(String filePath) {
    if (File(filePath).existsSync()) {
      final fileExtension = filePath.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(filePath: filePath),
          ),
        );
      } else if (['txt', 'log', 'json'].contains(fileExtension)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextPreviewScreen(filePath: filePath),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preview not supported for this file type.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cache Management')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUrlInputField(),
                    const SizedBox(height: 20),
                    _buildSummarySection(),
                    const SizedBox(height: 20),
                    _buildStatisticsChart(),
                    const SizedBox(height: 20),
                    _buildCachedFilesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUrlInputField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'Enter URL',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _addFileToCache(urlController.text),
          child: const Text('Cache'),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
                'Total Size: ${(totalCacheSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
            Text('Cache Hits: $cacheHits'),
            Text('Cache Misses: $cacheMisses'),
            Text(
                'Data Saved: ${(dataSaved / (1024 * 1024)).toStringAsFixed(2)} MB'),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedFilesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cachedFiles.length,
      itemBuilder: (context, index) {
        final file = cachedFiles[index];
        final fileSize = (file['size'] as num?)?.toDouble() ?? 0.0;

        return ListTile(
          title: Text(file['path'] ?? 'Unknown File'),
          subtitle: Text(
            'Size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB\n'
            'Last Modified: ${_formatDate(file['lastModified'])}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () => _previewFile(file['path']),
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    try {
      return DateFormat.yMMMd().format(DateTime.parse(dateString ?? ""));
    } catch (_) {
      return "Unknown Date";
    }
  }

  Widget _buildStatisticsChart() {
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Text('Hits');
                  case 1:
                    return const Text('Misses');
                  default:
                    return const Text('');
                }
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: cacheHits.toDouble(), color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: cacheMisses.toDouble(), color: Colors.red)],
          ),
        ],
      ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String filePath;

  const ImagePreviewScreen({required this.filePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Preview')),
      body: Center(child: Image.file(File(filePath))),
    );
  }
}

class TextPreviewScreen extends StatelessWidget {
  final String filePath;

  const TextPreviewScreen({required this.filePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Preview')),
      body: FutureBuilder<String>(
        future: File(filePath).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(snapshot.data ?? 'No content available.'),
            );
          }
        },
      ),
    );
  }
}
