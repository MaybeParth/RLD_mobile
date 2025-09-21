import 'package:flutter/material.dart';

class PatientInstructionsScreen extends StatelessWidget {
  final String patientName;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const PatientInstructionsScreen({
    super.key,
    required this.patientName,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Instructions'),
        leading: onBack != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeCard(),
            
            const SizedBox(height: 20),
            
            // Calibration instructions
            _buildCalibrationInstructions(),
            
            const SizedBox(height: 20),
            
            // Test execution instructions
            _buildTestInstructions(),
            
            const SizedBox(height: 20),
            
            // Important notes
            _buildImportantNotes(),
            
            const SizedBox(height: 30),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.check_circle),
                label: const Text('I Understand - Start Calibration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Welcome, $patientName!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This test measures your leg drop reaction time. Please follow the instructions carefully for accurate results.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => Icon(Icons.tune, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Calibration Steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInstructionStep(
              stepNumber: 1,
              title: 'Position the Device',
              description: 'Place the device on your leg as instructed by the clinician. Make sure it\'s secure and won\'t move during the test.',
              icon: Icons.phone_android,
            ),
            
            const SizedBox(height: 12),
            
            _buildInstructionStep(
              stepNumber: 2,
              title: 'Hold Still',
              description: 'Keep your leg in the starting position and hold completely still. The device needs to measure your baseline position.',
              icon: Icons.pause_circle,
            ),
            
            const SizedBox(height: 12),
            
            _buildInstructionStep(
              stepNumber: 3,
              title: 'Gentle Flex',
              description: 'When prompted, gently flex your leg 5-10 degrees (about 2-3 inches) without twisting. Hold for 2-3 seconds, then return to starting position.',
              icon: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => Icon(Icons.science, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Test Execution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInstructionStep(
              stepNumber: 1,
              title: 'Ready Position',
              description: 'Start in the same position as calibration. Keep your leg extended and relaxed.',
              icon: Icons.play_circle,
            ),
            
            const SizedBox(height: 12),
            
            _buildInstructionStep(
              stepNumber: 2,
              title: 'Wait for Signal',
              description: 'Wait for the "RECORDING" signal. Do not move until you see this indicator.',
              icon: Icons.timer,
            ),
            
            const SizedBox(height: 12),
            
            _buildInstructionStep(
              stepNumber: 3,
              title: 'Drop Your Leg',
              description: 'When ready, let your leg drop naturally as fast as possible. Don\'t try to control the speed - just let it fall naturally.',
              icon: Icons.trending_down,
            ),
            
            const SizedBox(height: 12),
            
            _buildInstructionStep(
              stepNumber: 4,
              title: 'Catch and Return',
              description: 'As soon as you feel the drop, catch your leg and return it to the starting position as quickly as possible.',
              icon: Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotes() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(
                  'Important Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildNoteItem('• Keep the device secure and don\'t let it move'),
            _buildNoteItem('• Don\'t try to control the drop speed - let it fall naturally'),
            _buildNoteItem('• Focus on the reaction, not the drop itself'),
            _buildNoteItem('• If you feel uncomfortable, let the clinician know'),
            _buildNoteItem('• We can repeat trials if needed - don\'t worry about mistakes'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required int stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}
