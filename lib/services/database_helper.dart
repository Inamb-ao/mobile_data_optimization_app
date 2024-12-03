import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Private constructor for Singleton pattern
  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  // Method to get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;

    // If _database is null, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the SQLite database
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    // Main table
    await db.execute('''
      CREATE TABLE my_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value INTEGER,
        timestamp TEXT
      )
    ''');

    // Cache metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT UNIQUE NOT NULL,
        path TEXT NOT NULL,
        size INTEGER NOT NULL,
        creation_time TEXT,
        file_type TEXT
      )
    ''');
  }

  // Insert data into a table with conflict resolution (replace)
  Future<int> insertData(String table, Map<String, dynamic> data) async {
    try {
      Database db = await database;
      return await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception("Failed to insert data into $table: $e");
    }
  }

  // Retrieve all data from a specific table
  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    try {
      Database db = await database;
      return await db.query(table);
    } catch (e) {
      throw Exception("Failed to fetch data from $table: $e");
    }
  }

  // Retrieve data by a specific 'name' from a table
  Future<List<Map<String, dynamic>>> getDataByName(
    String table,
    String columnName,
    String value,
  ) async {
    try {
      Database db = await database;
      return await db.query(
        table,
        where: '$columnName = ?',
        whereArgs: [value],
      );
    } catch (e) {
      throw Exception("Failed to fetch data from $table by $columnName: $e");
    }
  }

  // Delete all data from a specific table
  Future<int> deleteAllData(String table) async {
    try {
      Database db = await database;
      return await db.delete(table);
    } catch (e) {
      throw Exception("Failed to delete all data from $table: $e");
    }
  }

  // Calculate total cache size
  Future<int> calculateCacheSize() async {
    try {
      List<Map<String, dynamic>> cacheData = await getAllData('cache_metadata');
      int totalSize = cacheData.fold<int>(
        0,
        (sum, entry) => sum + ((entry['size'] as num?)?.toInt() ?? 0),
      );

      return totalSize;
    } catch (e) {
      throw Exception("Failed to calculate cache size: $e");
    }
  }

  // Insert cache metadata
  Future<int> insertCacheMetadata(Map<String, dynamic> metadata) async {
    return await insertData('cache_metadata', metadata);
  }

  // Retrieve cache metadata
  Future<List<Map<String, dynamic>>> getCacheMetadata() async {
    return await getAllData('cache_metadata');
  }

  // Delete specific cache metadata by URL
  Future<int> deleteCacheMetadata(String url) async {
    try {
      Database db = await database;
      return await db.delete(
        'cache_metadata',
        where: 'url = ?',
        whereArgs: [url],
      );
    } catch (e) {
      throw Exception("Failed to delete cache metadata for $url: $e");
    }
  }

  // Delete cached files by file type
  Future<int> deleteByFileType(String fileType) async {
    try {
      Database db = await database;
      return await db.delete(
        'cache_metadata',
        where: 'file_type = ?',
        whereArgs: [fileType],
      );
    } catch (e) {
      throw Exception("Failed to delete cache metadata by file type: $e");
    }
  }

  // Delete large cached files (greater than a specified size)
  Future<int> deleteLargeFiles(int sizeThreshold) async {
    try {
      Database db = await database;
      return await db.delete(
        'cache_metadata',
        where: 'size > ?',
        whereArgs: [sizeThreshold],
      );
    } catch (e) {
      throw Exception("Failed to delete large files: $e");
    }
  }

  // Utility to fetch metadata by URL
  Future<Map<String, dynamic>?> getMetadataByUrl(String url) async {
    List<Map<String, dynamic>> result = await getDataByName(
      'cache_metadata',
      'url',
      url,
    );
    return result.isNotEmpty ? result.first : null;
  }
}
