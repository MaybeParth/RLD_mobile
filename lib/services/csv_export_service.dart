import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/patients.dart';
import '../models/trial.dart';
import '../db/patient_database.dart';

class CsvExportService {
  static const String _exportFolderName = 'RLD_Exports';

  static Future<Directory> _ensureExportDirectory() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${docs.path}/$_exportFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _ts() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  static String _csvEscape(String? value) {
    final String v = value ?? '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      final escaped = v.replaceAll('"', '""');
      return '"$escaped"';
    }
    return v;
  }

  static Future<File> exportPatientTrialsCsv(Patient patient) async {
    final Directory dir = await _ensureExportDirectory();
    final String filename = 'patient_${patient.id}_trials_${_ts()}.csv';
    final File file = File('${dir.path}/$filename');

    final StringBuffer sb = StringBuffer();
    sb.writeln('Trial ID,Timestamp,Drop Angle (deg),Drop Time (ms),Motor Velocity,Peak Drop Angle (deg),Is Kept,Notes,Discard Reason');

    for (final Trial t in patient.trials) {
      sb.writeln([
        _csvEscape(t.id),
        _csvEscape(t.timestamp.toIso8601String()),
        t.dropAngle?.toStringAsFixed(1) ?? '',
        t.dropTimeMs?.toStringAsFixed(0) ?? '',
        t.motorVelocity?.toStringAsFixed(2) ?? '',
        t.peakDropAngle?.toStringAsFixed(1) ?? '',
        t.isKept ? 'Yes' : 'No',
        _csvEscape(t.notes),
        _csvEscape(t.discardReason),
      ].join(','));
    }

    return file.writeAsString(sb.toString());
  }

  static Future<File> exportPatientSummaryCsv(Patient patient) async {
    final Directory dir = await _ensureExportDirectory();
    final String filename = 'patient_${patient.id}_summary_${_ts()}.csv';
    final File file = File('${dir.path}/$filename');

    final Map<String, String> rows = <String, String>{
      'Patient ID': patient.id,
      'Name': patient.name,
      'Age': patient.age,
      'Gender': patient.gender,
      'Condition': patient.condition,
      'Total Trials': patient.totalTrials.toString(),
      'Kept Trials': patient.keptTrialsCount.toString(),
      'Discarded Trials': patient.discardedTrialsCount.toString(),
      'Calibration Zero Offset': (patient.calZeroOffsetDeg ?? '').toString(),
      'Calibration Ref X': (patient.calRefX ?? '').toString(),
      'Calibration Ref Y': (patient.calRefY ?? '').toString(),
      'Calibration Ref Z': (patient.calRefZ ?? '').toString(),
      'Calibration U X': (patient.calUX ?? '').toString(),
      'Calibration U Y': (patient.calUY ?? '').toString(),
      'Calibration U Z': (patient.calUZ ?? '').toString(),
      'Calibration V X': (patient.calVX ?? '').toString(),
      'Calibration V Y': (patient.calVY ?? '').toString(),
      'Calibration V Z': (patient.calVZ ?? '').toString(),
      'Custom Baseline Angle': (patient.customBaselineAngle ?? '').toString(),
      'Created At': patient.createdAt?.toIso8601String() ?? '',
      'Last Modified': patient.lastModified?.toIso8601String() ?? '',
    };

    final StringBuffer sb = StringBuffer();
    sb.writeln('Field,Value');
    rows.forEach((k, v) => sb.writeln('${_csvEscape(k)},${_csvEscape(v)}'));
    return file.writeAsString(sb.toString());
  }

  static Future<File> exportAllPatientsSummaryCsv(List<Patient> patients) async {
    final Directory dir = await _ensureExportDirectory();
    final String filename = 'patients_summary_${_ts()}.csv';
    final File file = File('${dir.path}/$filename');

    final StringBuffer sb = StringBuffer();
    sb.writeln('Patient ID,Name,Age,Gender,Condition,Created At,Last Modified,Total Trials,Kept Trials,Discarded Trials,Custom Baseline Angle');

    for (final Patient p in patients) {
      sb.writeln([
        _csvEscape(p.id),
        _csvEscape(p.name),
        _csvEscape(p.age),
        _csvEscape(p.gender),
        _csvEscape(p.condition),
        _csvEscape(p.createdAt?.toIso8601String()),
        _csvEscape(p.lastModified?.toIso8601String()),
        p.totalTrials,
        p.keptTrialsCount,
        p.discardedTrialsCount,
        (p.customBaselineAngle ?? '').toString(),
      ].join(','));
    }

    return file.writeAsString(sb.toString());
  }

  static Future<File> exportAllTrialsCombinedCsv(List<Patient> patients) async {
    final Directory dir = await _ensureExportDirectory();
    final String filename = 'all_trials_${_ts()}.csv';
    final File file = File('${dir.path}/$filename');

    final StringBuffer sb = StringBuffer();
    sb.writeln('Patient ID,Patient Name,Patient Age,Patient Gender,Patient Condition,Trial ID,Timestamp,Drop Angle (deg),Drop Time (ms),Motor Velocity,Peak Drop Angle (deg),Is Kept,Notes,Discard Reason');

    for (final Patient p in patients) {
      for (final Trial t in p.trials) {
        sb.writeln([
          _csvEscape(p.id),
          _csvEscape(p.name),
          _csvEscape(p.age),
          _csvEscape(p.gender),
          _csvEscape(p.condition),
          _csvEscape(t.id),
          _csvEscape(t.timestamp.toIso8601String()),
          t.dropAngle?.toStringAsFixed(1) ?? '',
          t.dropTimeMs?.toStringAsFixed(0) ?? '',
          t.motorVelocity?.toStringAsFixed(2) ?? '',
          t.peakDropAngle?.toStringAsFixed(1) ?? '',
          t.isKept ? 'Yes' : 'No',
          _csvEscape(t.notes),
          _csvEscape(t.discardReason),
        ].join(','));
      }
    }

    return file.writeAsString(sb.toString());
  }

  // High-level helpers
  static Future<List<File>> exportPatient(Patient patient) async {
    final File summary = await exportPatientSummaryCsv(patient);
    final File trials = await exportPatientTrialsCsv(patient);
    return [summary, trials];
  }

  static Future<List<File>> exportAll() async {
    final List<Patient> all = await PatientDatabase.getAllPatients();
    final File summary = await exportAllPatientsSummaryCsv(all);
    final File allTrials = await exportAllTrialsCombinedCsv(all);
    return [summary, allTrials];
  }
}


