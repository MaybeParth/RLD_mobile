import 'package:flutter/material.dart';

class CalibrationInstructionDialog extends StatefulWidget {
  final String currentStep;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final bool isLastStep;

  const CalibrationInstructionDialog({
    super.key,
    required this.currentStep,
    required this.onNext,
    required this.onCancel,
    this.isLastStep = false,
  });

  @override
  State<CalibrationInstructionDialog> createState() =>
      _CalibrationInstructionDialogState();
}

class _CalibrationInstructionDialogState
    extends State<CalibrationInstructionDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.tune, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Calibration Step'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepContent(),
            const SizedBox(height: 20),
            _buildProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.isLastStep ? 'Complete' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (widget.currentStep) {
      case 'position':
        return _buildPositionStep();
      case 'hold_still':
        return _buildHoldStillStep();
      case 'flex':
        return _buildFlexStep();
      case 'complete':
        return _buildCompleteStep();
      default:
        return const Text('Unknown step');
    }
  }

  Widget _buildPositionStep() {
    return Column(
      children: [
        Icon(
          Icons.phone_android,
          size: 64,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        const Text(
          'Position the Device',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please place the device on your leg as instructed by the clinician. Make sure it\'s secure and won\'t move during the test.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Text(
            '💡 Tip: The device should be firmly attached and not wobble when you move your leg slightly.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildHoldStillStep() {
    return Column(
      children: [
        Icon(
          Icons.pause_circle,
          size: 64,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        const Text(
          'Hold Still',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Keep your leg in the starting position and hold completely still. The device needs to measure your baseline position.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text(
            '⏱️ This will take about 10-15 seconds. Try to relax and breathe normally.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildFlexStep() {
    return Column(
      children: [
        Icon(
          Icons.trending_up,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'Gentle Flex',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'When prompted, gently flex your leg 5-10 degrees (about 2-3 inches) without twisting. Hold for 2-3 seconds, then return to starting position.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Text(
            '📏 The movement should be small - just enough to change the angle slightly. Don\'t bend your knee too much.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'Calibration Complete!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Great! The device is now calibrated and ready for testing. You can now proceed with the leg drop tests.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Text(
            '🎯 The system will now accurately measure your leg drop reaction time.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['position', 'hold_still', 'flex', 'complete'];
    final currentIndex = steps.indexOf(widget.currentStep);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final isActive = index <= currentIndex;

        return Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            if (index < steps.length - 1)
              Container(
                width: 20,
                height: 2,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
          ],
        );
      }).toList(),
    );
  }
}
