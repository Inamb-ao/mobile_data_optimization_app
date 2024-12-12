import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  Map<String, String> settings = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load settings from the database
  Future<void> _loadSettings() async {
    setState(() => isLoading = true);
    try {
      final data = await dbHelper.getAllData('settings');
      final loadedSettings = {
        for (var row in data)
          (row['name'] as String): (row['value'] as String)
      };
      if (mounted) {
        setState(() {
          settings = loadedSettings;
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading settings: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Update or insert a setting in the database
  Future<void> _updateSetting(String key, String value) async {
    try {
      await dbHelper.insertData('settings', {'name': key, 'value': value});
      setState(() {
        settings[key] = value;
      });
      _showSnackBar('$key updated successfully.');
    } catch (e) {
      _showSnackBar('Error updating $key: $e');
    }
  }

  /// Toggle compression setting
  void _toggleCompression() {
    final isEnabled = settings['CompressionEnabled'] == 'true';
    _updateSetting('CompressionEnabled', (!isEnabled).toString());
  }

  /// Toggle dark mode setting
  void _toggleDarkMode() {
    final isEnabled = settings['DarkMode'] == 'true';
    _updateSetting('DarkMode', (!isEnabled).toString());
  }

  /// Display feedback to the user
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                SwitchListTile(
                  title: const Text('Enable Compression'),
                  value: settings['CompressionEnabled'] == 'true',
                  onChanged: (_) => _toggleCompression(),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Enable Dark Mode'),
                  value: settings['DarkMode'] == 'true',
                  onChanged: (_) => _toggleDarkMode(),
                ),
                const Divider(),
                const Text(
                  'Additional Settings:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...settings.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                  );
                }),
              ],
            ),
    );
  }
}
