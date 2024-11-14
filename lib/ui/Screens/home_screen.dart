import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cache_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cloud_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/secure_storage_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/traffic_management_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/settings_screen.dart'; // Import the Settings screen
import 'package:mobile_data_optimization_app/ui/Screens/network_stats_screen.dart'; // Import the NetworkStatsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Added const for performance

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper(); // Initialize SQLite Helper

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Optimization App'), // Use const for performance
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _saveNavigation('CacheScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CacheScreen()), // Navigate to CacheScreen
                );
              },
              child: const Text('Cache Management'), // Use const for performance
            ),
            ElevatedButton(
              onPressed: () {
                _saveNavigation('CloudScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CloudScreen()), // Navigate to CloudScreen
                );
              },
              child: const Text('Cloud Service'), // Use const for performance
            ),
            ElevatedButton(
              onPressed: () {
                _saveNavigation('SecureStorageScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecureStorageScreen()), // Navigate to SecureStorageScreen
                );
              },
              child: const Text('Secure Storage'), // Use const for performance
            ),
            ElevatedButton(
              onPressed: () {
                _saveNavigation('TrafficManagementScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrafficManagementScreen()), // Navigate to Traffic Management
                );
              },
              child: const Text('Traffic Management'), // Button for Traffic Management
            ),
            ElevatedButton(
              onPressed: () {
                _saveNavigation('NetworkStatsScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NetworkStatsScreen()), // Navigate to NetworkStatsScreen
                );
              },
              child: const Text('Network Statistics'), // Button for Network Stats
            ),
            ElevatedButton(
              onPressed: () {
                _saveNavigation('SettingsScreen');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()), // Navigate to SettingsScreen
                );
              },
              child: const Text('Settings'), // Button for Settings
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                List<Map<String, dynamic>> data = await dbHelper.getAllData();
                _showSnackBar('Navigation history: ${data.toString()}');
              },
              child: const Text('View Navigation History'),
            ),
          ],
        ),
      ),
    );
  }

  // Method to save navigation actions into the database
  void _saveNavigation(String screenName) async {
    await dbHelper.insertData({
      'name': 'LastVisitedScreen',
      'value': screenName,
    });
    _showSnackBar('Navigated to $screenName');
  }

  // Method to display feedback using a SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
