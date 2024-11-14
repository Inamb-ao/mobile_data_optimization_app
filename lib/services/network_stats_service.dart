import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class NetworkStatsService {
  static const platform = MethodChannel('traffic_manager_channel');
  final Logger _logger = Logger(); // Create a Logger instance

  Future<int> getNetworkStats() async {
    try {
      final int result = await platform.invokeMethod('getNetworkStats');
      _logger.i("Network stats fetched successfully: $result bytes");
      return result; // Returns the total network usage in bytes
    } on PlatformException catch (e) {
      _logger.e("Failed to fetch network stats", e);
      return -1; // Return -1 on error
    }
  }
}
