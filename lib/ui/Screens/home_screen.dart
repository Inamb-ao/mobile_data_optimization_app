import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/secure_storage_service.dart';
import 'package:mobile_data_optimization_app/services/cloud_service.dart';  // Import cloud service
import 'package:logger/logger.dart';

class HomeScreen extends StatelessWidget {
  // Initialize SecureStorageService, CloudService, and Logger
  final SecureStorageService secureStorage = SecureStorageService();
  final CloudService cloudService = CloudService('https://an7ue2ngr9.execute-api.eu-north-1.amazonaws.com/dev');  // Use the correct cloud API URL
  final Logger logger = Logger();

  HomeScreen({super.key});  // Constructor without const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Optimization App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Save data securely to local storage
                await secureStorage.writeSecureData('key', 'value');
                logger.i('Data saved securely!');
              },
              child: const Text('Save Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Retrieve data from local storage
                String? value = await secureStorage.readSecureData('key');
                logger.i('Retrieved data: $value');
              },
              child: const Text('Retrieve Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Call the cloud service to send data for processing
                String data = 'Sample data for cloud processing';
                await cloudService.sendDataToCloud(data);
                logger.i('Data sent to cloud for processing');
              },
              child: const Text('Send Data to Cloud'),
            ),
          ],
        ),
      ),
    );
  }
}
