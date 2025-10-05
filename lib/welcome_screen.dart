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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 480;
            final maxContentWidth = isWide ? 500.0 : double.infinity;
            final imgHeight = (constraints.maxHeight * 0.28).clamp(140.0, 260.0);

            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 64),
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/img.png',
                            height: imgHeight,
                          ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientListScreen()),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        backgroundColor: color,
        foregroundColor: Colors.white,
        shadowColor: Colors.black54,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
