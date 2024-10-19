import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';  // Import the database helper

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});  // Use super key parameter

  @override
  SettingsScreenState createState() => SettingsScreenState();  // Create the state class
}

class SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();  // Initialize the database helper

  bool isCompressionEnabled = false;  // Default setting

  @override
  void initState() {
    super.initState();
    _loadCompressionSetting();  // Load setting from database when the screen is initialized
  }

  // Method to load the compression setting from the database
  void _loadCompressionSetting() async {
    List<Map<String, dynamic>> result = await dbHelper.getDataByName('CompressionEnabled');
    if (result.isNotEmpty) {
      setState(() {
        isCompressionEnabled = result.first['value'] == 1;  // Convert 1/0 to true/false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Data Compression'),
            value: isCompressionEnabled,
            onChanged: (bool value) async {
              setState(() {
                isCompressionEnabled = value;
              });
              // Save the new setting to the database
              await dbHelper.insertData({
                'name': 'CompressionEnabled',
                'value': value ? 1 : 0,  // Save as 1 for true, 0 for false
              });
              _showSnackBar('Compression setting saved');
            },
          ),
        ],
      ),
    );
  }

  // Method to show feedback with a SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
