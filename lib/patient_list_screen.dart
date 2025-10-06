import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
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
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  IconData _genderIcon(String gender) {
    final g = gender.trim().toLowerCase();
    final isFemale = g == 'female' || g.startsWith('fem') || g.contains('female');
    final isMale = !isFemale && (g == 'male' || g.startsWith('mal') || g.contains(' male') || g.endsWith('male'));
    final isNonBinary = g.contains('non-binary') || g.contains('nonbinary') || g.contains('non binary') || g == 'nb';
    if (isFemale) return Icons.female;
    if (isMale) return Icons.male;
    if (isNonBinary) return Icons.person;
    return Icons.person;
  }

  Color _genderColor(String gender) {
    final g = gender.trim().toLowerCase();
    final isFemale = g == 'female' || g.startsWith('fem') || g.contains('female');
    final isMale = !isFemale && (g == 'male' || g.startsWith('mal') || g.contains(' male') || g.endsWith('male'));
    final isNonBinary = g.contains('non-binary') || g.contains('nonbinary') || g.contains('non binary') || g == 'nb';
    if (isFemale) return Colors.pink;
    if (isMale) return Colors.blue;
    if (isNonBinary) return Colors.purple;
    return Colors.grey;
  }

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

  Future<void> _deletePatient(int index, Patient patient) async {
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
      setState(() => patients.removeAt(index));
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedTile(
          context,
          index,
          removedPatient,
          animation,
        ),
        duration: const Duration(milliseconds: 220),
      );

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
              if (!mounted) return;
              setState(() {
                final insertIndex = (index <= patients.length) ? index : patients.length;
                patients.insert(insertIndex, removedPatient);
                _listKey.currentState?.insertItem(
                  insertIndex,
                  duration: const Duration(milliseconds: 220),
                );
              });
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

  Widget _buildAnimatedTile(BuildContext context, int index, Patient patient, Animation<double> animation) {
    final tile = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _genderColor(patient.gender).withOpacity(0.15),
          child: Icon(
            _genderIcon(patient.gender),
            color: _genderColor(patient.gender),
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
              style: TextStyle(fontSize: 16, color: _genderColor(patient.gender)),
            ),
            Text(
              patient.condition,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        onTap: () => _showPatientPopup(patient),
      ),
    );

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: Dismissible(
        key: Key(patient.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          await _deletePatient(index, patient);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: tile,
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
            tooltip: 'Export XLSX',
            icon: const Icon(Icons.grid_on),
            onPressed: _exportAllAsXlsx,
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
            : AnimatedList(
          key: _listKey,
          initialItemCount: patients.length,
          itemBuilder: (context, index, animation) {
            final patient = patients[index];
            return _buildAnimatedTile(context, index, patient, animation);
          },
        ),
      ),
    );
  }
}

extension _PatientExport on _PatientListScreenState {

  Future<void> _exportAllAsXlsx() async {
    try {
      final all = await PatientDatabase.getAllPatients();
      final excel = Excel.createExcel();
      final sheet = excel['Patients'];

      // Header row
      final headers = <String>[
        'id','name','age','gender','condition',
        'createdAt','lastModified',
        'calZeroOffsetDeg','calRefX','calRefY','calRefZ','calUX','calUY','calUZ','calVX','calVY','calVZ','calibratedAtIso','dropsSinceCal','customBaselineAngle',
        'legacy_initialZ','legacy_finalZ','legacy_dropAngle','legacy_dropTimeMs','legacy_motorVelocity',
        'trials_count','kept_trials_count','discarded_trials_count',
      ];
      sheet.appendRow(headers.map<CellValue?>((s) => TextCellValue(s)).toList());

      String fmtDate(DateTime? d) => d != null ? d.toIso8601String() : '';
      String fmtNum(num? n) => n == null ? '' : n.toString();

      for (final p in all) {
        final kept = p.keptTrials;
        final discarded = p.discardedTrials;
        final row = <String>[
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
        sheet.appendRow(row.map<CellValue?>((s) => TextCellValue(s)).toList());
      }

      // Separate sheet for trials (one row per trial)
      final trialSheet = excel['Trials'];
      final trialHeaders = <String>[
        'patient_id','patient_name',
        'trial_id','timestamp','isKept','dropAngle','dropTimeMs','motorVelocity','notes','discardReason'
      ];
      trialSheet.appendRow(trialHeaders.map<CellValue?>((s) => TextCellValue(s)).toList());
      for (final p in all) {
        for (final t in p.trials) {
          trialSheet.appendRow([
            TextCellValue(p.id),
            TextCellValue(p.name),
            TextCellValue(t.id),
            TextCellValue(t.timestamp.toIso8601String()),
            TextCellValue(t.isKept ? 'true' : 'false'),
            TextCellValue(fmtNum(t.dropAngle)),
            TextCellValue(fmtNum(t.dropTimeMs)),
            TextCellValue(fmtNum(t.motorVelocity)),
            TextCellValue(t.notes ?? ''),
            TextCellValue(t.discardReason ?? ''),
          ]);
        }
      }

      final bytes = excel.encode()!;
      final file = await _writeTempBytes('patients_export.xlsx', bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Patient database export (XLSX)');
    } catch (e) {
      _showSnack('Export failed: $e');
    }
  }

  Future<File> _writeTempBytes(String filename, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, filename);
    final file = File(path);
    return file.writeAsBytes(bytes, flush: true);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
