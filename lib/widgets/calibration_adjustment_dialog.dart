import 'package:flutter/material.dart';

class CalibrationAdjustmentDialog extends StatefulWidget {
  final double currentAngle;
  final double currentZeroOffset;
  final Function(double zeroOffset) onAdjust;

  const CalibrationAdjustmentDialog({
    super.key,
    required this.currentAngle,
    required this.currentZeroOffset,
    required this.onAdjust,
  });

  @override
  State<CalibrationAdjustmentDialog> createState() =>
      _CalibrationAdjustmentDialogState();
}

class _CalibrationAdjustmentDialogState
    extends State<CalibrationAdjustmentDialog> {
  late double _zeroOffset;
  late double _displayedAngle;

  @override
  void initState() {
    super.initState();
    _zeroOffset = widget.currentZeroOffset;
    _displayedAngle = widget.currentAngle;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calibration Adjustment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Adjust the calibration to account for extension lag. The angle should show realistic values (typically 0-180°).',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Zero Offset: '),
              Expanded(
                child: Slider(
                  value: _zeroOffset,
                  min: -90.0,
                  max: 90.0,
                  divisions: 180,
                  label: '${_zeroOffset.toStringAsFixed(1)}°',
                  onChanged: (value) {
                    setState(() {
                      _zeroOffset = value;
                      _displayedAngle = widget.currentAngle + _zeroOffset;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Current Angle: ${_displayedAngle.toStringAsFixed(1)}°',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Zero Offset: ${_zeroOffset.toStringAsFixed(1)}°',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Move your leg to test the angle reading. Adjust the zero offset until the angle shows realistic values.\n'
            '180° = extended leg, angles decrease as you drop.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onAdjust(_zeroOffset);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
