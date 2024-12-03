import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class CloudService {
  // Logger for debugging and status tracking
  final Logger logger = Logger();

  // Base API endpoint
  final String baseUrl = 'https://an7ue2ngr9.execute-api.eu-north-1.amazonaws.com/dev';

  /// Send data to the cloud (POST)
  Future<void> sendDataToCloud(String data) async {
    final url = Uri.parse('$baseUrl/process');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': data}),
      );

      if (response.statusCode == 200) {
        logger.i('Data sent to cloud successfully: ${response.body}');
      } else {
        logger.e('Failed to send data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error sending data to the cloud: $e');
    }
  }

  /// Fetch data from the cloud (GET)
  Future<void> fetchDataFromCloud() async {
    final url = Uri.parse('$baseUrl/fetch');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.i('Data fetched successfully: $data');
      } else {
        logger.e('Failed to fetch data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching data from the cloud: $e');
    }
  }

  /// Update data in the cloud (PUT)
  Future<void> updateDataInCloud(String id, String updatedData) async {
    final url = Uri.parse('$baseUrl/update/$id');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': updatedData}),
      );

      if (response.statusCode == 200) {
        logger.i('Data updated successfully: ${response.body}');
      } else {
        logger.e('Failed to update data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error updating data in the cloud: $e');
    }
  }

  /// Delete data from the cloud (DELETE)
  Future<void> deleteDataFromCloud(String id) async {
    final url = Uri.parse('$baseUrl/delete/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        logger.i('Data deleted successfully');
      } else {
        logger.e('Failed to delete data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error deleting data from the cloud: $e');
    }
  }

  /// Retry logic for failed operations
  Future<void> retryOperation(Future<void> Function() operation, {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        await operation();
        return; // Exit if successful
      } catch (e) {
        attempt++;
        logger.w('Retry attempt $attempt failed: $e');
        if (attempt >= retries) {
          logger.e('All retry attempts failed.');
        }
      }
    }
  }

  /// Encrypt data before sending (basic example)
  String encryptData(String data) {
    return base64Encode(utf8.encode(data)); // Simple Base64 encryption
  }

  /// Decrypt data after receiving (basic example)
  String decryptData(String encryptedData) {
    return utf8.decode(base64Decode(encryptedData));
  }

  /// Fetch usage statistics (mock example)
  Future<void> fetchUsageStatistics() async {
    final url = Uri.parse('$baseUrl/usage-stats');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final stats = jsonDecode(response.body);
        logger.i('Usage statistics: $stats');
      } else {
        logger.e('Failed to fetch usage stats: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching usage statistics: $e');
    }
  }
}
