import 'package:flutter/material.dart';
import '../models/patients.dart';
import '../db/patient_database.dart';
import 'home_screen.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final commentsController = TextEditingController();

  String gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patient Form')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 600 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField('Patient ID# *', idController),
                    _buildTextField('Name', nameController),
                    _buildTextField('Age (yrs)', ageController, keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    Text('Gender:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'Male',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() => gender = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'Female',
                            groupValue: gender,
                            onChanged: (value) {
                              setState(() => gender = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                    _buildTextField('Height (m)', heightController, keyboardType: TextInputType.number),
                    _buildTextField('Weight (kg)', weightController, keyboardType: TextInputType.number),
                    _buildTextField('Comments / Relevant History', commentsController, maxLines: 4),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    )
                  ],
                ),
              ),
            ),
          );
        },
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (idController.text.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final patient = Patient(
      id: idController.text,
      name: nameController.text,
      age: ageController.text,
      gender: gender,
      condition: commentsController.text,
    );

    await PatientDatabase.insertPatient(patient);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(patient: patient),
      ),
    );
  }
}
