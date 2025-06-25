import 'package:flutter/material.dart';
import '../models/patients.dart';
import '../db/patient_database.dart';
import 'home_screen.dart';

class PatientFormScreen extends StatelessWidget {
  const PatientFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final genderController = TextEditingController();
    final heightController = TextEditingController();
    final weightController = TextEditingController();
    final commentsController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('New Patient Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField('Patient ID# *', idController),
            _buildTextField('Name *', nameController),
            _buildTextField('Age (yrs)', ageController, keyboardType: TextInputType.number),
            _buildTextField('Male/Female', genderController),
            _buildTextField('Height (m)', heightController, keyboardType: TextInputType.number),
            _buildTextField('Weight (kg)', weightController, keyboardType: TextInputType.number),
            _buildTextField('Comments / Relevant History', commentsController, maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isEmpty || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                final patient = Patient(
                  id: idController.text,
                  name: nameController.text,
                  age: ageController.text,
                  gender: genderController.text,
                  condition: commentsController.text,
                );

                await PatientDatabase.insertPatient(patient);

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(patient: patient),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
