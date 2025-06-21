// patient_router.dart
import 'package:flutter/material.dart';
import 'patient_form_screen.dart';
import 'patient_list_screen.dart';

class PatientRouterScreen extends StatelessWidget {
  const PatientRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/doctor_icon.png',
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              'Is this a new patient?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildButton(context, 'Yes', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientFormScreen()),
              );
            }),
            const SizedBox(height: 20),
            _buildButton(context, 'No', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientListScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shadowColor: Colors.black54,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
