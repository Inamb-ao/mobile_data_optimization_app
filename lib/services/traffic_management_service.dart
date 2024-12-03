import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/services/cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class TrafficManagementService {
  final DatabaseHelper dbHelper = DatabaseHelper(); // SQLite database helper
  final CustomCacheManager cacheManager = CustomCacheManager(); // Cache manager instance
  final Logger logger = Logger(); // Logger for better debugging

  static const platform = MethodChannel('traffic_manager_channel');

  Timer? _backgroundMonitoringTimer; // Timer for background monitoring

  /// Request necessary permissions (Phone and Usage Stats)
  Future<bool> requestPermissions() async {
    try {
      final phonePermission = await Permission.phone.request();
      if (!phonePermission.isGranted) {
        logger.e("Phone permission denied.");
        return false;
      }

      final bool usageStatsGranted = await _requestUsageStatsPermission();
      if (!usageStatsGranted) {
        logger.e("Usage Stats permission denied.");
        return false;
      }

      logger.i("All permissions granted.");
      return true;
    } catch (e) {
      logger.e("Error requesting permissions: $e");
      return false;
    }
  }

  /// Check and request Usage Stats Permission
  Future<bool> _requestUsageStatsPermission() async {
    try {
      final bool isGranted =
          await platform.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
      if (isGranted) {
        logger.i("Usage Stats permission already granted.");
        return true;
      }

      logger.w("Usage Stats permission not granted. Requesting permission...");
      await platform.invokeMethod('requestUsageStatsPermission');
      return false;
    } catch (e) {
      logger.e("Error checking/requesting Usage Stats permission: $e");
      return false;
    }
  }

  /// Collect categorized traffic data
  Future<Map<String, dynamic>> collectTrafficData() async {
    try {
      final networkStats =
          await platform.invokeMapMethod<String, dynamic>('getNetworkStats');

      if (networkStats == null) {
        throw Exception("No network stats received.");
      }

      final int mobileRxBytes =
          (networkStats['mobileRxBytes'] as num?)?.toInt() ?? 0;
      final int mobileTxBytes =
          (networkStats['mobileTxBytes'] as num?)?.toInt() ?? 0;
      final int wifiRxBytes =
          (networkStats['wifiRxBytes'] as num?)?.toInt() ?? 0;
      final int wifiTxBytes =
          (networkStats['wifiTxBytes'] as num?)?.toInt() ?? 0;

      final data = {
        'mobile': {'received': mobileRxBytes, 'transmitted': mobileTxBytes},
        'wifi': {'received': wifiRxBytes, 'transmitted': wifiTxBytes},
      };

      logger.i("Traffic Data: $data");

      // Store data in the database
      await _storeTrafficData('Mobile', mobileRxBytes, mobileTxBytes);
      await _storeTrafficData('Wi-Fi', wifiRxBytes, wifiTxBytes);

      return data;
    } catch (e) {
      logger.e("Error collecting traffic data: $e");
      return {};
    }
  }

  /// Store traffic data in the database
  Future<void> _storeTrafficData(
      String category, int received, int transmitted) async {
    try {
      await dbHelper.insertData('traffic_data', {
        'category': category,
        'received': received,
        'transmitted': transmitted,
        'timestamp': DateTime.now().toIso8601String(),
      });
      logger.i("$category traffic data stored successfully.");
    } catch (e) {
      logger.e("Error storing $category traffic data: $e");
    }
  }

  /// Start real-time monitoring
  void startRealTimeMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _backgroundMonitoringTimer?.cancel();
    _backgroundMonitoringTimer = Timer.periodic(interval, (timer) async {
      try {
        logger.i("Collecting traffic data in real-time...");
        await collectTrafficData();
      } catch (e) {
        logger.e("Error during real-time monitoring: $e");
      }
    });
    logger.i("Real-time monitoring started with interval: $interval.");
  }

  /// Stop real-time monitoring
  void stopRealTimeMonitoring() {
    _backgroundMonitoringTimer?.cancel();
    _backgroundMonitoringTimer = null;
    logger.i("Real-time monitoring stopped.");
  }

  /// Retrieve traffic data from the database
  Future<List<Map<String, dynamic>>> getTrafficData() async {
    try {
      final data = await dbHelper.getAllData('traffic_data');
      logger.i("Retrieved traffic data: $data");
      return data;
    } catch (e) {
      logger.e("Error retrieving traffic data: $e");
      return [];
    }
  }

  /// Retrieve traffic breakdown by category
  Future<Map<String, Map<String, int>>> getTrafficBreakdown() async {
    try {
      final trafficData = await getTrafficData();
      final Map<String, Map<String, int>> breakdown = {};

      for (var entry in trafficData) {
        final category = entry['category'] as String? ?? 'Unknown';
        final received = entry['received'] as int? ?? 0;
        final transmitted = entry['transmitted'] as int? ?? 0;

        breakdown[category] ??= {'received': 0, 'transmitted': 0};
        breakdown[category]!['received'] =
            (breakdown[category]!['received'] ?? 0) + received;
        breakdown[category]!['transmitted'] =
            (breakdown[category]!['transmitted'] ?? 0) + transmitted;
      }

      logger.i("Traffic Breakdown: $breakdown");
      return breakdown;
    } catch (e) {
      logger.e("Error retrieving traffic breakdown: $e");
      return {};
    }
  }

  /// Clear all traffic data
  Future<void> clearTrafficData() async {
    try {
      await dbHelper.deleteAllData('traffic_data');
      logger.i("All traffic data cleared.");
    } catch (e) {
      logger.e("Error clearing traffic data: $e");
    }
  }
}
