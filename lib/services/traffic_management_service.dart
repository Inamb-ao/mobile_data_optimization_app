import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';  // Import the logger package

class TrafficManagementService {
  final DatabaseHelper dbHelper = DatabaseHelper(); // SQLite database helper
  final Logger logger = Logger(); // Logger for better logging and debugging

  // Platform channel for native Android communication
  static const platform = MethodChannel('traffic_manager_channel');

  /// Request necessary permissions (Phone permission, handle usage stats manually)
  Future<bool> requestPermissions() async {
    // Request Phone permission using permission_handler
    var phonePermission = await Permission.phone.request();

    if (phonePermission.isGranted) {
      logger.i("Phone permission granted."); // Log permission status
      return true;
    } else {
      logger.e("Phone permission denied."); // Log permission status
      return false;
    }
  }

  /// Collect traffic data using network statistics from native Android code
  Future<void> collectTrafficData() async {
    // Step 1: Request necessary permissions
    bool permissionsGranted = await requestPermissions();

    if (permissionsGranted) {
      try {
        // Step 2: Invoke the platform channel to retrieve network stats
        final Map<String, dynamic> networkStats =
            await platform.invokeMapMethod<String, dynamic>('getNetworkStats') ?? {};

        // Log the stats retrieved
        logger.i("Network stats retrieved: $networkStats");

        // Step 3: Store network stats in the database
        await dbHelper.insertData({
          'name': 'TrafficData',
          'value': networkStats['totalRxBytes'] + networkStats['totalTxBytes'], // Save total data usage
        });

        logger.i("Traffic data successfully saved to database.");
      } on PlatformException catch (e) {
        // Log platform exceptions
        logger.e("Failed to retrieve network stats: '${e.message}'");
      } catch (e) {
        // Log any other exceptions
        logger.e("Unexpected error: $e");
      }
    } else {
      // Throw exception if permissions are not granted
      throw Exception('Permissions not granted. Cannot collect traffic data.');
    }
  }

  /// Retrieve traffic data from the database
  Future<List<Map<String, dynamic>>> getTrafficData() async {
    try {
      // Fetch all data entries with name 'TrafficData'
      List<Map<String, dynamic>> data = await dbHelper.getDataByName('TrafficData');
      logger.i("Traffic data retrieved from database: $data");
      return data;
    } catch (e) {
      logger.e("Failed to retrieve traffic data: $e");
      return [];
    }
  }

  /// Delete all traffic data from the database
  Future<void> clearTrafficData() async {
    try {
      await dbHelper.deleteAllData();
      logger.i("All traffic data cleared from database.");
    } catch (e) {
      logger.e("Failed to clear traffic data: $e");
    }
  }
}
