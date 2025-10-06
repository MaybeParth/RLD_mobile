import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/patients.dart';
import '../models/trial.dart';

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
      version: 6, 
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
    final map = patient.toMap();            
    map['createdAt'] = map['createdAt'] ?? now;
    map['lastModified'] = now;
    // Ensure trials are stored as JSON string in DB
    final trialsValue = map['trials'];
    if (trialsValue is List) {
      map['trials'] = jsonEncode(trialsValue);
    }

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
    // Ensure trials are stored as JSON string in DB
    final trialsValue = map['trials'];
    if (trialsValue is List) {
      map['trials'] = jsonEncode(trialsValue);
    }

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
    required List<double> ref, 
    required List<double> u,   
    required List<double> v,  
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

  static Future<void> addTrialToPatient(String patientId, Trial trial) async {
    final db = await database;
    final patient = await getPatient(patientId);
    if (patient == null) return;

    final updatedTrials = List<Trial>.from(patient.trials)..add(trial);
    // Correctly serialize each trial, not the last added one repeatedly
    final trialsJson = updatedTrials.map((t) => t.toMap()).toList();
    
    await db.update(
      'patients',
      {
        'trials': jsonEncode(trialsJson),
        'currentTrialNumber': updatedTrials.length,
        'lastModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  static Future<void> updateTrialStatus(String patientId, String trialId, bool isKept, {String? notes, String? discardReason}) async {
    final db = await database;
    final patient = await getPatient(patientId);
    if (patient == null) return;

    final updatedTrials = patient.trials.map((trial) {
      if (trial.id == trialId) {
        return trial.copyWith(
          isKept: isKept,
          notes: notes,
          discardReason: discardReason,
        );
      }
      return trial;
    }).toList();

    final trialsJson = updatedTrials.map((t) => t.toMap()).toList();
    
    await db.update(
      'patients',
      {
        'trials': jsonEncode(trialsJson),
        'lastModified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [patientId],
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
