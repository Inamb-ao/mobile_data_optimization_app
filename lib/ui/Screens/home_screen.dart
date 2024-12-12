import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // For runtime permissions
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cache_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cloud_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/compression_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/secure_storage_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/traffic_management_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/settings_screen.dart' as settings; // Alias for resolving conflicts
import 'package:logger/logger.dart';
import 'package:flutter/services.dart'; // For MethodChannel

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TrafficManagementService trafficService = TrafficManagementService();
  final Logger logger = Logger();

  static const _channel = MethodChannel('traffic_manager_channel');
  int trafficSavings = 0; // Traffic savings in bytes
  bool isLoading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    _loadData();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel(); // Cancel the timer to prevent leaks
    super.dispose();
  }

  /// Check and request necessary permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      // Request runtime permissions
      final phonePermission = await Permission.phone.request();
      final storagePermission = await Permission.storage.request();

      if (phonePermission.isDenied || storagePermission.isDenied) {
        _showSnackBar("Some permissions are missing. Please enable them in settings.");
      }

      // Check Usage Stats permission
      final hasUsagePermission = await _checkUsageStatsPermission();
      if (!hasUsagePermission) {
        await _requestUsageStatsPermission();
      }
    } catch (e) {
      logger.e("Error requesting permissions: $e");
      _showSnackBar("Error checking permissions. Please try again.");
    }
  }

  /// Check if the app has Usage Stats permission
  Future<bool> _checkUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      logger.e("Error checking usage stats permission: $e");
      return false;
    }
  }

  /// Request Usage Stats permission
  Future<void> _requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
      _showSnackBar("Please grant Usage Stats permission in the settings.");
    } catch (e) {
      logger.e("Error requesting usage stats permission: $e");
    }
  }

  /// Load data and update state
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final savings = await _calculateTrafficSavings();
      if (mounted) {
        setState(() {
          trafficSavings = savings;
          isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Error loading data: $e");
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Error fetching traffic data. Please try again.');
      }
    }
  }

  /// Calculate traffic savings based on real-time data
  Future<int> _calculateTrafficSavings() async {
    try {
      final trafficData = await trafficService.collectTrafficData();

      final mobileReceived = trafficData['mobile']['received'] as int? ?? 0;
      final mobileTransmitted = trafficData['mobile']['transmitted'] as int? ?? 0;
      final wifiReceived = trafficData['wifi']['received'] as int? ?? 0;
      final wifiTransmitted = trafficData['wifi']['transmitted'] as int? ?? 0;

      final totalMobileTraffic = mobileReceived + mobileTransmitted;
      final totalWifiTraffic = wifiReceived + wifiTransmitted;

      final mobileSavings = (totalMobileTraffic * 0.10).toInt();
      final wifiSavings = (totalWifiTraffic * 0.05).toInt();

      return mobileSavings + wifiSavings;
    } catch (e) {
      logger.e("Error calculating traffic savings: $e");
      return 0;
    }
  }

  /// Format savings to MB/GB
  String _formatSavings(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Start periodic updates
  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        await _loadData();
      } catch (e) {
        logger.e("Error during periodic update: $e");
      }
    });
  }

  /// Show feedback using a SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Optimization App'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrafficSavingsCard(),
                    const SizedBox(height: 20),
                    _buildNavigationGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build card to display traffic savings
  Widget _buildTrafficSavingsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Savings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Savings: ${_formatSavings(trafficSavings)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Build grid for navigation buttons
  Widget _buildNavigationGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildNavigationButton('Cache Management', const CacheScreen()),
        _buildNavigationButton('Cloud Service', const CloudScreen()),
        _buildNavigationButton('Secure Storage', const SecureStorageScreen()),
        _buildNavigationButton('Traffic Management', const TrafficManagementScreen()),
        _buildNavigationButton('Settings', const settings.SettingsScreen()), // Use alias
        _buildNavigationButton('Compression Service', const CompressionScreen()),
      ],
    );
  }

  /// Build individual navigation button
  Widget _buildNavigationButton(String title, Widget screen) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Text(title, textAlign: TextAlign.center),
    );
  }
}
