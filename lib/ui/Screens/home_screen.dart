import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cache_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/cloud_screen.dart';
import 'package:mobile_data_optimization_app/ui/Screens/secure_storage_screen.dart';
// Import the CacheScreen
// Import the CloudScreen
// Import the SecureStorageScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});  // Added const for performance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Optimization App'),  // Use const for performance
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to CacheScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CacheScreen()),  // Make sure CacheScreen is correctly defined and imported
                );
              },
              child: const Text('Cache Management'),  // Use const for performance
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to CloudScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CloudScreen()),  // Make sure CloudScreen is correctly defined and imported
                );
              },
              child: const Text('Cloud Service'),  // Use const for performance
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to SecureStorageScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecureStorageScreen()),  // Make sure SecureStorageScreen is correctly defined and imported
                );
              },
              child: const Text('Secure Storage'),  // Use const for performance
            ),
          ],
        ),
      ),
    );
  }
}
