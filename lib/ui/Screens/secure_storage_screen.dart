import 'package:flutter/material.dart';
import 'package:mobile_data_optimization_app/services/secure_storage_service.dart';
import 'package:logger/logger.dart';

class SecureStorageScreen extends StatefulWidget {
  const SecureStorageScreen({super.key});

  @override
  SecureStorageScreenState createState() => SecureStorageScreenState();
}

class SecureStorageScreenState extends State<SecureStorageScreen> {
  final SecureStorageService secureStorage = SecureStorageService();
  final Logger logger = Logger();
  Map<String, String> storedItems = {};
  bool isLoading = true;
  bool encryptionEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStoredItems();
  }

  /// Load all stored items
  Future<void> _loadStoredItems() async {
    setState(() => isLoading = true);
    try {
      final items = await secureStorage.readAllSecureData();
      if (mounted) {
        setState(() {
          storedItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      logger.e("Failed to load stored items: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Add a new item
  Future<void> _addItem(String key, String value) async {
    try {
      await secureStorage.writeSecureData(key, value);
      _loadStoredItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
      }
    } catch (e) {
      logger.e("Failed to add item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item!')),
        );
      }
    }
  }

  /// Delete an item
  Future<void> _deleteItem(String key) async {
    try {
      await secureStorage.deleteSecureData(key);
      _loadStoredItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
      }
    } catch (e) {
      logger.e("Failed to delete item: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item!')),
        );
      }
    }
  }

  /// Toggle encryption setting
  void _toggleEncryption() {
    setState(() {
      encryptionEnabled = !encryptionEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          encryptionEnabled ? 'Encryption enabled.' : 'Encryption disabled.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Storage'),
        actions: [
          IconButton(
            icon: Icon(
              encryptionEnabled ? Icons.lock : Icons.lock_open,
            ),
            onPressed: _toggleEncryption,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : storedItems.isEmpty
              ? const Center(child: Text('No items found.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: storedItems.length,
                        itemBuilder: (context, index) {
                          final key = storedItems.keys.elementAt(index);
                          final value = storedItems[key]!;
                          return Card(
                            child: ListTile(
                              title: Text(key),
                              subtitle: Text(value),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteItem(key),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showAddItemDialog(),
                      child: const Text('Add Item'),
                    ),
                  ],
                ),
    );
  }

  /// Show a dialog to add a new item
  void _showAddItemDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'Key'),
              ),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(labelText: 'Value'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final key = keyController.text;
                final value = valueController.text;
                if (key.isNotEmpty && value.isNotEmpty) {
                  _addItem(key, value);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
