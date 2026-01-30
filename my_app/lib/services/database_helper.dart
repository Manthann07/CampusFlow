import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'campusflow.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Appointments Table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appointmentId TEXT,
        studentId TEXT,
        studentName TEXT,
        facultyId TEXT,
        facultyName TEXT,
        subject TEXT,
        date TEXT,
        time TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');

    // Optional: Local copy of users for offline testing
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        role TEXT,
        department TEXT
      )
    ''');
    // Seed initial data for demo
    await db.insert('users', {
      'uid': 'f1',
      'name': 'Dr. Sagar Patel',
      'email': 'sagarpatel@gmail.com',
      'role': 'Faculty',
      'department': 'Computer Engineering'
    });
  }

  // Helper methods for Appointments
  Future<int> insertAppointment(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('appointments', row);
  }

  Future<List<Map<String, dynamic>>> queryAllAppointments(String studentId, String facultyId, String role) async {
    Database db = await database;
    if (role == 'Faculty') {
      return await db.query('appointments', where: 'facultyId = ?', whereArgs: [facultyId], orderBy: 'id DESC');
    } else {
      return await db.query('appointments', where: 'studentId = ?', whereArgs: [studentId], orderBy: 'id DESC');
    }
  }

  Future<int> updateAppointment(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('appointments', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAppointment(int id) async {
    Database db = await database;
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  // User helpers
  Future<void> saveUserLocally(Map<String, dynamic> user) async {
    Database db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getLocalFaculty() async {
    Database db = await database;
    return await db.query('users', where: 'role = ?', whereArgs: ['Faculty']);
  }
}
