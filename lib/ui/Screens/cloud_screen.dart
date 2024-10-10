import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/cloud_service.dart';
import 'package:logger/logger.dart';

class CloudScreen extends StatefulWidget {
  const CloudScreen({super.key});  // Added const for performance

  @override
  CloudScreenState createState() => CloudScreenState();  // Public type for the state class
}

class CloudScreenState extends State<CloudScreen> {
  final CloudService cloudService = CloudService('https://an7ue2ngr9.execute-api.eu-north-1.amazonaws.com/dev');  // Replace with actual cloud service URL
  final Logger logger = Logger();  // Logger for logging events

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Service'),  // Use const for static content
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _sendData();  // Handle async logic outside the onPressed callback
              },
              child: const Text('Send Data to Cloud'),  // Use const for static content
            ),
          ],
        ),
      ),
    );
  }

  // Async method to send data to the cloud
  Future<void> _sendData() async {
    try {
      const data = 'Sample data for cloud processing';
      await cloudService.sendDataToCloud(data);
      logger.i('Data sent to cloud for processing');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sent to cloud for processing')),
        );
      }
    } catch (e) {
      logger.e('Failed to send data to the cloud: $e');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send data to the cloud')),
        );
      }
    }
  }
}
