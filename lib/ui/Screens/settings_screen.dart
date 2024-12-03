import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart'; // Import the database helper
import 'package:mobile_data_optimization_app/services/cache_manager.dart'; // Import the custom cache manager
import 'package:mobile_data_optimization_app/services/compression_service.dart'; // Import the compression service

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // Database helper
  final CustomCacheManager cacheManager = CustomCacheManager(); // Custom cache manager
  final CompressionService compressionService = CompressionService(); // Compression service
  bool isCompressionEnabled = false; // Default setting for data compression
  bool isCachingEnabled = true; // Default setting for caching
  int cacheSizeLimit = 50; // Default cache size limit in MB
  bool isLoading = true; // Loading state indicator
  int compressionSavings = 0; // Data saved through compression in bytes

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load all settings on initialization
  }

  /// Load settings from the database
  Future<void> _loadSettings() async {
    setState(() => isLoading = true);
    try {
      // Load compression setting
      final compressionResult =
          await dbHelper.getDataByName('settings', 'name', 'CompressionEnabled');
      if (compressionResult.isNotEmpty) {
        isCompressionEnabled = compressionResult.first['value'] == 1;
      }

      // Load caching setting
      final cachingResult =
          await dbHelper.getDataByName('settings', 'name', 'CachingEnabled');
      if (cachingResult.isNotEmpty) {
        isCachingEnabled = cachingResult.first['value'] == 1;
      }

      // Load cache size limit
      final cacheSizeResult =
          await dbHelper.getDataByName('settings', 'name', 'CacheSizeLimit');
      if (cacheSizeResult.isNotEmpty) {
        cacheSizeLimit = cacheSizeResult.first['value'];
      }

      // Load compression savings
      final compressionSavingsResult = await dbHelper.getDataByName(
          'settings', 'name', 'CompressionSavings');
      if (compressionSavingsResult.isNotEmpty) {
        compressionSavings = compressionSavingsResult.first['value'];
      }
    } catch (e) {
      _showSnackBar('Error loading settings: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSwitchTile(
                  title: 'Enable Data Compression',
                  value: isCompressionEnabled,
                  onChanged: (bool value) => _saveSetting(
                    settingName: 'CompressionEnabled',
                    value: value,
                    onChangedCallback: () =>
                        setState(() => isCompressionEnabled = value),
                  ),
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Enable Caching',
                  value: isCachingEnabled,
                  onChanged: (bool value) => _saveSetting(
                    settingName: 'CachingEnabled',
                    value: value,
                    onChangedCallback: () =>
                        setState(() => isCachingEnabled = value),
                  ),
                ),
                const Divider(),
                _buildCacheSizeLimitTile(),
                const Divider(),
                ListTile(
                  title: const Text('Compression Savings'),
                  subtitle: Text(
                      '${(compressionSavings / (1024 * 1024)).toStringAsFixed(2)} MB saved'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _clearCache,
                  child: const Text('Clear Cache'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _simulateCompression,
                  child: const Text('Simulate Compression'),
                ),
              ],
            ),
    );
  }

  /// Simulate data compression and calculate savings
  Future<void> _simulateCompression() async {
    try {
     final testData = 'This is some sample data to compress!'.codeUnits;
      final compressedData =
          compressionService.compressData(testData); // Compress data
      final decompressedData =
          compressionService.decompressData(compressedData); // Decompress data

      if (String.fromCharCodes(decompressedData) ==
          String.fromCharCodes(testData)) {
        final savings = testData.length - compressedData.length;
        setState(() {
          compressionSavings += savings;
        });

        await _saveSetting(
          settingName: 'CompressionSavings',
          value: compressionSavings,
          onChangedCallback: () {},
        );

        _showSnackBar('Data compressed successfully. Savings: $savings bytes');
      } else {
        _showSnackBar('Compression integrity check failed.');
      }
    } catch (e) {
      _showSnackBar('Error during compression: $e');
    }
  }

  /// Build a tile for cache size limit input
  Widget _buildCacheSizeLimitTile() {
    return ListTile(
      title: const Text('Cache Size Limit (MB)'),
      subtitle: Text('Current: $cacheSizeLimit MB'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          final newSize = await _showCacheSizeInputDialog();
          if (newSize != null) {
            await _saveSetting(
              settingName: 'CacheSizeLimit',
              value: newSize,
              onChangedCallback: () =>
                  setState(() => cacheSizeLimit = newSize),
            );
          }
        },
      ),
    );
  }

  /// Show a dialog for cache size input
  Future<int?> _showCacheSizeInputDialog() async {
    int? newSize;
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Cache Size Limit'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter size in MB',
            ),
            onChanged: (value) {
              newSize = int.tryParse(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, newSize),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Save a setting to the database
  Future<void> _saveSetting({
    required String settingName,
    required dynamic value,
    required VoidCallback onChangedCallback,
  }) async {
    try {
      await dbHelper.insertData(
        'settings',
        {
          'name': settingName,
          'value': value,
        },
      );
      onChangedCallback(); // Update UI state
      _showSnackBar('$settingName saved successfully');
    } catch (e) {
      _showSnackBar('Error saving $settingName: $e');
    }
  }

  /// Clear cache using the custom cache manager
  Future<void> _clearCache() async {
    try {
      await cacheManager.clearCache(); // Use the custom cache manager to clear cache
      _showSnackBar('Cache cleared successfully.');
    } catch (e) {
      _showSnackBar('Error clearing cache: $e');
    }
  }

  /// Build a switch tile widget
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
      subtitle: Text(
        value ? 'Enabled' : 'Disabled',
        style: TextStyle(color: value ? Colors.green : Colors.red),
      ),
    );
  }

  /// Show feedback using SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
