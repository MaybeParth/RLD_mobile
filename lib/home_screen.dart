import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'dart:math' as math;
import 'dart:async';
import '../db/patient_database.dart';
import '../models/patients.dart';

class HomeScreen extends StatefulWidget {
  final Patient patient;
  const HomeScreen({super.key, required this.patient});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum TestState { idle, calibrating, ready, recording, completed }
enum SignalQuality { poor, fair, good }

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ---------- Sensor & state ----------
  Vector3 _a = Vector3.zero();
  Vector3 _gFiltered = Vector3(0, 0, 1);
  Vector3? _gyro;
  StreamSubscription? _accelSub, _gyroSub;

  // Calibration / plane (persisted per patient)
  Vector3? _gRef;
  Vector3? _planeU, _planeV;
  double _zeroOffsetDeg = 0.0;
  static const double _baselineAngle = 180.0;

  // Angle tracking on 0..180 (180 = extended)
  double? _liveAngleDeg;
  double? _peakDropAngleDeg; // MIN leg angle during trial (deepest drop)

  // Test state & results
  TestState _testState = TestState.idle;
  double? _dropAngle;               // clinical drop = 180 − min(legAngle)
  DateTime? _startTime;
  Duration? _dropTime;
  double? _motorVelocity;

  // Drop event timing
  bool _dropDetected = false;
  bool _reactionDetected = false;
  DateTime? _dropStartAt;
  double? _minLegAngleDeg;
  DateTime? _minAt;

  // Legacy compatibility (kept)
  double? _tiltZ;
  double? _initialAngleZ;
  double? _finalAngleZ;

  // Diagnostics
  int _sampleCount = 0;
  int _sampleRate = 0;
  Timer? _sampleRateTimer;
  SignalQuality _signalQuality = SignalQuality.good;

  // Animations
  AnimationController? _pulseController;
  AnimationController? _recordingController;

  // Filters & constants
  static const double _beta = 0.90;
  static const int _medianWin = 5;
  final List<double> _angleWindow = <double>[];
  static const double _maxPhysicalDeg = 180.0;
  static const double _minValidDropAngle = 10.0;
  static const double _maxValidDropAngle = 90.0;

  // Velocity / noise
  DateTime? _lastAngleT;
  double? _lastAngleDeg;
  double _omegaDegPerSec = 0.0;
  double _accelMag = 1.0; // in g approx (computed)
  double _noiseRmsDeg = 0.8;

  // Adaptive thresholds (auto tuned; defaults below)
  double _omegaDropThreshDegPerSec = 120.0;
  double _omegaReactThreshDegPerSec = 100.0;
  double _accelDipFrac = 0.75;  // |a| < 0.75 g -> onset
  double _accelBumpFrac = 1.10; // |a| > 1.10 g -> reaction

  // Safety
  Timer? _autoStopTimer;
  static const Duration _maxTestDuration = Duration(seconds: 30);

  // ---------- Init / dispose ----------
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

