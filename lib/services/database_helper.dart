import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';  // Helps manipulate file paths

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
    String path = join(documentsDirectory.path, 'my_database.db');
    
    return await openDatabase(
      path,
      version: 1,  // Set the database version
      onCreate: _onCreate,
    );
  }

  // Create the tables when the database is first created
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE my_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        value INTEGER
      )
    ''');
  }

  // Function to insert data into the database, with conflict resolution (replace)
  Future<int> insertData(Map<String, dynamic> data) async {
    Database db = await database;
    return await db.insert(
      'my_table', 
      data, 
      conflictAlgorithm: ConflictAlgorithm.replace  // Replace if the record already exists
    );
  }

  // Retrieve all data from the database
  Future<List<Map<String, dynamic>>> getAllData() async {
    Database db = await database;
    return await db.query('my_table');
  }

  // Retrieve data by a specific 'name'
  Future<List<Map<String, dynamic>>> getDataByName(String name) async {
    Database db = await database;
    return await db.query(
      'my_table',
      where: 'name = ?',  // Use where clause to filter by 'name'
      whereArgs: [name],  // Pass the 'name' as an argument
    );
  }

  // Delete all data from the database (optional utility)
  Future<int> deleteAllData() async {
    Database db = await database;
    return await db.delete('my_table');
  }
}
