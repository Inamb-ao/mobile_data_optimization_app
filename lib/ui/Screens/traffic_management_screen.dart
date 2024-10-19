import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:logger/logger.dart';

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  TrafficManagementScreenState createState() => TrafficManagementScreenState();
}

class TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final TrafficManagementService trafficService = TrafficManagementService();
  final Logger logger = Logger();

  int totalTraffic = 0;  // To display total traffic
  bool isLoading = false;  // To track loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Management'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()  // Show a loading spinner if traffic data is being collected
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Total Traffic: $totalTraffic MB', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _collectTrafficData();
                    },
                    child: const Text('Collect Traffic Data'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _retrieveTrafficData();
                    },
                    child: const Text('Retrieve Traffic Data'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _clearTrafficData();
                    },
                    child: const Text('Clear Traffic Data'),
                  ),
                ],
              ),
      ),
    );
  }

  // Method to collect traffic data and save it to the database
  Future<void> _collectTrafficData() async {
    setState(() {
      isLoading = true;
    });

    await trafficService.collectTrafficData();
    logger.i('Traffic data collected and saved.');

    setState(() {
      isLoading = false;
    });

    _showSnackBar('Traffic data collected successfully.');
  }

  // Method to retrieve traffic data from the database
  Future<void> _retrieveTrafficData() async {
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> data = await trafficService.getTrafficData();
    if (data.isNotEmpty) {
      setState(() {
        totalTraffic = data.first['value'];  // Display the retrieved traffic data
      });
      logger.i('Traffic data retrieved: $totalTraffic MB');
    } else {
      _showSnackBar('No traffic data found.');
    }

    setState(() {
      isLoading = false;
    });
  }

  // Method to clear all traffic data
  Future<void> _clearTrafficData() async {
    await trafficService.clearTrafficData();
    setState(() {
      totalTraffic = 0;  // Reset the displayed traffic data
    });
    logger.i('Traffic data cleared.');
    _showSnackBar('Traffic data cleared.');
  }

  // Helper method to show SnackBars for feedback
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