    // Load existing calibration if present for this patient
    _loadCalibrationFromPatient(widget.patient);
  }

  void _startSensors() {
    const int us = 1000; // request ~1kHz
    motionSensors.accelerometerUpdateInterval = us;
    motionSensors.userAccelerometerUpdateInterval = us;
    motionSensors.gyroscopeUpdateInterval = us;

    _accelSub = motionSensors.accelerometer.listen((AccelerometerEvent e) {
      _sampleCount++;

      // Low-pass gravity estimate
      _a.setValues(e.x, e.y, e.z);
      final gNext = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
      if (gNext.length2 != 0) _gFiltered = gNext.normalized();

      _tiltZ = _zTilt(e.x, e.y, e.z);

      // magnitude in g
      final g0 = 9.81;
      final mag = math.sqrt(e.x*e.x + e.y*e.y + e.z*e.z);
      _accelMag = mag / g0;

      _updateLiveAngleAndDetect();
    });

    _gyroSub = motionSensors.gyroscope.listen((g) {
      _gyro = Vector3(g.x, g.y, g.z); // rad/s
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

  // ---------- Math helpers ----------
  Vector3 _unit(Vector3 v) => (v.length2 == 0) ? Vector3(0, 0, 1) : v.normalized();
  double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

  double _zTilt(double ax, double ay, double az) =>
      math.atan(az / math.sqrt(ax * ax + ay * ay)) * 180.0 / math.pi;

  double _angleBetween(Vector3 a, Vector3 b) {
    final d = _clamp(_unit(a).dot(_unit(b)), -1.0, 1.0);
    return math.acos(d) * 180.0 / math.pi;
  }

  // ---------- Sagittal plane angle (ignores left/right wobble) ----------
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

  // ---------- Live angle + event detection ----------
  void _updateLiveAngleAndDetect() {
    if (_gRef == null) {
      setState(() => _liveAngleDeg = null);
      return;
    }

    final leg = _legAngleInPlane(_gFiltered);
    if (leg == null) return;

    final smoothed = _medianSmooth(leg);
    setState(() => _liveAngleDeg = smoothed);

    // angle velocity (deg/s)
    final now = DateTime.now();
    if (_lastAngleT != null && _lastAngleDeg != null) {
      final dt = now.difference(_lastAngleT!).inMicroseconds / 1e6;
      if (dt > 0) _omegaDegPerSec = (smoothed - _lastAngleDeg!) / dt;
    }
    _lastAngleT = now;
    _lastAngleDeg = smoothed;

    // gyro projected onto plane normal (deg/s)
    double gyroInPlaneDeg = 0.0;
    if (_gyro != null && _planeU != null && _planeV != null) {
      final n = _planeU!.cross(_planeV!).normalized();
      gyroInPlaneDeg = _gyro!.dot(n) * 180.0 / math.pi; // rad/s -> deg/s
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
        // update minimum while falling
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

  // ---------- Pre-roll (auto-tune thresholds) ----------
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
        gyroAbs.add(_gyro!.length); // rad/s magnitude
      }
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // estimate derivative RMS
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

    // fidget detection: if gyro is very active, skip auto-raise thresholds
    bool fidgety = false;
    if (gyroAbs.isNotEmpty) {
      // convert to deg/s for check
      final degs = gyroAbs.map((r) => r * 180.0 / math.pi).toList()..sort();
      final p90 = degs[ (degs.length * 0.9).floor().clamp(0, degs.length - 1) ];
      if (p90 > 30.0) { // very active device during pre-roll
        fidgety = true;
      }
    }

    if (!fidgety) {
      _omegaDropThreshDegPerSec = (_noiseRmsDeg * 20.0).clamp(60.0, 160.0);
      _omegaReactThreshDegPerSec = (_noiseRmsDeg * 18.0).clamp(50.0, 140.0);
      final meanMag = mags.reduce((a, b) => a + b) / mags.length; // around ~1.0
      _accelDipFrac = (meanMag - 0.25).clamp(0.55, 0.9);
      _accelBumpFrac = (meanMag + 0.15).clamp(1.02, 1.40);
    } else {
      // fall back to safer defaults and inform user
      _omegaDropThreshDegPerSec = 120.0;
      _omegaReactThreshDegPerSec = 100.0;
      _accelDipFrac = 0.80;
      _accelBumpFrac = 1.12;
      if (mounted) {
        _showSnackBar('Device was moving during pre-roll; using conservative thresholds.', Colors.orange);
      }
    }
  }

  // ---------- Reference capture & plane ----------
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

    // validate flex 5–25°
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

  // ---------- Persistent calibration ----------
  void _loadCalibrationFromPatient(Patient p) {
    if (p.calRefX != null && p.calUX != null && p.calVX != null) {
      _gRef = Vector3(p.calRefX!, p.calRefY!, p.calRefZ!).normalized();
      _planeU = Vector3(p.calUX!, p.calUY!, p.calUZ!).normalized();
      _planeV = Vector3(p.calVX!, p.calVY!, p.calVZ!).normalized();
      _zeroOffsetDeg = p.calZeroOffsetDeg ?? 0.0;
      setState(() {});
    }
  }

  Future<void> _saveCalibrationForPatient() async {
    if (_gRef == null || _planeU == null || _planeV == null) return;
    await PatientDatabase.saveCalibration(
      id: widget.patient.id,
      zeroOffsetDeg: _zeroOffsetDeg,
      ref: [_gRef!.x, _gRef!.y, _gRef!.z],
      u: [_planeU!.x, _planeU!.y, _planeU!.z],
      v: [_planeV!.x, _planeV!.y, _planeV!.z],
    );
  }

  // ---------- Workflow ----------
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

    // First-time calibration? Do it once and persist.
    if (_gRef == null || _planeU == null || _planeV == null) {
      await _captureStableReference(samples: 60);
      final okPlane = await _captureFlexAndBuildPlane(samples: 30);
      if (!okPlane) {
        _showSnackBar('Flex 5–20° without twisting to define the plane, then try again.', Colors.orange);
        setState(() => _testState = TestState.idle);
        return;
      }

      // Auto-offset to show ≈ 180° at extension, plus a manual fine-tune slider (dialog below)
      // The dialog will compute final _zeroOffsetDeg and save calibration.
      _showCalibrationDialog(initialAuto: true);
      return; // calibration dialog will continue flow
    }

    // Already calibrated → start recording
    setState(() {
      _testState = TestState.recording;
      _startTime = DateTime.now();
      _dropDetected = false;
      _reactionDetected = false;
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

      final minLeg = _minLegAngleDeg ?? (_liveAngleDeg ?? 180.0);
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

    final updatedPatient = widget.patient.copyWith(
      initialZ: _initialAngleZ,
      finalZ: _finalAngleZ,
      dropAngle: _dropAngle,
      dropTimeMs: _dropTime?.inMilliseconds.toDouble(),
      motorVelocity: _motorVelocity,
      // keep calibration as-is
    );

    await PatientDatabase.upsertPatient(updatedPatient);
    await PatientDatabase.incrementDropsSinceCal(widget.patient.id);

    if (!mounted) return;
    _showSnackBar('Results saved for ${widget.patient.name}', Colors.green);
  }

  void _resetTest() {
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
      // Keep calibration for this patient
    });
  }

  // ---------- UI helpers ----------
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // === Calibration dialog (with fine-tune slider restored) ===
  void _showCalibrationDialog({bool initialAuto = false}) {
    final currentLeg = _legAngleInPlane(_gFiltered) ?? 180.0;
    // rawInPlane = 180 - currentLeg
    final rawInPlane = 180.0 - currentLeg;

    double fineTune = 0.0; // manual override
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) {
          final previewOffset = (-rawInPlane + fineTune).clamp(-30.0, 30.0);
          final previewLeg = (_baselineAngle - ( (180.0 - currentLeg) + previewOffset )).clamp(0.0, 180.0);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Expanded(child: Text("Calibrate Extended Position")),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text("${previewLeg.toStringAsFixed(1)}°",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 4),
                      const Text("Current Leg Position", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Fine-tune offset (aim for ~180° when fully extended):"),
                Slider(
                  value: fineTune,
                  min: -30.0,
                  max: 30.0,
                  divisions: 60,
                  label: "${fineTune.toStringAsFixed(1)}°",
                  onChanged: (v) => setSB(() => fineTune = v),
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
                        child: Text("${fineTune.toStringAsFixed(1)}°",
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
                    "Keep the device at full extension. After calibrating, flex 5–10° once to define the motion plane.",
                    style: TextStyle(fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetTest();
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // finalize offset and persist calibration
                  setState(() {
                    _zeroOffsetDeg = (-rawInPlane + fineTune).clamp(-30.0, 30.0);
                  });
                  await _saveCalibrationForPatient();
                  Navigator.pop(context);

                  // Now begin recording with tuned thresholds
                  setState(() {
                    _testState = TestState.recording;
                    _startTime = DateTime.now();
                    _dropDetected = false;
                    _reactionDetected = false;
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
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("Calibrate & Start"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- UI (unchanged from your last version) ----------
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
              fontSize: 32,
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
              Text("0°", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text("180°", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
          label: const Text("Start Test"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
            const Text("Calibrating..."),
          ],
        );

      case TestState.ready:
        return const Text("Ready to record...");

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
                        Text("RECORDING", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Text("RECORDING", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text("Stop Recording"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case TestState.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _resetTest,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIndicator(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isValid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green : Colors.orange,
            ),
          ),
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
    // === Your original UI (unchanged) ===
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leg Drop Test'),
        elevation: 0,
        actions: [
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
                              children: [
                                Icon(Icons.trending_down, color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Text("Minimum Angle:", style: TextStyle(fontWeight: FontWeight.bold)),
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

                      const SizedBox(height: 12),
                      if (_dropAngle != null) ...[
                        _buildValidationIndicator("Drop Range", _dropAngle! >= _minValidDropAngle && _dropAngle! <= _maxValidDropAngle),
                        _buildValidationIndicator("Signal Quality", _signalQuality != SignalQuality.poor),
                        _buildValidationIndicator("Time Range", (_dropTime?.inMilliseconds ?? 0) >= 100 && (_dropTime?.inMilliseconds ?? 0) <= 2000),
                      ],
                    ],
                  ),
                ),
              ),

            // Technical Info (Collapsible)
            Card(
              child: ExpansionTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                title: const Text("Technical Details"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Mode: Sagittal-plane (axis-agnostic within plane)"),
                        Text("Sample Rate: $_sampleRate Hz (Target: 1000 Hz)"),
                        Text("Signal Quality: ${_signalQuality.name.toUpperCase()}"),
                        Text("Legacy Z Tilt: ${_tiltZ?.toStringAsFixed(2) ?? '--'}°"),
                        Text("Zero Offset: ${_zeroOffsetDeg.toStringAsFixed(2)}°"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
