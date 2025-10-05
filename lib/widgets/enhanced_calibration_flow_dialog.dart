import 'package:flutter/material.dart';

class EnhancedCalibrationFlowDialog extends StatefulWidget {
  final String currentStep;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const EnhancedCalibrationFlowDialog({
    super.key,
    required this.currentStep,
    required this.onNext,
    required this.onCancel,
  });

  @override
  State<EnhancedCalibrationFlowDialog> createState() =>
      _EnhancedCalibrationFlowDialogState();
}

class _EnhancedCalibrationFlowDialogState
    extends State<EnhancedCalibrationFlowDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: Colors.blue),
          SizedBox(width: 8),
          Text('Calibration Process'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepIndicator(),
            SizedBox(height: 20),
            _buildCurrentStepContent(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onNext,
          child: Text(_getButtonText()),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Position', 'Hold Still', 'Flex Leg', 'Set Baseline'];
    final currentIndex = _getCurrentStepIndex();

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentIndex;
        final isCompleted = index < currentIndex;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : (isActive ? Colors.blue : Colors.grey),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                step,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.blue : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (widget.currentStep) {
      case 'position':
        return _buildPositionStep();
      case 'hold_still':
        return _buildHoldStillStep();
      case 'flex_leg':
        return _buildFlexLegStep();
      case 'set_baseline':
        return _buildSetBaselineStep();
      default:
        return _buildPositionStep();
    }
  }

  Widget _buildPositionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Position the Device',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _buildInstructionItem(
          icon: Icons.phone_android,
          text:
              'Securely attach the device to your leg using the provided strap',
          color: Colors.blue,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.straighten,
          text: 'Position your leg in your normal extended position',
          color: Colors.green,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.warning,
          text: 'Make sure the device is tight enough to prevent movement',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildHoldStillStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Hold Still',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _buildInstructionItem(
          icon: Icons.pause_circle,
          text: 'Keep your leg completely still for 10 seconds',
          color: Colors.blue,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.timer,
          text: 'The device needs to capture a stable reference',
          color: Colors.green,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.warning,
          text: 'Any movement will cause calibration to fail',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildFlexLegStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Flex Your Leg',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _buildInstructionItem(
          icon: Icons.trending_down,
          text: 'Slowly bend your knee about 5-20 degrees',
          color: Colors.blue,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.rotate_right,
          text: 'Move only your knee - avoid twisting or moving your hip',
          color: Colors.green,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.timer,
          text:
              'Hold the flexed position for 3 seconds, then return to extended',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSetBaselineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Set Your Baseline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _buildInstructionItem(
          icon: Icons.my_location,
          text: 'Position your leg in your desired starting position',
          color: Colors.blue,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.tune,
          text: 'This will be your reference point (0°) for all measurements',
          color: Colors.green,
        ),
        SizedBox(height: 8),
        _buildInstructionItem(
          icon: Icons.info,
          text: 'The device will capture this angle as your baseline',
          color: Colors.orange,
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[700]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is where you can account for extension lag or other factors that affect your leg position.',
                  style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  int _getCurrentStepIndex() {
    switch (widget.currentStep) {
      case 'position':
        return 0;
      case 'hold_still':
        return 1;
      case 'flex_leg':
        return 2;
      case 'set_baseline':
        return 3;
      default:
        return 0;
    }
  }

  String _getButtonText() {
    switch (widget.currentStep) {
      case 'position':
        return 'Start Calibration';
      case 'hold_still':
        return 'Hold Still';
      case 'flex_leg':
        return 'Flex Leg';
      case 'set_baseline':
        return 'Set Baseline';
      default:
        return 'Next';
    }
  }
}
