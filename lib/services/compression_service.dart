import 'package:archive/archive.dart';

class CompressionService {
  // Function to compress data
  List<int> compressData(List<int> data) {
    const encoder = ZLibEncoder();
    return encoder.encode(data);
  }

  // Function to decompress data
  List<int> decompressData(List<int> compressedData) {
    const decoder = ZLibDecoder();
    return decoder.decodeBytes(compressedData);
  }
}
