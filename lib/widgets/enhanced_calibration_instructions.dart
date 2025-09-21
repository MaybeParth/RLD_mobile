import 'package:flutter/material.dart';

class EnhancedCalibrationInstructions extends StatelessWidget {
  const EnhancedCalibrationInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings, color: Colors.blue),
          SizedBox(width: 8),
          Text('Calibration Instructions'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStep(
              step: 1,
              title: 'Device Placement',
              description: 'Securely attach the device to your leg using the provided strap. Make sure it\'s tight enough to prevent movement but not uncomfortable.',
              icon: Icons.phone_android,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            _buildStep(
              step: 2,
              title: 'Starting Position',
              description: 'Hold your leg in your normal extended position. This will be your reference point (0°). If you have extension lag, this is fine - we\'ll adjust for it later.',
              icon: Icons.straighten,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            _buildStep(
              step: 3,
              title: 'Hold Still (10 seconds)',
              description: 'Keep your leg completely still for 10 seconds. The device needs to capture a stable reference. Any movement will cause calibration to fail.',
              icon: Icons.pause_circle,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            _buildStep(
              step: 4,
              title: 'Gentle Flex (5-20°)',
              description: 'Slowly bend your knee about 5-20 degrees. Move only your knee - avoid twisting or moving your hip. Think of it like a gentle knee bend.',
              icon: Icons.trending_down,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            _buildStep(
              step: 5,
              title: 'Hold Flex Position',
              description: 'Hold the flexed position for 3 seconds, then return to your starting position. This helps the device understand your leg\'s movement plane.',
              icon: Icons.timer,
              color: Colors.purple,
            ),
            SizedBox(height: 20),
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
                      'Tip: If calibration fails, try again with smaller movements and ensure the device stays still during the reference phase.',
                      style: TextStyle(fontSize: 12, color: Colors.amber[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildStep({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


