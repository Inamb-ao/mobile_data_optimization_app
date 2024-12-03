import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts visualization

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  TrafficManagementScreenState createState() => TrafficManagementScreenState();
}

class TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final TrafficManagementService trafficService = TrafficManagementService(); // Service instance
  final Logger logger = Logger(); // Logger for debugging
  bool isLoading = true; // Loading state indicator
  List<Map<String, dynamic>> trafficData = []; // List to store traffic data
  Map<String, Map<String, int>> trafficBreakdown = {}; // Breakdown by app/network type

  @override
  void initState() {
    super.initState();
    _loadTrafficData(); // Load traffic data when the screen initializes
  }

  /// Load traffic data and calculate breakdown
  Future<void> _loadTrafficData() async {
    setState(() => isLoading = true); // Set loading state
    try {
      final data = await trafficService.getTrafficData(); // Fetch data from service
      final breakdown = await trafficService.getTrafficBreakdown(); // Fetch breakdown

      if (mounted) {
        setState(() {
          trafficData = data; // Update state with fetched data
          trafficBreakdown = breakdown; // Update breakdown data
        });
      }
    } catch (e) {
      logger.e("Error loading traffic data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false); // Reset loading state
    }
  }

  /// Clear all traffic data
  Future<void> _clearTrafficData() async {
    try {
      await trafficService.clearTrafficData(); // Clear data via service
      _loadTrafficData(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Traffic data cleared successfully.')),
        );
      }
    } catch (e) {
      logger.e("Error clearing traffic data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }

  /// Build chart for traffic breakdown
  Widget _buildTrafficBreakdownChart() {
    if (trafficBreakdown.isEmpty) {
      return const Text('No detailed traffic breakdown available.');
    }

    final flattenedData = <String, int>{};
    trafficBreakdown.forEach((category, data) {
      flattenedData[category] = data.values.reduce((a, b) => a + b);
    });

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final keys = flattenedData.keys.toList();
                  if (value.toInt() < keys.length) {
                    return Text(keys[value.toInt()]);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          barGroups: flattenedData.entries.map((entry) {
            final index = flattenedData.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [BarChartRodData(toY: entry.value.toDouble())],
            );
          }).toList(),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : trafficData.isEmpty
              ? const Center(child: Text('No traffic data available.')) // Show empty state
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: trafficData.length,
                          itemBuilder: (context, index) {
                            final item = trafficData[index]; // Access traffic data item
                            return ListTile(
                              title: Text('Traffic Data #${index + 1}'),
                              subtitle: Text(
                                'Value: ${(item['value'] as num?)?.toInt() ?? 0} bytes\n'
                                'Timestamp: ${item['timestamp'] ?? "Unknown"}',
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Traffic Breakdown by App/Network Type:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildTrafficBreakdownChart(), // Display breakdown chart
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _clearTrafficData, // Clear traffic data
                        child: const Text('Clear Traffic Data'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
