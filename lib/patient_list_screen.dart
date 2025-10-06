import 'package:flutter/material.dart';
import '../models/patients.dart';
import '../db/patient_database.dart';
import 'bloc_screens/simple_test_screen_bloc.dart';
import 'services/csv_export_service.dart';
import 'package:path_provider/path_provider.dart';

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

    if (confirmed ?? false) {
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
            onPressed: () async {
              Navigator.pop(context);
              try {
                final files = await CsvExportService.exportPatient(patient);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported ${files.length} file(s) for ${patient.name} to Documents/RLD_Exports'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
            child: const Text(
              'Export CSV',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
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
            tooltip: 'Export all patients CSV',
            icon: const Icon(Icons.download),
            onPressed: () async {
              try {
                final files = await CsvExportService.exportAll();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported ${files.length} file(s) to Documents/RLD_Exports'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
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
