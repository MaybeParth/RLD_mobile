import 'package:flutter/material.dart';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:vector_math/vector_math_64.dart';

class CalibrationDebugDialog extends StatefulWidget {
  const CalibrationDebugDialog({super.key});

  @override
  State<CalibrationDebugDialog> createState() => _CalibrationDebugDialogState();
}

class _CalibrationDebugDialogState extends State<CalibrationDebugDialog> {
  String _status = 'Initializing...';
  List<String> _logs = [];
  bool _isCalibrating = false;
  Vector3? _lastAcceleration;
  double _sampleCount = 0;

  @override
  void initState() {
    super.initState();
    _testSensors();
  }

  void _testSensors() {
    setState(() {
      _status = 'Testing sensor access...';
      _logs.add('Testing sensor access...');
    });

    try {
      // Test accelerometer access
      motionSensors.accelerometerUpdateInterval = 1000;

      final sub = motionSensors.accelerometer.listen((e) {
        setState(() {
          _lastAcceleration = Vector3(e.x, e.y, e.z);
          _sampleCount++;
          _status = 'Sensors working! Samples: ${_sampleCount.toInt()}';
          _logs.add(
              'Accel: ${e.x.toStringAsFixed(2)}, ${e.y.toStringAsFixed(2)}, ${e.z.toStringAsFixed(2)}');
        });
      });

      // Stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        sub.cancel();
        setState(() {
          _status =
              'Sensor test complete. Samples received: ${_sampleCount.toInt()}';
        });
      });
    } catch (e) {
      setState(() {
        _status = 'Sensor error: $e';
        _logs.add('Error: $e');
      });
    }
  }

  void _startCalibrationTest() {
    setState(() {
      _isCalibrating = true;
      _status = 'Starting calibration test...';
      _logs.clear();
    });

    // Simulate calibration process
    _simulateCalibration();
  }

  Future<void> _simulateCalibration() async {
    setState(() {
      _status = 'Step 1: Capturing reference position...';
      _logs.add('Step 1: Capturing reference position...');
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _status = 'Step 2: Please flex your leg 5-20°...';
      _logs.add('Step 2: Please flex your leg 5-20°...');
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _status = 'Step 3: Analyzing flex data...';
      _logs.add('Step 3: Analyzing flex data...');
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _status = 'Calibration test complete!';
      _logs.add('Calibration test complete!');
      _isCalibrating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calibration Debug'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_lastAcceleration != null)
              Text(
                'Last Acceleration: ${_lastAcceleration!.x.toStringAsFixed(2)}, ${_lastAcceleration!.y.toStringAsFixed(2)}, ${_lastAcceleration!.z.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 10),
            const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
        if (!_isCalibrating)
          ElevatedButton(
            onPressed: _startCalibrationTest,
            child: const Text('Test Calibration'),
          ),
      ],
    );
  }
}
