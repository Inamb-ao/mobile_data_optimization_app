import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/services/cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class TrafficManagementService {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final CustomCacheManager cacheManager = CustomCacheManager();
  final Logger logger = Logger();

  static const platform = MethodChannel('traffic_manager_channel');
  Timer? _backgroundMonitoringTimer;

  /// Request necessary permissions
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

  /// Request Usage Stats Permission
  Future<bool> _requestUsageStatsPermission() async {
    try {
      final isGranted = await platform.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
      if (isGranted) {
        logger.i("Usage Stats permission already granted.");
        return true;
      }

      logger.w("Requesting Usage Stats permission...");
      await platform.invokeMethod('requestUsageStatsPermission');
      return false;
    } catch (e) {
      logger.e("Error requesting Usage Stats permission: $e");
      return false;
    }
  }

  /// Collect traffic data
  Future<Map<String, dynamic>> collectTrafficData() async {
    try {
      final networkStats =
          await platform.invokeMapMethod<String, dynamic>('getNetworkStats');

      if (networkStats == null) throw Exception("No network stats received.");

      final mobileRxBytes = (networkStats['mobileRxBytes'] as num?)?.toInt() ?? 0;
      final mobileTxBytes = (networkStats['mobileTxBytes'] as num?)?.toInt() ?? 0;
      final wifiRxBytes = (networkStats['wifiRxBytes'] as num?)?.toInt() ?? 0;
      final wifiTxBytes = (networkStats['wifiTxBytes'] as num?)?.toInt() ?? 0;

      final data = {
        'mobile': {'received': mobileRxBytes, 'transmitted': mobileTxBytes},
        'wifi': {'received': wifiRxBytes, 'transmitted': wifiTxBytes},
      };

      logger.i("Traffic Data: $data");
      await _storeTrafficData('Mobile', mobileRxBytes, mobileTxBytes);
      await _storeTrafficData('Wi-Fi', wifiRxBytes, wifiTxBytes);

      return data;
    } catch (e) {
      logger.e("Error collecting traffic data: $e");
      return {};
    }
  }

  /// Store traffic data
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
    stopRealTimeMonitoring();
    _backgroundMonitoringTimer = Timer.periodic(interval, (_) async {
      try {
        logger.i("Real-time monitoring: Collecting traffic data...");
        await collectTrafficData();
      } catch (e) {
        logger.e("Error in real-time monitoring: $e");
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

  /// Get traffic breakdown
  Future<Map<String, Map<String, int>>> getTrafficBreakdown() async {
    try {
      final trafficData = await getTrafficData();
      final breakdown = <String, Map<String, int>>{};

      for (final entry in trafficData) {
        final category = entry['category'] as String? ?? 'Unknown';
        final received = (entry['received'] as int?) ?? 0;
        final transmitted = (entry['transmitted'] as int?) ?? 0;

        breakdown[category] ??= {'received': 0, 'transmitted': 0};
        breakdown[category]!['received'] =
            (breakdown[category]!['received'] ?? 0) + received;
        breakdown[category]!['transmitted'] =
            (breakdown[category]!['transmitted'] ?? 0) + transmitted;
      }

      return breakdown;
    } catch (e) {
      logger.e("Error retrieving traffic breakdown: $e");
      return {};
    }
  }

  /// Get traffic data
  Future<List<Map<String, dynamic>>> getTrafficData() async {
    try {
      return await dbHelper.getAllData('traffic_data');
    } catch (e) {
      logger.e("Error retrieving traffic data: $e");
      return [];
    }
  }

  /// Clear traffic data
  Future<void> clearTrafficData() async {
    try {
      await dbHelper.deleteAllData('traffic_data');
      logger.i("All traffic data cleared.");
    } catch (e) {
      logger.e("Error clearing traffic data: $e");
    }
  }
}
