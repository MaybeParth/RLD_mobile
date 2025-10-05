import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'dart:math' as math;
import 'dart:async';
import '../bloc/test/test_bloc.dart';
import '../bloc/events/test_events.dart';
import '../models/patients.dart';
import '../models/trial.dart';
import '../db/patient_database.dart';

class SimpleTestScreenBloc extends StatefulWidget {
  final Patient patient;
  const SimpleTestScreenBloc({super.key, required this.patient});

  @override
  State<SimpleTestScreenBloc> createState() => _SimpleTestScreenBlocState();
}

enum TestState { idle, calibrating, ready, recording, completed }
enum SignalQuality { poor, fair, good }

class _SimpleTestScreenBlocState extends State<SimpleTestScreenBloc> with TickerProviderStateMixin {
  
  Vector3 _a = Vector3.zero();
  Vector3 _gFiltered = Vector3(0, 0, 1);
  Vector3? _gyro;
  StreamSubscription? _accelSub, _gyroSub;

  Vector3? _gRef;
  Vector3? _planeU, _planeV;
  double _zeroOffsetDeg = 0.0;
  static const double _baselineAngle = 180.0;

  double? _liveAngleDeg;
  double? _peakDropAngleDeg; 

  TestState _testState = TestState.idle;
  double? _dropAngle;               
  DateTime? _startTime;
  Duration? _dropTime;
  double? _motorVelocity;

  bool _dropDetected = false;
  bool _reactionDetected = false;
  DateTime? _dropStartAt;
  double? _minLegAngleDeg;
  DateTime? _minAt;
  

  double? _tiltZ;
  double? _initialAngleZ;
  double? _finalAngleZ;

  int _sampleCount = 0;
  int _sampleRate = 0;
  Timer? _sampleRateTimer;
  SignalQuality _signalQuality = SignalQuality.good;

  AnimationController? _pulseController;
  AnimationController? _recordingController;

  double _beta = 0.85;
  static const int _medianWin = 5;
  final List<double> _angleWindow = <double>[];
  static const double _maxPhysicalDeg = 180.0;

  DateTime? _lastAngleT;
  double? _lastAngleDeg;
  DateTime? _lastUiUpdate;
  static const Duration _uiUpdateInterval = Duration(milliseconds: 16); // ~60 FPS
  double _omegaDegPerSec = 0.0;
  double _accelMag = 1.0; 
  double _noiseRmsDeg = 0.8;

  double _omegaDropThreshDegPerSec = 120.0;
  double _omegaReactThreshDegPerSec = 100.0;
  double _accelDipFrac = 0.75;  
  double _accelBumpFrac = 1.10; 

  Timer? _autoStopTimer;
  static const Duration _maxTestDuration = Duration(seconds: 30);

  // Trial management
  List<Trial> _keptTrials = [];
  bool _trialDialogShown = false;
  
  // Calibration slider
  bool _showCalibrationSlider = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _requestMaxRate();
    _initializeSampleRateMonitoring();
    _startSensors();

