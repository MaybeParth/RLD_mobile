// home_screen.dart
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'dart:math' as math;
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Vector3 _accelerometer = Vector3.zero();
  double? _tiltX, _tiltY, _tiltZ;

  double? _initialAngleZ;
  double? _finalAngleZ;
  double? _dropAngle;
  DateTime? _startTime;
  DateTime? _endTime;
  Duration? _dropTime;
  double? _motorVelocity;

  double _angleOffset = 0.0;

  int? _groupValue = 0;

  int _sampleCount = 0;
  int _sampleRate = 0;
  Timer? _sampleRateTimer;

  @override
  void initState() {
    super.initState();

    _sampleRateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _sampleRate = _sampleCount;
        _sampleCount = 0;
      });
    });

    motionSensors.accelerometer.listen((AccelerometerEvent event) {
      _sampleCount++;
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
        _tiltX = _calculateXAxisTilt(event.x, event.y, event.z);
        _tiltY = _calculateYAxisTilt(event.x, event.y, event.z);
        _tiltZ = _calculateZAxisTilt(event.x, event.y, event.z) + _angleOffset;
      });
    });
  }

  @override
  void dispose() {
    _sampleRateTimer?.cancel();
    super.dispose();
  }

  double _calculateXAxisTilt(double ax, double ay, double az) {
    return math.atan(ax / math.sqrt(ay * ay + az * az)) * 180 / math.pi;
  }

  double _calculateYAxisTilt(double ax, double ay, double az) {
    return math.atan(ay / math.sqrt(ax * ax + az * az)) * 180 / math.pi;
  }

  double _calculateZAxisTilt(double ax, double ay, double az) {
    return math.atan(az / math.sqrt(ax * ax + ay * ay)) * 180 / math.pi;
  }

  void freezeInitialAngle() {
    setState(() {
      _initialAngleZ = _tiltZ;
      _startTime = DateTime.now();
    });
  }

  void freezeFinalAngle() {
    setState(() {
      _finalAngleZ = _tiltZ;
      _endTime = DateTime.now();

      if (_initialAngleZ != null && _finalAngleZ != null && _startTime != null && _endTime != null) {
        _dropAngle = (_finalAngleZ! - _initialAngleZ!).abs();
        _dropTime = _endTime!.difference(_startTime!);

        final seconds = _dropTime!.inMilliseconds / 1000;
        if (seconds > 0) {
          _motorVelocity = _dropAngle! / seconds;
        }
      }
    });
  }

  void calibrateAngle() {
    showDialog(
      context: context,
      builder: (context) {
        double current = _tiltZ ?? 0;
        double adjusted = current;
        return AlertDialog(
          title: Text("Calibrate Angle"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Current Angle: ${current.toStringAsFixed(2)}°"),
              Text("Select Correct Angle:"),
              Slider(
                value: adjusted,
                min: 0,
                max: 200,
                onChanged: (val) {
                  setState(() {
                    adjusted = val;
                  });
                },
              ),
              Text("Adjusted to: ${adjusted.toStringAsFixed(2)}°"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _angleOffset = adjusted - current;
                });
                Navigator.pop(context);
              },
              child: Text("Set Offset"),
            ),
          ],
        );
      },
    );
  }

  void setUpdateInterval(int? groupValue, int interval) {
    motionSensors.accelerometerUpdateInterval = interval;
    motionSensors.userAccelerometerUpdateInterval = interval;
    motionSensors.gyroscopeUpdateInterval = interval;
    motionSensors.magnetometerUpdateInterval = interval;
    motionSensors.orientationUpdateInterval = interval;
    motionSensors.absoluteOrientationUpdateInterval = interval;
    setState(() {
      _groupValue = groupValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reactive Leg Drop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                ElevatedButton(
                  onPressed: calibrateAngle,
                  child: Text("Calibrate"),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: freezeInitialAngle,
                  child: Text("Start Drop"),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: freezeFinalAngle,
                  child: Text("End Drop"),
                ),
              ],
            ),
            Divider(),
            Text("Initial Z Tilt: ${_initialAngleZ?.toStringAsFixed(2) ?? '--'}°"),
            Text("Final Z Tilt: ${_finalAngleZ?.toStringAsFixed(2) ?? '--'}°"),
            Text("Drop Angle: ${_dropAngle?.toStringAsFixed(2) ?? '--'}°"),
            Text("Drop Time: ${_dropTime?.inMilliseconds ?? '--'} ms"),
            Text("Motor Velocity: ${_motorVelocity?.toStringAsFixed(2) ?? '--'} °/s"),
            Divider(),
            Text("Live Z Tilt: ${_tiltZ?.toStringAsFixed(2) ?? '--'}°"),
            Text("Sample Rate: $_sampleRate samples/sec"),
          ],
        ),
      ),
    );
  }
}
