import 'package:flutter/material.dart';

class ManualCalibrationDialog extends StatefulWidget {
  final double currentAngle;
  final Function(double baselineAngle) onSetBaseline;

  const ManualCalibrationDialog({
    super.key,
    required this.currentAngle,
    required this.onSetBaseline,
  });

  @override
  State<ManualCalibrationDialog> createState() => _ManualCalibrationDialogState();
}

class _ManualCalibrationDialogState extends State<ManualCalibrationDialog> {
  late double _baselineAngle;

  @override
  void initState() {
    super.initState();
    _baselineAngle = widget.currentAngle;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.my_location, color: Colors.blue),
          SizedBox(width: 8),
          Text('Manual Calibration'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current angle display
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Angle',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.currentAngle.toStringAsFixed(1)}°',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'How to Set Your Baseline:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Position your leg in your desired starting position\n'
                    '2. Watch the "Current Angle" above (180° = extended leg)\n'
                    '3. Click "Set as Baseline" when you\'re ready\n'
                    '4. All measurements will be relative to this angle\n'
                    '5. Angles decrease as you drop your leg',
                    style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Manual angle input
            Text(
              'Or manually enter your baseline angle:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Baseline Angle (degrees)',
                      border: OutlineInputBorder(),
                      suffixText: '°',
                    ),
                    onChanged: (value) {
                      final angle = double.tryParse(value);
                      if (angle != null) {
                        setState(() {
                          _baselineAngle = angle.clamp(0.0, 180.0);
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _baselineAngle = widget.currentAngle;
                    });
                  },
                  child: Text('Use Current'),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Baseline angle display
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Your Baseline Angle',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_baselineAngle.toStringAsFixed(1)}°',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All drop measurements will be relative to this angle\n'
                      '180° = extended leg, angles decrease as you drop',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSetBaseline(_baselineAngle);
            Navigator.of(context).pop();
          },
          child: Text('Set as Baseline'),
        ),
      ],
    );
  }
}
