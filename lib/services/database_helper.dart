import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Logger logger = Logger();

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'app_database.db');
      return await openDatabase(
        path,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      logger.e("Database initialization failed: $e");
      rethrow;
    }
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    logger.i("Creating database tables...");
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
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE traffic_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        received INTEGER NOT NULL,
        transmitted INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    logger.i("Database tables created successfully.");
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      logger.i("Upgrading database to version $newVersion...");
      await db.execute('''
        CREATE TABLE IF NOT EXISTS traffic_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          received INTEGER NOT NULL,
          transmitted INTEGER NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  // Insert data with conflict resolution
  Future<int> insertData(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      return await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      logger.e("Error inserting data into $table: $e");
      rethrow;
    }
  }

  // Fetch all data
  Future<List<Map<String, dynamic>>> getAllData(String table) async {
    try {
      final db = await database;
      return await db.query(table);
    } catch (e) {
      logger.e("Error fetching data from $table: $e");
      rethrow;
    }
  }

  // Fetch traffic data
  Future<List<Map<String, dynamic>>> getTrafficData() async {
    try {
      final data = await getAllData('traffic_data');
      if (data.isEmpty) {
        logger.w("No traffic data found.");
      }
      return data;
    } catch (e) {
      logger.e("Error fetching traffic data: $e");
      rethrow;
    }
  }

  // Fetch cache metadata
  Future<List<Map<String, dynamic>>> getCacheMetadata() async {
    try {
      final metadata = await getAllData('cache_metadata');
      if (metadata.isEmpty) {
        logger.w("No cache metadata found.");
      }
      return metadata;
    } catch (e) {
      logger.e("Error fetching cache metadata: $e");
      rethrow;
    }
  }

  // Clear all data in a table
  Future<int> deleteAllData(String table) async {
    try {
      final db = await database;
      return await db.delete(table);
    } catch (e) {
      logger.e("Error deleting data from $table: $e");
      rethrow;
    }
  }

  // Handle null fields in aggregation
  Future<Map<String, int>> getAggregatedTrafficData() async {
    try {
      final data = await getTrafficData();
      int totalReceived = 0;
      int totalTransmitted = 0;

      for (final entry in data) {
        totalReceived += (entry['received'] as int?) ?? 0;
        totalTransmitted += (entry['transmitted'] as int?) ?? 0;
      }

      return {
        'totalReceived': totalReceived,
        'totalTransmitted': totalTransmitted,
      };
    } catch (e) {
      logger.e("Error aggregating traffic data: $e");
      return {'totalReceived': 0, 'totalTransmitted': 0};
    }
  }
  // Insert cache metadata into the database
 Future<int> insertCacheMetadata(Map<String, dynamic> metadata) async {
  try {
    final db = await database;
    return await db.insert(
      'cache_metadata',
      metadata,
      conflictAlgorithm: ConflictAlgorithm.replace,  // Avoid duplicates by replacing existing data
    );
  } catch (e) {
    logger.e("Error inserting cache metadata: $e");
    rethrow;
  }
}
 // Insert test data for cache management screen
  Future<void> insertTestCacheData() async {
    try {
      // Creating some test cache data
      final testData = [
        {
          'url': 'https://www.google.com/url?sa=i&url=https%3A%2F%2Fcommons.wikimedia.org%2Fwiki%2FFile%3ALogo_nike_principal.jpg&psig=AOvVaw1VrgIoIqSnqZ_cQ_PYbTXj&ust=1733884297712000&source=images&cd=vfe&opi=89978449&ved=0CBQQjRxqFwoTCIDejb-UnIoDFQAAAAAdAAAAABAE',
          'path': '/path/to/file1.jpg',
          'size': 1024 * 1024, // 1 MB
          'creation_time': DateTime.now().toIso8601String(),
          'file_type': 'image/jpg',
        },
        {
          'url': 'https://tourism.gov.in/sites/default/files/2019-04/dummy-pdf_2.pdf',
          'path': '/path/to/file2.pdf',
          'size': 2048 * 1024, // 2 MB
          'creation_time': DateTime.now().toIso8601String(),
          'file_type': 'application/pdf',
        },
      ];

      // Inserting the test data into the 'cache_metadata' table
      for (var data in testData) {
        await insertData('cache_metadata', data);
      }

      logger.i("Test cache data inserted successfully.");
    } catch (e) {
      logger.e("Error inserting test cache data: $e");
    }
  }
}
