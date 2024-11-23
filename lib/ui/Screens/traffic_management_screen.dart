import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:logger/logger.dart';
import 'package:fl_chart/fl_chart.dart'; // For chart visualization
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  TrafficManagementScreenState createState() => TrafficManagementScreenState();
}

class TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final TrafficManagementService trafficService = TrafficManagementService(); // Service to manage traffic data
  final Logger logger = Logger(); // Logger for logging events

  List<Map<String, dynamic>> trafficData = []; // Store traffic data
  bool isLoading = false; // Track loading state
  bool hasData = false; // Track if traffic data exists
  double totalTrafficMB = 0; // Total traffic in MB for display
  double maxTraffic = 0; // Maximum traffic for stats
  double minTraffic = double.infinity; // Minimum traffic for stats
  double avgTraffic = 0; // Average traffic for stats
  bool isMonitoring = false; // Toggle for real-time monitoring
  Timer? monitoringTimer; // Timer for periodic updates

  @override
  void initState() {
    super.initState();
    _loadTrafficData(); // Load traffic data on screen initialization
  }

  @override
  void dispose() {
    monitoringTimer?.cancel(); // Cancel monitoring when screen is disposed
    super.dispose();
  }

  // Helper to format data in MB or GB dynamically
  String formatTraffic(double bytes) {
    if (bytes > 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} GB';
    } else {
      return '${bytes.toStringAsFixed(2)} MB';
    }
  }

  // Load traffic data from the database
  Future<void> _loadTrafficData() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data = await trafficService.getTrafficData();
      if (data.isNotEmpty) {
        double total = 0;
        double max = 0;
        double min = double.infinity;

        for (var entry in data) {
          double valueInMB = entry['value'] / 1e6; // Convert to MB
          total += valueInMB;
          if (valueInMB > max) max = valueInMB;
          if (valueInMB < min) min = valueInMB;
        }

        setState(() {
          trafficData = data;
          totalTrafficMB = total;
          maxTraffic = max;
          minTraffic = min;
          avgTraffic = total / data.length;
          hasData = true;
        });
        logger.i('Traffic data loaded successfully.');
      } else {
        setState(() {
          hasData = false;
        });
        logger.w('No traffic data found.');
      }
    } catch (e) {
      logger.e('Failed to load traffic data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Collect traffic data periodically
  void _startLiveMonitoring() {
    monitoringTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _collectTrafficData();
    });
  }

  void _stopLiveMonitoring() {
    monitoringTimer?.cancel();
    logger.i('Live monitoring stopped.');
  }

  // Collect traffic data and save to the database
  Future<void> _collectTrafficData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await trafficService.collectTrafficData();
      logger.i('Traffic data collected.');
      _showSnackBar('Traffic data collected successfully.');
      _loadTrafficData(); // Reload traffic data after collection
      _checkTrafficThreshold(); // Check for traffic threshold
    } catch (e) {
      logger.e('Error collecting traffic data: $e');
      _showSnackBar('Failed to collect traffic data.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Check for traffic threshold
  void _checkTrafficThreshold() {
    if (totalTrafficMB > 5120) { // 5 GB threshold
      _showSnackBar('Alert: Traffic usage exceeded 5 GB!');
    }
  }

  // Export traffic data as CSV
  Future<void> _exportDataToCSV() async {
    if (trafficData.isEmpty) {
      _showSnackBar('No data to export.');
      return;
    }

    List<List<dynamic>> rows = [
      ['Date', 'Traffic (MB)'], // Header row
      ...trafficData.map((entry) => [
            entry['date'] ?? 'Unknown Date', // Replace with your date field
            (entry['value'] / 1e6).toStringAsFixed(2),
          ]),
    ];

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/traffic_data.csv';

    final file = File(path);
    await file.writeAsString(csvData);

    _showSnackBar('Data exported to $path');
    logger.i('Data exported to $path');
  }

  // Clear all traffic data
  Future<void> _clearTrafficData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await trafficService.clearTrafficData();
      setState(() {
        trafficData = [];
        totalTrafficMB = 0;
        maxTraffic = 0;
        minTraffic = double.infinity;
        avgTraffic = 0;
        hasData = false;
      });
      logger.i('Traffic data cleared.');
      _showSnackBar('Traffic data cleared.');
    } catch (e) {
      logger.e('Error clearing traffic data: $e');
      _showSnackBar('Failed to clear traffic data.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper to show SnackBars
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Build the traffic data chart
  Widget _buildLineChart() {
    if (trafficData.isEmpty) {
      return const Text('No traffic data available for visualization.');
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) =>
                    Text('${value.toInt()} MB'),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < trafficData.length) {
                    return Text('Day ${index + 1}');
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: trafficData
                  .asMap()
                  .entries
                  .map(
                    (entry) => FlSpot(
                      entry.key.toDouble(),
                      (entry.value['value'] / 1e6),
                    ),
                  )
                  .toList(),
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.green],
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.greenAccent],
                ),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Management'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasData)
                      Text(
                        'Total Traffic: ${formatTraffic(totalTrafficMB)}',
                        style: const TextStyle(fontSize: 20),
                      )
                    else
                      const Text(
                        'No traffic data available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _collectTrafficData,
                      child: const Text('Collect Traffic Data'),
                    ),
                    ElevatedButton(
                      onPressed: _clearTrafficData,
                      child: const Text('Clear Traffic Data'),
                    ),
                    ElevatedButton(
                      onPressed: _exportDataToCSV,
                      child: const Text('Export Data'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isMonitoring = !isMonitoring;
                        });
                        if (isMonitoring) {
                          _startLiveMonitoring();
                        } else {
                          _stopLiveMonitoring();
                        }
                      },
                      child: Text(isMonitoring ? 'Stop Monitoring' : 'Start Monitoring'),
                    ),
                    const SizedBox(height: 20),
                    _buildLineChart(),
                  ],
                ),
              ),
      ),
    );
  }
}
