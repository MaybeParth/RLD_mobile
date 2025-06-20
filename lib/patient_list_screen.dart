// patient_list_screen.dart
import 'package:flutter/material.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> patients = [
      {
        'id': '001',
        'age': '83 yr old - Male',
        'condition': 'Type 2 diabetic'
      },
      {
        'id': '002',
        'age': '64 yr old - Female',
        'condition': 'ACL tear: R. Knee (10/27/2017)'
      },
      {
        'id': '003',
        'age': '76 yr old - Female',
        'condition': 'L. Knee pain [Rated: 6/10]'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Database')),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return ListTile(
            leading: CircleAvatar(
              child: Icon(
                patient['age']!.contains('Male') ? Icons.male : Icons.female,
              ),
            ),
            title: Text('ID#: ${patient['id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient['age']!,
                  style: TextStyle(color: patient['age']!.contains('Male') ? Colors.red : Colors.purple),
                ),
                Text(patient['condition']!),
              ],
            ),
          );
        },
      ),
    );
  }
}
