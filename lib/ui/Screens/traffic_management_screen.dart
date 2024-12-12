import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mobile_data_optimization_app/services/traffic_management_service.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts visualization

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  TrafficManagementScreenState createState() =>
      TrafficManagementScreenState();
}

class TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final TrafficManagementService trafficService = TrafficManagementService();
  final Logger logger = Logger();
  bool isLoading = true;
  List<Map<String, dynamic>> trafficData = [];
  Map<String, Map<String, int>> trafficBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadTrafficData();
  }

  Future<void> _loadTrafficData() async {
    setState(() => isLoading = true);
    try {
      final data = await trafficService.getTrafficData();
      final breakdown = await trafficService.getTrafficBreakdown();

      logger.d('Traffic Data: $data');
      logger.d('Traffic Breakdown: $breakdown');

      if (mounted) {
        setState(() {
          trafficData = data;
          trafficBreakdown = breakdown;
        });
      }
    } catch (e) {
      logger.e("Error loading traffic data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _clearTrafficData() async {
    try {
      await trafficService.clearTrafficData();
      await _loadTrafficData();
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

  /// Format bytes into MB/GB units
  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  Widget _buildTrafficBreakdownChart() {
    if (trafficBreakdown.isEmpty) {
      return const Text('No detailed traffic breakdown available.');
    }

    final flattenedData = <String, double>{};
    trafficBreakdown.forEach((category, data) {
      final totalBytes = (data['received'] ?? 0) + (data['transmitted'] ?? 0);
      flattenedData[category] = totalBytes / (1024 * 1024); // Convert to MB
    });

    final List<PieChartSectionData> pieSections = flattenedData.entries.map((entry) {
      final color = Colors.primaries[flattenedData.keys.toList().indexOf(entry.key) % Colors.primaries.length];
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)} MB',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: pieSections,
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(flattenedData),
      ],
    );
  }

  /// Build a custom legend for the pie chart
  Widget _buildLegend(Map<String, double> flattenedData) {
    final legendItems = flattenedData.entries.map((entry) {
      final color = Colors.primaries[flattenedData.keys.toList().indexOf(entry.key) % Colors.primaries.length];
      return Row(
        children: [
          Container(
            width: 16,
            height: 16,
            color: color,
            margin: const EdgeInsets.only(right: 8),
          ),
          Text(
            entry.key,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: legendItems,
    );
  }

  Widget _buildDataSummaryCard() {
    final totalReceived = trafficData.fold<int>(
      0,
      (sum, item) => sum + (item['received'] as int? ?? 0),
    );
    final totalTransmitted = trafficData.fold<int>(
      0,
      (sum, item) => sum + (item['transmitted'] as int? ?? 0),
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Total Received: ${_formatBytes(totalReceived)}'),
            Text('Total Transmitted: ${_formatBytes(totalTransmitted)}'),
            Text(
                'Total Data: ${_formatBytes(totalReceived + totalTransmitted)}'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _clearTrafficData,
        child: const Icon(Icons.delete),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trafficData.isEmpty
              ? const Center(child: Text('No traffic data available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataSummaryCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Traffic Breakdown by Category:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildTrafficBreakdownChart(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: trafficData.length,
                          itemBuilder: (context, index) {
                            final item = trafficData[index];
                            return ListTile(
                              title: Text('Traffic Data #${index + 1}'),
                              subtitle: Text(
                                'Category: ${item['category'] ?? "Unknown"}\n'
                                'Received: ${_formatBytes((item['received'] as num?)?.toInt() ?? 0)}\n'
                                'Transmitted: ${_formatBytes((item['transmitted'] as num?)?.toInt() ?? 0)}\n'
                                'Timestamp: ${item['timestamp'] ?? "Unknown"}',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
