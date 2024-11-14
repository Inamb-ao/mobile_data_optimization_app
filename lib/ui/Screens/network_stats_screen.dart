import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/network_stats_service.dart';

class NetworkStatsScreen extends StatefulWidget {
  const NetworkStatsScreen({super.key});

  @override
  NetworkStatsScreenState createState() => NetworkStatsScreenState(); // Made the state class public
}

class NetworkStatsScreenState extends State<NetworkStatsScreen> {
  final NetworkStatsService _networkStatsService = NetworkStatsService();
  int _networkUsage = 0;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchNetworkStats();
  }

  Future<void> _fetchNetworkStats() async {
    try {
      final int usage = await _networkStatsService.getNetworkStats();
      if (usage != -1) {
        setState(() {
          _networkUsage = usage;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to fetch network stats.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Statistics'),
      ),
      body: Center(
        child: _errorMessage.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Network Usage:',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_networkUsage bytes',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchNetworkStats,
        tooltip: 'Refresh Network Stats',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
