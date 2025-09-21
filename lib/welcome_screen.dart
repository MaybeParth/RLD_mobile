// welcome_screen.dart
import 'package:flutter/material.dart';
import 'patient_list_screen.dart';
import 'bloc_screens/patient_form_screen_bloc.dart';
import 'screens/patient_instructions_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/img.png',
              height: 200,
            ),
            const SizedBox(height: 40),
            _buildMenuButton(context, 'New Test', Colors.orange, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientFormScreenBloc()),
              );
            }),
            const SizedBox(height: 20),
            _buildMenuButton(context, 'Instructions', Colors.orange, () {
              _showGeneralInstructions(context);
            }),
            const SizedBox(height: 20),
            _buildMenuButton(context, 'Patient Database', Colors.deepOrange, () {
              // Add navigation to Patient Database page
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

  Widget _buildMenuButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        backgroundColor: color,
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

  void _showGeneralInstructions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientInstructionsScreen(
          patientName: 'User',
          onContinue: () {
            Navigator.pop(context);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
