import 'package:flutter/material.dart';

class TestInstructionDialog extends StatefulWidget {
  final String currentPhase;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final bool isRecording;

  const TestInstructionDialog({
    super.key,
    required this.currentPhase,
    required this.onStart,
    required this.onCancel,
    this.isRecording = false,
  });

  @override
  State<TestInstructionDialog> createState() => _TestInstructionDialogState();
}

class _TestInstructionDialogState extends State<TestInstructionDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.science, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Test Instructions'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPhaseContent(),
            const SizedBox(height: 20),
            _buildStatusIndicator(),
          ],
        ),
      ),
      actions: widget.isRecording ? null : [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.onStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Start Test'),
        ),
      ],
    );
  }

  Widget _buildPhaseContent() {
    switch (widget.currentPhase) {
      case 'ready':
        return _buildReadyPhase();
      case 'recording':
        return _buildRecordingPhase();
      case 'complete':
        return _buildCompletePhase();
      default:
        return const Text('Unknown phase');
    }
  }

  Widget _buildReadyPhase() {
    return Column(
      children: [
        Icon(
          Icons.play_circle,
          size: 64,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        const Text(
          'Ready to Test',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'You\'re ready to perform the leg drop test. The system will measure how many degrees your leg drops.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        
        _buildInstructionItem(
          icon: Icons.timer,
          text: 'Wait for the "RECORDING" signal before moving',
        ),
        
        _buildInstructionItem(
          icon: Icons.trending_down,
          text: 'Let your leg drop naturally as fast as possible',
        ),
        
        _buildInstructionItem(
          icon: Icons.speed,
          text: 'The system will measure your drop angle in degrees',
        ),
        
        _buildInstructionItem(
          icon: Icons.trending_up,
          text: 'Kick your leg back to 180° extended position quickly',
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
            '💡 Remember: Don\'t try to control the drop speed - let it fall naturally!',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingPhase() {
    return Column(
      children: [
        Icon(
          Icons.fiber_manual_record,
          size: 64,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        const Text(
          'RECORDING',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'The test is now recording. You can perform the leg drop test at any time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              const Text(
                'What to do now:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Let your leg drop naturally'),
              const Text('2. System measures your drop angle in degrees'),
              const Text('3. Kick your leg back to 180° extended position'),
              const Text('4. System detects your reaction automatically'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletePhase() {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),
        const Text(
          'Test Complete!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Great job! The test has been completed successfully. The system measured how many degrees your leg dropped.',
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
            '🎯 Your drop angle, reaction time, and motor velocity have been measured and recorded.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;
    
    switch (widget.currentPhase) {
      case 'ready':
        statusColor = Colors.blue;
        statusText = 'Ready';
        break;
      case 'recording':
        statusColor = Colors.red;
        statusText = 'Recording';
        break;
      case 'complete':
        statusColor = Colors.green;
        statusText = 'Complete';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
