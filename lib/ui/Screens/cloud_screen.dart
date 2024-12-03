import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/cloud_service.dart';
import 'package:logger/logger.dart';

class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key}); // Added const for performance

  @override
  CloudScreenState createState() => CloudScreenState(); // Public type for the state class
}

class CloudScreenState extends State<CloudScreen> {
  final CloudService cloudService = CloudService(); // Adjusted constructor call
  final Logger logger = Logger(); // Logger for logging events

  bool isLoading = false; // Loading state indicator

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Service'), // Use const for static content
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _sendData(),
                    child: const Text('Send Data to Cloud'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _fetchData(),
                    child: const Text('Fetch Data from Cloud'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _updateData(),
                    child: const Text('Update Data in Cloud'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _deleteData(),
                    child: const Text('Delete Data from Cloud'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _fetchUsageStats(),
                    child: const Text('Fetch Cloud Usage Statistics'),
                  ),
                ],
              ),
            ),
    );
  }

  /// Send data to the cloud
  Future<void> _sendData() async {
    _setLoading(true);
    try {
      const data = 'Sample data for cloud processing';
      await cloudService.sendDataToCloud(data);
      _showSnackBar('Data sent to cloud successfully!');
    } catch (e) {
      logger.e('Failed to send data: $e');
      _showSnackBar('Failed to send data to cloud');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch data from the cloud
  Future<void> _fetchData() async {
    _setLoading(true);
    try {
      await cloudService.fetchDataFromCloud();
      _showSnackBar('Data fetched successfully from cloud!');
    } catch (e) {
      logger.e('Failed to fetch data: $e');
      _showSnackBar('Failed to fetch data from cloud');
    } finally {
      _setLoading(false);
    }
  }

  /// Update data in the cloud
  Future<void> _updateData() async {
    _setLoading(true);
    try {
      const id = '123'; // Replace with actual ID
      const updatedData = 'Updated data content';
      await cloudService.updateDataInCloud(id, updatedData);
      _showSnackBar('Data updated successfully in cloud!');
    } catch (e) {
      logger.e('Failed to update data: $e');
      _showSnackBar('Failed to update data in cloud');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete data from the cloud
  Future<void> _deleteData() async {
    _setLoading(true);
    try {
      const id = '123'; // Replace with actual ID
      await cloudService.deleteDataFromCloud(id);
      _showSnackBar('Data deleted successfully from cloud!');
    } catch (e) {
      logger.e('Failed to delete data: $e');
      _showSnackBar('Failed to delete data from cloud');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch cloud usage statistics
  Future<void> _fetchUsageStats() async {
    _setLoading(true);
    try {
      await cloudService.fetchUsageStatistics();
      _showSnackBar('Cloud usage statistics fetched successfully!');
    } catch (e) {
      logger.e('Failed to fetch usage statistics: $e');
      _showSnackBar('Failed to fetch usage statistics');
    } finally {
      _setLoading(false);
    }
  }

  /// Show a SnackBar with the given message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Set the loading state
  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
      });
    }
  }
}
