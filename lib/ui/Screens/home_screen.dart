import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cache_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cloud_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/compression_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/secure_storage_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/settings_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/traffic_management_screen.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TrafficManagementService trafficService = TrafficManagementService();
  final Logger logger = Logger();

  int trafficSavings = 0; // Traffic savings in bytes
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
      }
    }
  }

  Future<int> _calculateTrafficSavings() async {
    try {
      final trafficData = await trafficService.collectTrafficData();

      final mobileReceived = trafficData['mobile']['received'] as int;
      final mobileTransmitted = trafficData['mobile']['transmitted'] as int;
      final wifiReceived = trafficData['wifi']['received'] as int;
      final wifiTransmitted = trafficData['wifi']['transmitted'] as int;

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

  String _formatSavings(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
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

  Widget _buildNavigationGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildNavigationButton(
          'Cache Management',
          const CacheScreen(),
        ),
        _buildNavigationButton(
          'Cloud Service',
          const CloudScreen(),
        ),
        _buildNavigationButton(
          'Secure Storage',
          const SecureStorageScreen(),
        ),
        _buildNavigationButton(
          'Traffic Management',
          const TrafficManagementScreen(),
        ),
        _buildNavigationButton(
          'Settings',
          const SettingsScreen(),
        ),
        _buildNavigationButton(
          'Compression Service',
          const CompressionScreen(),
        ),
      ],
    );
  }

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
