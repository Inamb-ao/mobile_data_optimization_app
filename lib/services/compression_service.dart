import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class CompressionService {
  // Supported Compression Types
  static const String zlib = 'zlib';
  static const String gzip = 'gzip';

  /// Compress data using the specified algorithm
  List<int> compressData(List<int> data, {String algorithm = zlib}) {
    try {
      List<int> compressedData;
      switch (algorithm) {
        case gzip:
          compressedData = GZipEncoder().encode(data)!;
          break;
        case zlib:
        default:
          compressedData = const ZLibEncoder().encode(data);
          break;
      }

      return compressedData;
    } catch (e) {
      throw Exception('Compression failed: $e');
    }
  }

  /// Decompress data using the specified algorithm
  List<int> decompressData(List<int> compressedData, {String algorithm = zlib}) {
    try {
      List<int> decompressedData;
      switch (algorithm) {
        case gzip:
          decompressedData = GZipDecoder().decodeBytes(compressedData);
          break;
        case zlib:
        default:
          decompressedData = const ZLibDecoder().decodeBytes(compressedData);
          break;
      }

      return decompressedData;
    } catch (e) {
      throw Exception('Decompression failed: $e');
    }
  }

  /// Compress a file
  Future<File> compressFile(File file, {String algorithm = zlib}) async {
    try {
      final fileBytes = await file.readAsBytes();
      final compressedBytes = compressData(fileBytes, algorithm: algorithm);

      final compressedFilePath = '${file.path}.compressed';
      final compressedFile = File(compressedFilePath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      throw Exception('File compression failed: $e');
    }
  }

  /// Decompress a file
  Future<File> decompressFile(File file, {String algorithm = zlib}) async {
    try {
      final compressedBytes = await file.readAsBytes();
      final decompressedBytes = decompressData(compressedBytes, algorithm: algorithm);

      final decompressedFilePath = file.path.replaceFirst('.compressed', '');
      final decompressedFile = File(decompressedFilePath);
      await decompressedFile.writeAsBytes(decompressedBytes);

      return decompressedFile;
    } catch (e) {
      throw Exception('File decompression failed: $e');
    }
  }

  /// Get compression statistics for in-memory data
  Map<String, dynamic> getCompressionStatistics(Uint8List originalData, Uint8List compressedData) {
    final originalSize = originalData.lengthInBytes;
    final compressedSize = compressedData.lengthInBytes;
    final savings = originalSize - compressedSize;
    final savingsPercentage = originalSize > 0 ? (savings / originalSize) * 100 : 0;

    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'savings': savings,
      'savingsPercentage': savingsPercentage.toStringAsFixed(2),
    };
  }

  /// Get compression statistics for files
  Future<Map<String, dynamic>> getFileCompressionStatistics(File originalFile, File compressedFile) async {
    try {
      final originalSize = await originalFile.length();
      final compressedSize = await compressedFile.length();
      final savings = originalSize - compressedSize;
      final savingsPercentage = originalSize > 0 ? (savings / originalSize) * 100 : 0;

      return {
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'savings': savings,
        'savingsPercentage': savingsPercentage.toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to calculate file compression statistics: $e');
    }
  }
}
