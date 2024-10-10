import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/secure_storage_service.dart';
import 'package:logger/logger.dart';

class SecureStorageScreen extends StatefulWidget {
  const SecureStorageScreen({super.key});  // Use const for constructor

  @override
  SecureStorageScreenState createState() => SecureStorageScreenState();  // Removed private type _SecureStorageScreenState
}

class SecureStorageScreenState extends State<SecureStorageScreen> {
  final SecureStorageService secureStorage = SecureStorageService();  // SecureStorageService is public
  final Logger logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Storage'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _saveData();  // Moved BuildContext-dependent code outside of async function
              },
              child: const Text('Save Data Securely'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _retrieveData();  // Moved BuildContext-dependent code outside of async function
              },
              child: const Text('Retrieve Secure Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteData();  // Moved BuildContext-dependent code outside of async function
              },
              child: const Text('Delete Secure Data'),
            ),
          ],
        ),
      ),
    );
  }

  // Async method to save data
  Future<void> _saveData() async {
    try {
      await secureStorage.writeSecureData('key', 'sample_value');
      logger.i('Data saved securely!');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data saved securely!')),
        );
      }
    } catch (e) {
      logger.e('Failed to save data: $e');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save data!')),
        );
      }
    }
  }

  // Async method to retrieve data
  Future<void> _retrieveData() async {
    try {
      String? value = await secureStorage.readSecureData('key');
      if (value != null) {
        logger.i('Retrieved data: $value');
        if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Retrieved data: $value')),
          );
        }
      } else {
        logger.w('No data found for the given key.');
        if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data found.')),
          );
        }
      }
    } catch (e) {
      logger.e('Failed to retrieve data: $e');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve data!')),
        );
      }
    }
  }

  // Async method to delete data
  Future<void> _deleteData() async {
    try {
      await secureStorage.deleteSecureData('key');
      logger.i('Secure data deleted successfully.');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Secure data deleted.')),
        );
      }
    } catch (e) {
      logger.e('Failed to delete secure data: $e');
      if (mounted) {  // Ensure widget is still mounted before accessing BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete data!')),
        );
      }
    }
  }
}
