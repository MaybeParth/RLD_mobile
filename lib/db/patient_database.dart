import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/patients.dart';

class PatientDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = p.join(await getDatabasesPath(), 'patients.db');
    return await openDatabase(
      path,
      version: 6, // ⬅️ bump to add trials and new fields
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
            motorVelocity REAL,
            trials TEXT,
            currentTrialNumber INTEGER,
            calZeroOffsetDeg REAL,
            calRefX REAL, calRefY REAL, calRefZ REAL,
            calUX REAL, calUY REAL, calUZ REAL,
            calVX REAL, calVY REAL, calVZ REAL,
            calibratedAtIso TEXT,
            dropsSinceCal INTEGER,
            customBaselineAngle REAL,
            createdAt TEXT,
            lastModified TEXT
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
          try { await db.execute('ALTER TABLE patients ADD COLUMN name TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE patients ADD COLUMN createdAt TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE patients ADD COLUMN lastModified TEXT'); } catch (_) {}
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE patients ADD COLUMN calZeroOffsetDeg REAL'); } catch (_) {}
          for (final col in [
            'calRefX','calRefY','calRefZ',
            'calUX','calUY','calUZ',
            'calVX','calVY','calVZ',
          ]) { try { await db.execute('ALTER TABLE patients ADD COLUMN $col REAL'); } catch (_) {} }
          try { await db.execute('ALTER TABLE patients ADD COLUMN calibratedAtIso TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE patients ADD COLUMN dropsSinceCal INTEGER'); } catch (_) {}
        }
        if (oldVersion < 6) {
          try { await db.execute('ALTER TABLE patients ADD COLUMN trials TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE patients ADD COLUMN currentTrialNumber INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE patients ADD COLUMN customBaselineAngle REAL'); } catch (_) {}
        }
      },
    );
  }

  static Future<void> insertPatient(Patient patient) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final map = patient.toMap();            // ✅ fix: build map first
    map['createdAt'] = map['createdAt'] ?? now;
    map['lastModified'] = now;

    await db.insert(
      'patients',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> upsertPatient(Patient patient) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final map = patient.toMap();
    map['lastModified'] = now;

    final exists = await db.query('patients', where: 'id = ?', whereArgs: [patient.id], limit: 1);
    if (exists.isEmpty) {
      map['createdAt'] = now;
      await db.insert('patients', map, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update('patients', map, where: 'id = ?', whereArgs: [patient.id]);
    }
  }

  static Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final rows = await db.query(
      'patients',
      orderBy: 'COALESCE(lastModified, createdAt) DESC, name ASC',
    );
    return rows.map((m) => Patient.fromMap(m)).toList();
  }

  static Future<Patient?> getPatient(String id) async {
    final db = await database;
    final rows = await db.query('patients', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Patient.fromMap(rows.first);
  }

  static Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> saveCalibration({
    required String id,
    required double zeroOffsetDeg,
    required List<double> ref, // [x,y,z]
    required List<double> u,   // [x,y,z]
    required List<double> v,   // [x,y,z]
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'patients',
      {
        'calZeroOffsetDeg': zeroOffsetDeg,
        'calRefX': ref[0], 'calRefY': ref[1], 'calRefZ': ref[2],
        'calUX': u[0], 'calUY': u[1], 'calUZ': u[2],
        'calVX': v[0], 'calVY': v[1], 'calVZ': v[2],
        'calibratedAtIso': now,
        'dropsSinceCal': 0,
        'lastModified': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> incrementDropsSinceCal(String id) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE patients
      SET dropsSinceCal = COALESCE(dropsSinceCal, 0) + 1,
          lastModified = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), id]);
  }
}
