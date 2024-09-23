import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';  // Import the logger package

class CloudService {
  // Initialize logger
  final Logger logger = Logger();

  // Constructor
  CloudService(String s);

  // Send data to the cloud (e.g., AWS Lambda)
  Future<void> sendDataToCloud(String data) async {
    // Use the provided API Gateway URL
    final url = Uri.parse('https://an7ue2ngr9.execute-api.eu-north-1.amazonaws.com/dev/process');
    
    try {
      // Send a POST request with JSON-encoded data
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': data}),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        logger.i('Data sent to cloud successfully');
      } else {
        logger.e('Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      // Catch and log any errors during the request
      logger.e('Error sending data to the cloud: $e');
    }
  }
}
