import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';  // Import the logger package

class TrafficManagementService {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final Logger logger = Logger();  // Initialize the logger

  static const platform = MethodChannel('traffic_manager_channel');

  // Request necessary permissions (only requesting phone permission, handle usage stats manually)
  Future<bool> requestPermissions() async {
    // Request Phone permission using permission_handler
    var phonePermission = await Permission.phone.request();

    if (phonePermission.isGranted) {
      return true;  // Phone permission granted
    } else {
      return false;  // Phone permission denied
    }
  }

  // Collect traffic data using network statistics from native Android code
  Future<void> collectTrafficData() async {
    // First, request necessary permissions
    bool permissionsGranted = await requestPermissions();

    if (permissionsGranted) {
      try {
        // Call the platform channel to retrieve network stats
        final int networkUsage = await platform.invokeMethod('getNetworkStats');
        logger.i('Total network usage: $networkUsage bytes');  // Use logger instead of print

        // Store the traffic data in the database
        await dbHelper.insertData({
          'name': 'TrafficData',
          'value': networkUsage,  // Save total network usage
        });
      } on PlatformException catch (e) {
        logger.e("Failed to get network stats: '${e.message}'");  // Use logger for error
      }
    } else {
      throw Exception('Permissions not granted. Cannot collect traffic data.');
    }
  }

  // Retrieve traffic data from the database
  Future<List<Map<String, dynamic>>> getTrafficData() async {
    return await dbHelper.getDataByName('TrafficData');
  }

  // Delete traffic data from the database (optional)
  Future<void> clearTrafficData() async {
    await dbHelper.deleteAllData();
  }
}
