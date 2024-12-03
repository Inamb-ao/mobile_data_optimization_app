import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_data_optimization_app/services/compression_service.dart';

class CompressionScreen extends StatefulWidget {
  const CompressionScreen({super.key});

  @override
  CompressionScreenState createState() => CompressionScreenState();
}

class CompressionScreenState extends State<CompressionScreen> {
  final CompressionService compressionService = CompressionService();
  File? selectedFile; // Stores the selected file
  int? originalSize; // Original file size in bytes
  int? compressedSize; // Compressed file size in bytes
  Map<String, dynamic>? compressionStats; // Compression statistics
  bool isProcessing = false; // Tracks processing state (compressing/decompressing)

  /// Pick a file using File Picker
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        selectedFile = file;
        originalSize = file.lengthSync();
        compressedSize = null; // Reset compressed size
        compressionStats = null; // Reset compression stats
      });
    }
  }

  /// Compress the selected file
  Future<void> _compressFile() async {
    if (selectedFile == null) return;

    setState(() => isProcessing = true);
    try {
      final fileBytes = Uint8List.fromList(selectedFile!.readAsBytesSync());
      final compressedBytes = Uint8List.fromList(compressionService.compressData(fileBytes));

      setState(() {
        compressedSize = compressedBytes.length;
        compressionStats = compressionService.getCompressionStatistics(
          fileBytes,
          compressedBytes,
        );
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File compressed successfully!')),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error compressing file: $e')),
      );
    }
  }

  /// Decompress the selected file
  Future<void> _decompressFile() async {
    if (selectedFile == null) return;

    setState(() => isProcessing = true);
    try {
      final fileBytes = Uint8List.fromList(selectedFile!.readAsBytesSync());
      final decompressedBytes = Uint8List.fromList(compressionService.decompressData(fileBytes));

      setState(() {
        compressedSize = decompressedBytes.length;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File decompressed successfully!')),
      );
    } catch (e) {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error decompressing file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compression Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 20),
            if (selectedFile != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected File: ${selectedFile!.path}'),
                  Text('Original Size: ${(originalSize ?? 0) / 1024} KB'),
                  if (compressedSize != null)
                    Text('Compressed Size: ${(compressedSize ?? 0) / 1024} KB'),
                  if (compressionStats != null) ...[
                    Text(
                      'Savings: ${(compressionStats!['savings'] as int) / 1024} KB',
                    ),
                    Text(
                      'Savings Percentage: ${compressionStats!['savingsPercentage']}%',
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (isProcessing)
                    const Center(child: CircularProgressIndicator()),
                  if (!isProcessing)
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _compressFile,
                          child: const Text('Compress File'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _decompressFile,
                          child: const Text('Decompress File'),
                        ),
                      ],
                    ),
                ],
              ),
            if (selectedFile == null)
              const Text('No file selected.', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
