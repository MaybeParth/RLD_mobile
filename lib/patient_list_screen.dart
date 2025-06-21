import 'package:flutter/material.dart';
import '../models/patients.dart';
import '../db/patient_database.dart';
import 'home_screen.dart';

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

  void _showPatientPopup(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.name} (ID: ${patient.id})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${patient.name}"),
            Text("Age: ${patient.age}"),
            Text("Gender: ${patient.gender}"),
            Text("Condition: ${patient.condition}"),
            const Divider(),
            Text("Drop Angle: ${patient.dropAngle?.toStringAsFixed(2) ?? '--'}°"),
            Text("Drop Time: ${patient.dropTimeMs?.toStringAsFixed(0) ?? '--'} ms"),
            Text("Motor Velocity: ${patient.motorVelocity?.toStringAsFixed(2) ?? '--'} °/s"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen(patient: patient)),
              );
            },
            child: const Text("Perform New Test"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Database')),
      body: patients.isEmpty
          ? const Center(child: Text("No patient records found."))
          : ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  patient.gender.toLowerCase().contains('male') ? Icons.male : Icons.female,
                ),
              ),
              title: Text('${patient.name} (ID: ${patient.id})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${patient.age} yr old - ${patient.gender}',
                    style: TextStyle(
                      color: patient.gender.toLowerCase().contains('male') ? Colors.red : Colors.purple,
                    ),
                  ),
                  Text(patient.condition),
                ],
              ),
              onTap: () => _showPatientPopup(patient),
            ),
          );
        },
      ),
    );
  }
}