    _loadCalibrationFromPatient(widget.patient);
    _loadKeptTrials();
  }

  void _startSensors() {
    const int us = 1000; 
    motionSensors.accelerometerUpdateInterval = us;
    motionSensors.userAccelerometerUpdateInterval = us;
    motionSensors.gyroscopeUpdateInterval = us;

    _accelSub = motionSensors.accelerometer.listen((AccelerometerEvent e) {
      _sampleCount++;

      _a.setValues(e.x, e.y, e.z);
      final gNext = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
      if (gNext.length2 != 0) _gFiltered = gNext.normalized();

      _tiltZ = _zTilt(e.x, e.y, e.z);

      final g0 = 9.81;
      final mag = math.sqrt(e.x*e.x + e.y*e.y + e.z*e.z);
      _accelMag = mag / g0;

      _updateLiveAngleAndDetect();
    });

    _gyroSub = motionSensors.gyroscope.listen((g) {
      _gyro = Vector3(g.x, g.y, g.z);
    });
  }

  @override
  void dispose() {
    _sampleRateTimer?.cancel();
    _autoStopTimer?.cancel();
    _pulseController?.dispose();
    _recordingController?.dispose();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  void _initializeSampleRateMonitoring() {
    _sampleRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _sampleRate = _sampleCount;
        _sampleCount = 0;

        if (_sampleRate < 100) {
          _signalQuality = SignalQuality.poor;
        } else if (_sampleRate < 500) {
          _signalQuality = SignalQuality.fair;
        } else {
          _signalQuality = SignalQuality.good;
        }
      });
    });
  }

  Vector3 _unit(Vector3 v) => (v.length2 == 0) ? Vector3(0, 0, 1) : v.normalized();
  double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

  double _zTilt(double ax, double ay, double az) =>
      math.atan(az / math.sqrt(ax * ax + ay * ay)) * 180.0 / math.pi;

  double _angleBetween(Vector3 a, Vector3 b) {
    final d = _clamp(_unit(a).dot(_unit(b)), -1.0, 1.0);
    return math.acos(d) * 180.0 / math.pi;
  }

  double? _legAngleInPlane(Vector3 gCur) {
    if (_gRef == null || _planeU == null || _planeV == null) return null;

    final ref = _gRef!;
    final refU = ref.dot(_planeU!);
    final refV = ref.dot(_planeV!);
    final curU = gCur.dot(_planeU!);
    final curV = gCur.dot(_planeV!);

    final ref2 = math.sqrt(refU*refU + refV*refV);
    final cur2 = math.sqrt(curU*curU + curV*curV);
    if (ref2 == 0 || cur2 == 0) return null;

    final rU = refU / ref2, rV = refV / ref2;
    final cU = curU / cur2, cV = curV / cur2;

    final dot2 = _clamp(rU*cU + rV*cV, -1.0, 1.0);
    final rawInPlane = math.acos(dot2) * 180.0 / math.pi;

    final leg = (_baselineAngle - (rawInPlane + _zeroOffsetDeg)).clamp(0.0, 180.0);
    return leg;
  }

  double _medianSmooth(double v) {
    _angleWindow.add(v);
    if (_angleWindow.length > _medianWin) _angleWindow.removeAt(0);
    final sorted = List<double>.from(_angleWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }

  Future<void> _quickRecalibrateToCurrent180() async {
    if (_gRef == null) {
      _showSnackBar('Calibrate baseline first, then retry.', Colors.orange);
      return;
    }
    final current = _directLegAngle(_gFiltered);
    if (current == null) return;
    final correction = 180.0 - current;
    setState(() {
      _zeroOffsetDeg = (_zeroOffsetDeg + correction).clamp(-30.0, 30.0);
    });
    await _saveCalibrationToDatabase();
    _showSnackBar('Recalibrated: set current as 180°', Colors.green);
  }

  Future<void> _fullRecalibrateBaselineAndPlane() async {
    try {
      await _captureStableReference(samples: 60);
      final okPlane = await _captureFlexAndBuildPlane(samples: 30);
      if (!okPlane) {
        _showSnackBar('Flex 5–20° without twisting to define the plane, then try again.', Colors.orange);
        setState(() => _testState = TestState.idle);
        return;
      }
      await _saveCalibrationForPatient();
      await _saveCalibrationToDatabase();
      _showSnackBar('Baseline and plane recalibrated.', Colors.green);
    } catch (e) {
      _showSnackBar('Recalibration failed: $e', Colors.red);
    }
  }

  void _showRecalibrateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recalibrate Start Angle'),
        content: const Text('Choose how you want to recalibrate.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _quickRecalibrateToCurrent180();
            },
            child: const Text('Set current as 180°'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _fullRecalibrateBaselineAndPlane();
            },
            child: const Text('Full recalibrate'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Ensure reference is correctly oriented and the current extended position reads ~180°
  

  // Fallback: direct angle between current gravity and reference when plane is unreliable
  double? _directLegAngle(Vector3 gCur) {
    if (_gRef == null) return null;
    final raw = _angleBetween(_gRef!, gCur);
    return (_baselineAngle - (raw + _zeroOffsetDeg)).clamp(0.0, 180.0);
  }

  void _updateLiveAngleAndDetect() {
    if (_gRef == null) {
      setState(() => _liveAngleDeg = null);
      return;
    }

    // Compute leg angle strictly within the calibrated plane; ignore out-of-plane wobble
    final double? legPlane = _legAngleInPlane(_gFiltered);
    double? leg = legPlane;
    if (leg == null) {
      setState(() => _liveAngleDeg = null);
      return;
    }

    final smoothed = _medianSmooth(leg);
    // Throttle UI updates and ignore unrealistic display jumps to improve perceived stability
    final now = DateTime.now();
    final allowUi = _lastUiUpdate == null || now.difference(_lastUiUpdate!) >= _uiUpdateInterval || _testState == TestState.recording;
    final prev = _liveAngleDeg;
    final jumpOk = _testState == TestState.recording || prev == null || (smoothed - prev).abs() <= 15.0; // no jump suppression during recording
    if (allowUi && jumpOk) {
      _lastUiUpdate = now;
      setState(() {
        _liveAngleDeg = smoothed;
      });
    } else {
      // keep internal for detection regardless of UI throttle
      _liveAngleDeg = smoothed;
    }

    // reuse 'now' defined above
    if (_lastAngleT != null && _lastAngleDeg != null) {
      final dt = now.difference(_lastAngleT!).inMicroseconds / 1e6;
      if (dt > 0) {
        _omegaDegPerSec = (smoothed - _lastAngleDeg!) / dt;
      }
    }
    _lastAngleT = now;
    _lastAngleDeg = smoothed;

    double gyroInPlaneDeg = 0.0;
    if (_gyro != null && _planeU != null && _planeV != null) {
      final n = _planeU!.cross(_planeV!).normalized();
      gyroInPlaneDeg = _gyro!.dot(n) * 180.0 / math.pi;
    }

    if (_testState == TestState.recording) {
      if (!_dropDetected) {
        final fastDown = gyroInPlaneDeg < -_omegaDropThreshDegPerSec;
        final accelDip = _accelMag < _accelDipFrac;
        final fallbackFast = _omegaDegPerSec < -(_omegaDropThreshDegPerSec * 0.7);

        if ((fastDown && accelDip) || (fallbackFast && accelDip)) {
          _dropDetected = true;
          _dropStartAt = now;
          _minLegAngleDeg = smoothed;
          _minAt = now;
        }
      } else if (!_reactionDetected) {
        if (_minLegAngleDeg == null || smoothed < _minLegAngleDeg!) {
          _minLegAngleDeg = smoothed;
          _minAt = now;
        }

        final fastUp = gyroInPlaneDeg > _omegaReactThreshDegPerSec;
        final accelBump = _accelMag > _accelBumpFrac;
        final fallbackUp = _omegaDegPerSec > (_omegaReactThreshDegPerSec * 0.5);

        if ((fastUp && accelBump) || (fallbackUp && accelBump)) {
          _reactionDetected = true;
          _peakDropAngleDeg = _minLegAngleDeg;
          _stopRecording();
        }
      }
    }
  }

  Future<void> _preRollNoiseCharacterization({int ms = 500}) async {
    final angles = <double>[];
    final mags = <double>[];
    final gyroAbs = <double>[];

    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < ms) {
      final leg = _legAngleInPlane(_gFiltered) ?? 180.0;
      angles.add(leg);
      mags.add(_accelMag);
      if (_gyro != null) {
        gyroAbs.add(_gyro!.length);
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }

    final n = angles.length;
    if (n >= 2) {
      final dtSec = (ms / math.max(1, n)) / 1000.0;
      final deriv = <double>[];
      for (int i = 1; i < n; i++) {
        deriv.add((angles[i] - angles[i - 1]) / dtSec);
      }
      final meanSq = deriv.map((d) => d * d).reduce((a, b) => a + b) / deriv.length;
      _noiseRmsDeg = math.sqrt(meanSq).clamp(0.3, 3.0);
    } else {
      _noiseRmsDeg = 1.0;
    }

    bool fidgety = false;
    if (gyroAbs.isNotEmpty) {
      final degs = gyroAbs.map((r) => r * 180.0 / math.pi).toList()..sort();
      final p90 = degs[ (degs.length * 0.9).floor().clamp(0, degs.length - 1) ];
      if (p90 > 30.0) {
        fidgety = true;
      }
    }

    if (!fidgety) {
      _omegaDropThreshDegPerSec = (_noiseRmsDeg * 20.0).clamp(60.0, 160.0);
      _omegaReactThreshDegPerSec = (_noiseRmsDeg * 18.0).clamp(50.0, 140.0);
      final meanMag = mags.reduce((a, b) => a + b) / mags.length;
      _accelDipFrac = (meanMag - 0.25).clamp(0.55, 0.9);
      _accelBumpFrac = (meanMag + 0.15).clamp(1.02, 1.40);
    } else {
      _omegaDropThreshDegPerSec = 120.0;
      _omegaReactThreshDegPerSec = 100.0;
      _accelDipFrac = 0.80;
      _accelBumpFrac = 1.12;
      if (mounted) {
        _showSnackBar('Device was moving during pre-roll; using conservative thresholds.', Colors.orange);
      }
    }
  }

  Future<void> _captureStableReference({int samples = 60}) async {
    Vector3 sum = Vector3.zero();
    int got = 0;
    setState(() => _testState = TestState.calibrating);

    await Future.delayed(const Duration(milliseconds: 300));

    final c = Completer<void>();
    final sub = motionSensors.accelerometer.listen((e) {
      final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
      if (next.length2 != 0) {
        _gFiltered = next.normalized();
        sum += _gFiltered;
        got++;
        if (got >= samples && !c.isCompleted) c.complete();
      }
    });

    await c.future;
    await sub.cancel();

    _gRef = _unit(sum / got.toDouble());
    setState(() => _testState = TestState.ready);
  }

  Future<bool> _captureFlexAndBuildPlane({int samples = 30}) async {
    Vector3 sum = Vector3.zero();
    int got = 0;

    await Future.delayed(const Duration(milliseconds: 200));

    final c = Completer<void>();
    final sub = motionSensors.accelerometer.listen((e) {
      final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
      if (next.length2 != 0) {
        _gFiltered = next.normalized();
        sum += _gFiltered;
        got++;
        if (got >= samples && !c.isCompleted) c.complete();
      }
    });

    await c.future;
    await sub.cancel();

    final gFlex = _unit(sum / got.toDouble());
    if (_gRef == null) return false;

    final delta = _angleBetween(_gRef!, gFlex);
    if (delta < 5.0 || delta > 25.0) return false;

    final n = _gRef!.cross(gFlex);
    if (n.length2 == 0) return false;
    final planeN = n.normalized();

    final tmp = (gFlex - _gRef! * _gRef!.dot(gFlex));
    if (tmp.length2 == 0) return false;

    _planeU = tmp.normalized();
    _planeV = planeN.cross(_planeU!).normalized();
    return true;
  }

  Future<void> _loadCalibrationFromPatient(Patient p) async {
    try {
      // Get fresh patient data from database
      final freshPatient = await PatientDatabase.getPatient(p.id);
      if (freshPatient != null) {
        if (freshPatient.calRefX != null && freshPatient.calUX != null && freshPatient.calVX != null) {
          _gRef = Vector3(freshPatient.calRefX!, freshPatient.calRefY!, freshPatient.calRefZ!).normalized();
          _planeU = Vector3(freshPatient.calUX!, freshPatient.calUY!, freshPatient.calUZ!).normalized();
          _planeV = Vector3(freshPatient.calVX!, freshPatient.calVY!, freshPatient.calVZ!).normalized();
          final loaded = freshPatient.calZeroOffsetDeg ?? 0.0;
          _zeroOffsetDeg = loaded.clamp(-30.0, 30.0);
          setState(() {});
        }
      }
    } catch (e) {
      // print('Error loading calibration: $e');
    }
  }

  Future<void> _loadKeptTrials() async {
    try {
      final updatedPatient = await PatientDatabase.getPatient(widget.patient.id);
      if (updatedPatient != null) {
        // Sort kept trials newest-first (stack behavior)
        final kept = List<Trial>.from(updatedPatient.keptTrials)
          ..sort((a, b) {
            final at = a.timestamp;
            final bt = b.timestamp;
            if (at != null && bt != null) return bt.compareTo(at);
            return b.id.compareTo(a.id);
          });
        setState(() {
          _keptTrials = kept;
        });
      }
    } catch (e) {
      // print('Error loading kept trials: $e');
    }
  }


  void _toggleCalibrationSlider() {
    setState(() {
      _showCalibrationSlider = !_showCalibrationSlider;
    });
  }

  void _adjustCalibration(double newOffset) async {
    // print('Adjusting calibration to: $newOffset');
    setState(() {
      _zeroOffsetDeg = newOffset;
    });
    // Save calibration to database
    await _saveCalibrationToDatabase();
  }

  Future<void> _saveCalibrationToDatabase() async {
    try {
      // Initialize calibration vectors if they don't exist
      if (_gRef == null) {
        _gRef = Vector3(0, 0, -1); // Default gravity reference
      }
      if (_planeU == null) {
        _planeU = Vector3(1, 0, 0); // Default plane U
      }
      if (_planeV == null) {
        _planeV = Vector3(0, 1, 0); // Default plane V
      }
      
      await PatientDatabase.saveCalibration(
        id: widget.patient.id,
        zeroOffsetDeg: _zeroOffsetDeg,
        ref: [_gRef!.x, _gRef!.y, _gRef!.z],
        u: [_planeU!.x, _planeU!.y, _planeU!.z],
        v: [_planeV!.x, _planeV!.y, _planeV!.z],
      );
      // print('Calibration saved: offset=${_zeroOffsetDeg.toStringAsFixed(2)}°');
    } catch (e) {
      // print('Error saving calibration: $e');
    }
  }

  Future<void> _saveCalibrationForPatient() async {
    if (_gRef == null || _planeU == null || _planeV == null) return;
    // Save calibration via BLoC
    context.read<TestBloc>().add(CalibrationComplete(
      gRef: _gRef!,
      planeU: _planeU!,
      planeV: _planeV!,
      zeroOffsetDeg: _zeroOffsetDeg,
    ));
  }

  void _requestMaxRate() {
    const int us = 1000;
    motionSensors.accelerometerUpdateInterval = us;
    motionSensors.userAccelerometerUpdateInterval = us;
    motionSensors.gyroscopeUpdateInterval = us;
    motionSensors.magnetometerUpdateInterval = 20000;
    motionSensors.orientationUpdateInterval = 20000;
    motionSensors.absoluteOrientationUpdateInterval = 20000;
  }

  

  Future<void> _startTest() async {
    if (_testState != TestState.idle) return;

    if (_gRef == null || _planeU == null || _planeV == null) {
      await _captureStableReference(samples: 60);
      final okPlane = await _captureFlexAndBuildPlane(samples: 30);
      if (!okPlane) {
        _showSnackBar('Flex 5–20° without twisting to define the plane, then try again.', Colors.orange);
        setState(() => _testState = TestState.idle);
        return;
      }

      await _saveCalibrationForPatient();
    }

    // Keep calibration fixed across tests; do not auto-adjust here

    setState(() {
      _testState = TestState.recording;
      _startTime = DateTime.now();
      
      _beta = 0.80; // slightly more responsive during recording
      _dropDetected = false;
      _reactionDetected = false;
      _trialDialogShown = false;
      _peakDropAngleDeg = 180.0;
      _minLegAngleDeg = _liveAngleDeg ?? 180.0;
      _minAt = _startTime;
      _dropStartAt = null;
      _angleWindow.clear();
    });

    await _preRollNoiseCharacterization();

    _autoStopTimer = Timer(_maxTestDuration, () {
      if (_testState == TestState.recording) {
        _stopRecording();
        _showSnackBar('Test auto-stopped after ${_maxTestDuration.inSeconds}s', Colors.orange);
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_testState != TestState.recording) return;

    _autoStopTimer?.cancel();

    setState(() {
      _testState = TestState.completed;
      _finalAngleZ = _tiltZ;

      // Use only the in-plane minimum angle for drop angle reporting
      final double minLeg = _minLegAngleDeg ?? (_liveAngleDeg ?? 180.0);
      _dropAngle = (_baselineAngle - minLeg).clamp(0.0, _maxPhysicalDeg);

      if (_dropStartAt != null && _minAt != null) {
        _dropTime = _minAt!.difference(_dropStartAt!);
      } else if (_startTime != null && _minAt != null) {
        _dropTime = _minAt!.difference(_startTime!);
      }

      final seconds = (_dropTime?.inMilliseconds ?? 0) / 1000.0;
      if (seconds > 0 && _dropAngle != null) {
        _motorVelocity = _dropAngle! / seconds;
      }
    });

    // Create trial and show decision dialog
    final trial = Trial(
      id: 'trial_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      initialZ: _initialAngleZ,
      finalZ: _finalAngleZ,
      dropAngle: _dropAngle,
      dropTimeMs: _dropTime?.inMilliseconds.toDouble(),
      motorVelocity: _motorVelocity,
      peakDropAngle: _peakDropAngleDeg,
    );

    if (!_trialDialogShown) {
      _trialDialogShown = true;
      _showTrialDecisionDialog(trial);
    }
  }

  void _showTrialDecisionDialog(Trial trial) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Trial Complete!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Trial results
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Drop Angle:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        Text(
                          '${trial.dropAngle?.toStringAsFixed(1) ?? 'N/A'}°',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Drop Time:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        Text(
                          '${trial.dropTimeMs?.toStringAsFixed(0) ?? 'N/A'}ms',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    if (trial.motorVelocity != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Motor Velocity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                          Text(
                            '${trial.motorVelocity!.toStringAsFixed(1)}°/s',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Would you like to keep this trial for analysis?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: double.infinity),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 480;
                    if (isWide) {
                      return SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              fit: FlexFit.tight,
                              flex: 1,
                              child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _handleTrialDecision(trial, false);
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Discard', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              fit: FlexFit.tight,
                              flex: 1,
                              child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _handleTrialDecision(trial, true);
                            },
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: const Text('Keep Trial', style: TextStyle(color: Colors.white, fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _handleTrialDecision(trial, false);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Discard', style: TextStyle(color: Colors.red, fontSize: 18)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _handleTrialDecision(trial, true);
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Keep Trial', style: TextStyle(color: Colors.white, fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    );
                  },
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTrialDecision(Trial trial, bool isKept, {String? notes}) async {
    // print('Handling trial decision: isKept=$isKept');
    try {
      // Add trial to database
      // print('Adding trial to database...');
      await PatientDatabase.addTrialToPatient(widget.patient.id, trial);
      
      if (isKept) {
        // Update trial status to kept
        // print('Updating trial status to kept...');
        await PatientDatabase.updateTrialStatus(widget.patient.id, trial.id, true, notes: notes);
        _showSnackBar(notes != null ? 'Trial kept with notes and saved' : 'Trial kept and saved', Colors.green);
      } else {
        // Update trial status to discarded
        // print('Updating trial status to discarded...');
        await PatientDatabase.updateTrialStatus(widget.patient.id, trial.id, false, discardReason: 'User discarded');
        _showSnackBar('Trial discarded', Colors.orange);
      }
      
      // Refresh kept trials and reset test for next trial
      // print('Refreshing kept trials and resetting test...');
      await _loadKeptTrials();
      _resetTestForNextTrial();
      // print('Trial decision handling complete - staying on test screen');
      
    } catch (e) {
      // print('Error in trial decision: $e');
      _showSnackBar('Error saving trial: $e', Colors.red);
    }
  }

  void _resetTestForNextTrial() {
    _autoStopTimer?.cancel();
    setState(() {
      _testState = TestState.idle;
      _liveAngleDeg = null;
      _peakDropAngleDeg = null;
      _dropAngle = null;
      _dropTime = null;
      _motorVelocity = null;
      _dropDetected = false;
      _reactionDetected = false;
      _startTime = null;
      _minAt = null;
      _dropStartAt = null;
      _angleWindow.clear();
      _beta = 0.85;
    });
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAngleGauge() {
    final angle = _liveAngleDeg ?? 180.0;
    final maxAngle = 180.0;
    final progress = (angle / maxAngle).clamp(0.0, 1.0);

    Color gaugeColor = Colors.red;
    if (angle > 120) gaugeColor = Colors.orange;
    if (angle > 150) gaugeColor = Colors.green;

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            "${angle.toStringAsFixed(1)}°",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: gaugeColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0°", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text("180°", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestControls() {
    switch (_testState) {
      case TestState.idle:
        return ElevatedButton.icon(
          onPressed: _startTest,
          icon: const Icon(Icons.play_arrow),
          label: const Text(
            "Start Test",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

      case TestState.calibrating:
        return Column(
          children: [
            if (_pulseController != null)
              AnimatedBuilder(
                animation: _pulseController!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController!.value * 0.1),
                    child: const CircularProgressIndicator(),
                  );
                },
              )
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text(
              "Calibrating...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        );

      case TestState.ready:
        return const Text(
          "Ready to record...",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        );

      case TestState.recording:
        return Column(
          children: [
            if (_recordingController != null)
              AnimatedBuilder(
                animation: _recordingController!,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1 + (_recordingController!.value * 0.2)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.red),
                        SizedBox(width: 8),
                        Text("RECORDING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    SizedBox(width: 8),
                    Text("RECORDING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text(
                "Stop Recording",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );

      case TestState.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _resetTestForNextTrial,
              icon: const Icon(Icons.refresh),
              label: const Text("New Test"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialItem(Trial trial) {
    // Simple kept trial card showing only Drop angle, Motor velocity, and Drop time
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  'Drop angle: ${trial.dropAngle?.toStringAsFixed(1) ?? 'N/A'}°',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                trial.formattedTimestamp,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 360) {
                return Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: _miniMetric('Motor velocity',
                          trial.motorVelocity != null ? '${trial.motorVelocity!.toStringAsFixed(1)}°/s' : 'N/A'),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.tight,
                      child: _miniMetric('Drop time',
                          trial.dropTimeMs != null ? '${trial.dropTimeMs!.toStringAsFixed(0)} ms' : 'N/A'),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniMetric('Motor velocity',
                      trial.motorVelocity != null ? '${trial.motorVelocity!.toStringAsFixed(1)}°/s' : 'N/A'),
                  const SizedBox(height: 6),
                  _miniMetric('Drop time',
                      trial.dropTimeMs != null ? '${trial.dropTimeMs!.toStringAsFixed(0)} ms' : 'N/A'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  

  Widget _buildSignalQuality() {
    Color qualityColor;
    IconData qualityIcon;

    switch (_signalQuality) {
      case SignalQuality.poor:
        qualityColor = Colors.red;
        qualityIcon = Icons.signal_cellular_connected_no_internet_0_bar;
        break;
      case SignalQuality.fair:
        qualityColor = Colors.orange;
        qualityIcon = Icons.signal_cellular_alt;
        break;
      case SignalQuality.good:
        qualityColor = Colors.green;
        qualityIcon = Icons.signal_cellular_4_bar;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: qualityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: qualityColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(qualityIcon, size: 16, color: qualityColor),
          const SizedBox(width: 4),
          Text(
            "$_sampleRate Hz",
            style: TextStyle(color: qualityColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leg Drop Test',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalibrate Start Angle',
            onPressed: _showRecalibrateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Fine-tune Calibration',
            onPressed: _toggleCalibrationSlider,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildSignalQuality(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Patient Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              widget.patient.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.patient.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "ID: ${widget.patient.id} • Age: ${widget.patient.age} • ${widget.patient.gender}",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (widget.patient.condition.isNotEmpty)
                                  Text(
                                    "Condition: ${widget.patient.condition}",
                                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Calibration Slider
            if (_showCalibrationSlider) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text("Fine-tune Calibration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${(_liveAngleDeg ?? 0.0).toStringAsFixed(1)}°",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            const Text("Current Live Angle", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Adjust offset to make current angle read 180°:"),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Slider(
                            value: _zeroOffsetDeg,
                            min: -30.0,
                            max: 30.0,
                            divisions: 120,
                            label: "${_zeroOffsetDeg.toStringAsFixed(1)}°",
                            onChanged: _adjustCalibration,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("-30°", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Text("${_zeroOffsetDeg.toStringAsFixed(1)}°",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Text("+30°", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Text(
                          "Adjust the slider until the live angle shows 180° when your leg is fully extended.",
                          style: TextStyle(fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _saveCalibrationToDatabase();
                            if (mounted) {
                              setState(() { _showCalibrationSlider = false; });
                              _showSnackBar('Calibration saved', Colors.green);
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Angle Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rotate_right, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text("Live Angle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    _buildAngleGauge(),

                    if (_testState == TestState.recording || _peakDropAngleDeg != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.trending_down, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    "Minimum Angle:",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "${_peakDropAngleDeg?.toStringAsFixed(1) ?? '--'}°",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Text("Test Control", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTestControls(),
                  ],
                ),
              ),
            ),

            // Kept Trials Section
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            "Kept Trials (${_keptTrials.length})",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_keptTrials.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                'No kept trials yet. Complete tests and choose to keep them.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._keptTrials.map((trial) => _buildTrialItem(trial)),
                  ],
                ),
              ),
            ),

            // Results Display
            if (_testState == TestState.completed || _dropAngle != null || widget.patient.dropAngle != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text("Test Results", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow("Drop Angle", "${_dropAngle?.toStringAsFixed(2) ?? widget.patient.dropAngle?.toStringAsFixed(2) ?? '--'}°", Colors.red),
                      _buildResultRow("Minimum Angle", "${_peakDropAngleDeg?.toStringAsFixed(2) ?? '--'}°", Colors.blue),
                      _buildResultRow("Drop Time", "${_dropTime?.inMilliseconds ?? widget.patient.dropTimeMs?.toInt() ?? '--'} ms", Colors.orange),
                      _buildResultRow("Motor Velocity", "${_motorVelocity?.toStringAsFixed(2) ?? widget.patient.motorVelocity?.toStringAsFixed(2) ?? '--'} °/s", Colors.green),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
