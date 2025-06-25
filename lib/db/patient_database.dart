import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patients.dart';

class PatientDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'patients.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            name TEXT,
            age TEXT,
            gender TEXT,
            condition TEXT,
            initialZ REAL,
            finalZ REAL,
            dropAngle REAL,
            dropTime REAL,
            motorVelocity REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE patients ADD COLUMN initialZ REAL');
          await db.execute('ALTER TABLE patients ADD COLUMN finalZ REAL');
          await db.execute('ALTER TABLE patients ADD COLUMN dropAngle REAL');
          await db.execute('ALTER TABLE patients ADD COLUMN dropTime REAL');
          await db.execute('ALTER TABLE patients ADD COLUMN motorVelocity REAL');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE patients ADD COLUMN name TEXT');
        }
      },
    );
  }

  static Future<void> insertPatient(Patient patient) async {
    final db = await database;
    await db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updatePatient(Patient patient) async {
    final db = await database;
    await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  static Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('patients');
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  static Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
