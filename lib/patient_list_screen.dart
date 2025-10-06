import 'dart:convert' as convert;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../models/patients.dart';
import '../db/patient_database.dart';
import 'bloc_screens/simple_test_screen_bloc.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List<Patient> patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final data = await PatientDatabase.getAllPatients();
    setState(() {
      patients = data;
    });
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Delete',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${patient.name}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PatientDatabase.deletePatient(patient.id);
      final removedPatient = patient;
      setState(() => patients.remove(patient));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Deleted ${removedPatient.name}",
            style: const TextStyle(fontSize: 16),
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await PatientDatabase.insertPatient(removedPatient);
              _loadPatients();
            },
          ),
        ),
      );
    }
  }

  void _showPatientPopup(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${patient.name} (ID: ${patient.id})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${patient.name}", style: const TextStyle(fontSize: 16)),
            Text("Age: ${patient.age}", style: const TextStyle(fontSize: 16)),
            Text("Gender: ${patient.gender}", style: const TextStyle(fontSize: 16)),
            Text("Condition: ${patient.condition}", style: const TextStyle(fontSize: 16)),
            const Divider(),
            Text("Drop Angle: ${patient.dropAngle?.toStringAsFixed(2) ?? '--'}°", style: const TextStyle(fontSize: 16)),
            Text("Drop Time: ${patient.dropTimeMs?.toStringAsFixed(0) ?? '--'} ms", style: const TextStyle(fontSize: 16)),
            Text("Motor Velocity: ${patient.motorVelocity?.toStringAsFixed(2) ?? '--'} °/s", style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SimpleTestScreenBloc(patient: patient)),
              );
            },
            child: const Text(
              "Perform New Test",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Database',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Export JSON',
            icon: const Icon(Icons.file_download),
            onPressed: _exportAllAsJson,
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.table_chart),
            onPressed: _exportAllAsCsv,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatients,
        child: patients.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                "No patient records found.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ],
        )
            : ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return Dismissible(
              key: Key(patient.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                await _deletePatient(patient);
                return false; // Prevent Dismissible from auto-removing the item
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      patient.gender.toLowerCase().contains('male') ? Icons.male : Icons.female,
                    ),
                  ),
                  title: Text(
                    '${patient.name} (ID: ${patient.id})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${patient.age} yr old - ${patient.gender}',
                        style: TextStyle(
                          fontSize: 16,
                          color: patient.gender.toLowerCase().contains('male') ? Colors.red : Colors.purple,
                        ),
                      ),
                      Text(
                        patient.condition,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  onTap: () => _showPatientPopup(patient),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension _PatientExport on _PatientListScreenState {
  Future<void> _exportAllAsJson() async {
    try {
      final all = await PatientDatabase.getAllPatients();
      final data = all.map((p) => p.toMap()).toList();
      final jsonStr = convert.JsonEncoder.withIndent('  ').convert(data);

      final file = await _writeTempFile('patients_export.json', jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'Patient database export (JSON)');
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  Future<void> _exportAllAsCsv() async {
    try {
      final all = await PatientDatabase.getAllPatients();

      // Header columns
      final headers = <String>[
        'id','name','age','gender','condition',
        'createdAt','lastModified',
        'calZeroOffsetDeg','calRefX','calRefY','calRefZ','calUX','calUY','calUZ','calVX','calVY','calVZ','calibratedAtIso','dropsSinceCal','customBaselineAngle',
        'legacy_initialZ','legacy_finalZ','legacy_dropAngle','legacy_dropTimeMs','legacy_motorVelocity',
        'trials_count','kept_trials_count','discarded_trials_count',
        // Flatten a few recent trials (up to 3) for convenience
        'trial1_id','trial1_timestamp','trial1_isKept','trial1_dropAngle','trial1_dropTimeMs','trial1_motorVelocity',
        'trial2_id','trial2_timestamp','trial2_isKept','trial2_dropAngle','trial2_dropTimeMs','trial2_motorVelocity',
        'trial3_id','trial3_timestamp','trial3_isKept','trial3_dropAngle','trial3_dropTimeMs','trial3_motorVelocity',
      ];

      final rows = <List<String>>[];
      rows.add(headers);

      for (final p in all) {
        String fmtDate(DateTime? d) => d != null ? d.toIso8601String() : '';
        String fmtNum(num? n) => n == null ? '' : n.toString();

        final kept = p.keptTrials;
        final discarded = p.discardedTrials;

        List<String> base = [
          p.id,
          p.name,
          p.age,
          p.gender,
          p.condition,
          fmtDate(p.createdAt),
          fmtDate(p.lastModified),
          fmtNum(p.calZeroOffsetDeg),
          fmtNum(p.calRefX), fmtNum(p.calRefY), fmtNum(p.calRefZ),
          fmtNum(p.calUX), fmtNum(p.calUY), fmtNum(p.calUZ),
          fmtNum(p.calVX), fmtNum(p.calVY), fmtNum(p.calVZ),
          p.calibratedAtIso ?? '',
          p.dropsSinceCal?.toString() ?? '',
          fmtNum(p.customBaselineAngle),
          fmtNum(p.initialZ),
          fmtNum(p.finalZ),
          fmtNum(p.dropAngle),
          fmtNum(p.dropTimeMs),
          fmtNum(p.motorVelocity),
          p.trials.length.toString(),
          kept.length.toString(),
          discarded.length.toString(),
        ];

        List<String> trialCols = [];
        for (int i = 0; i < 3; i++) {
          if (i < p.trials.length) {
            final t = p.trials[i];
            trialCols.addAll([
              t.id,
              t.timestamp.toIso8601String(),
              (t.isKept == true).toString(),
              fmtNum(t.dropAngle),
              fmtNum(t.dropTimeMs),
              fmtNum(t.motorVelocity),
            ]);
          } else {
            trialCols.addAll(['','','','','','']);
          }
        }

        rows.add([...base, ...trialCols]);
      }

      final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
      final file = await _writeTempFile('patients_export.csv', csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Patient database export (CSV)');
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  String _escapeCsv(String s) {
    final needsQuotes = s.contains(',') || s.contains('"') || s.contains('\n');
    String v = s.replaceAll('"', '""');
    return needsQuotes ? '"$v"' : v;
  }

  Future<File> _writeTempFile(String filename, String contents) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, filename);
    final file = File(path);
    return file.writeAsString(contents);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
