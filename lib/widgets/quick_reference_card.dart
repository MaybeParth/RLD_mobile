import 'package:flutter/material.dart';

class QuickReferenceCard extends StatelessWidget {
  final String currentStep;
  final VoidCallback? onShowFullInstructions;

  const QuickReferenceCard({
    super.key,
    required this.currentStep,
    this.onShowFullInstructions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getStepIcon(),
                  color: _getStepColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStepTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStepColor(),
                  ),
                ),
                const Spacer(),
                if (onShowFullInstructions != null)
                  TextButton(
                    onPressed: onShowFullInstructions,
                    child: const Text('Full Instructions'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStepDescription(),
              style: const TextStyle(fontSize: 14),
            ),
            if (_hasAdditionalInfo())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStepColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getAdditionalInfo(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStepColor(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStepIcon() {
    switch (currentStep) {
      case 'calibration_position':
        return Icons.phone_android;
      case 'calibration_hold':
        return Icons.pause_circle;
      case 'calibration_flex':
        return Icons.trending_up;
      case 'test_ready':
        return Icons.play_circle;
      case 'test_recording':
        return Icons.fiber_manual_record;
      case 'test_complete':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStepColor() {
    switch (currentStep) {
      case 'calibration_position':
        return Colors.blue;
      case 'calibration_hold':
        return Colors.orange;
      case 'calibration_flex':
        return Colors.green;
      case 'test_ready':
        return Colors.blue;
      case 'test_recording':
        return Colors.red;
      case 'test_complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStepTitle() {
    switch (currentStep) {
      case 'calibration_position':
        return 'Position Device';
      case 'calibration_hold':
        return 'Hold Still';
      case 'calibration_flex':
        return 'Gentle Flex';
      case 'test_ready':
        return 'Ready to Test';
      case 'test_recording':
        return 'RECORDING';
      case 'test_complete':
        return 'Test Complete';
      default:
        return 'Unknown Step';
    }
  }

  String _getStepDescription() {
    switch (currentStep) {
      case 'calibration_position':
        return 'Place the device securely on your leg as instructed.';
      case 'calibration_hold':
        return 'Keep your leg still in the starting position.';
      case 'calibration_flex':
        return 'Gently flex your leg 5-10 degrees, then return to start.';
      case 'test_ready':
        return 'Wait for the recording signal, then let your leg drop naturally.';
      case 'test_recording':
        return 'Perform the leg drop test now. Let it fall naturally, then catch it quickly.';
      case 'test_complete':
        return 'Great job! The test is complete and results are being analyzed.';
      default:
        return 'Follow the on-screen instructions.';
    }
  }

  bool _hasAdditionalInfo() {
    return currentStep == 'calibration_hold' ||
        currentStep == 'test_recording' ||
        currentStep == 'calibration_flex';
  }

  String _getAdditionalInfo() {
    switch (currentStep) {
      case 'calibration_hold':
        return '⏱️ This takes about 10-15 seconds. Try to relax.';
      case 'calibration_flex':
        return '📏 Small movement - just 2-3 inches. Don\'t bend too much.';
      case 'test_recording':
        return '💡 Don\'t control the speed - let it fall naturally!';
      default:
        return '';
    }
  }
}
