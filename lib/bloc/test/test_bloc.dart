import 'dart:async';
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import '../events/test_events.dart';
import '../states/test_states.dart';
import '../../models/trial.dart';

class TestBloc extends Bloc<TestEvent, TestState> {
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  Timer? _sampleRateTimer;
  Timer? _autoStopTimer;
  
  // Sensor data
  Vector3 _a = Vector3.zero();
  Vector3 _gFiltered = Vector3(0, 0, 1);
  Vector3? _gyro;
  
  // Angle tracking for velocity calculation
  double? _lastAngle;
  DateTime? _lastAngleTime;
  int _sampleCount = 0;
  int _sampleRate = 0;
  
  // Calibration constants
  static const double _beta = 0.95;  // Increased for more stability
  static const int _medianWin = 7;   // Increased window for better smoothing
  static const Duration _maxTestDuration = Duration(seconds: 30);
  
  // Angle tracking
  final List<double> _angleWindow = <double>[];
  double _omegaDegPerSec = 0.0;
  double _accelMag = 1.0;
  
  // Advanced filtering for consistency
  final List<double> _angleHistory = <double>[];  // Extended history for better filtering
  static const int _historySize = 20;  // Keep more history for better analysis
  
  // Consistency tracking
  double _angleVariance = 0.0;  // Current angle variance
  List<double> _recentDrops = <double>[];  // Track recent drop measurements for consistency
  
  // Adaptive thresholds
  double _omegaDropThreshDegPerSec = 120.0;
  double _omegaReactThreshDegPerSec = 100.0;
  double _accelDipFrac = 0.75;
  double _accelBumpFrac = 1.10;
  
  TestBloc() : super(const TestState()) {
    on<InitializeTest>(_onInitializeTest);
    on<StartCalibration>(_onStartCalibration);
    on<CalibrationComplete>(_onCalibrationComplete);
    on<StartTest>(_onStartTest);
    on<UpdateSensorData>(_onUpdateSensorData);
    on<DetectDrop>(_onDetectDrop);
    on<DetectReaction>(_onDetectReaction);
    on<StopTest>(_onStopTest);
    on<ResetTest>(_onResetTest);
    on<SaveTestResults>(_onSaveTestResults);
    on<StartNewTrial>(_onStartNewTrial);
    on<EndTesting>(_onEndTesting);
    on<KeepTrial>(_onKeepTrial);
    on<DiscardTrial>(_onDiscardTrial);
    on<SetCustomBaselineAngle>(_onSetCustomBaselineAngle);
    on<AdjustCalibration>(_onAdjustCalibration);
    on<SetManualBaseline>(_onSetManualBaseline);
  }

  @override
  Future<void> close() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _sampleRateTimer?.cancel();
    _autoStopTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitializeTest(InitializeTest event, Emitter<TestState> emit) async {
    emit(state.copyWith(status: TestStatus.idle));
    _startSensors();
    _initializeSampleRateMonitoring();
  }

  Future<void> _onStartCalibration(StartCalibration event, Emitter<TestState> emit) async {
    emit(state.copyWith(
      status: TestStatus.calibrating,
      errorMessage: null, // Clear any previous errors
    ));
    
    try {
      // Wait a moment for sensors to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Capture stable reference
      final gRef = await _captureStableReference();
      print('🔍 Calibration: gRef captured = $gRef');
      emit(state.copyWith(gRef: gRef));
      
      // Wait a moment before flex capture
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Capture flex and build plane
      final planeData = await _captureFlexAndBuildPlane();
      if (planeData != null) {
        print('🔍 Calibration: planeU = ${planeData['u']}, planeV = ${planeData['v']}');
        
        // After plane definition, we need to capture the baseline angle
        // This is where the user sets their own starting position
        final baselineAngle = await _captureBaselineAngle();
        
        emit(state.copyWith(
          planeU: planeData['u'],
          planeV: planeData['v'],
          customBaselineAngle: baselineAngle,
          status: TestStatus.ready,
          errorMessage: null, // Clear any errors on success
        ));
        print('🔍 Calibration: Complete! Baseline angle set to ${baselineAngle.toStringAsFixed(1)}°. Ready for testing.');
      } else {
        print('❌ Calibration: Failed to build plane');
        emit(state.copyWith(
          status: TestStatus.idle,
          errorMessage: 'Calibration failed. Please ensure you flex your leg 5-20° without twisting during the flex phase.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: TestStatus.idle,
        errorMessage: 'Calibration failed: ${e.toString()}',
      ));
    }
  }

  void _onCalibrationComplete(CalibrationComplete event, Emitter<TestState> emit) {
    emit(state.copyWith(
      gRef: event.gRef,
      planeU: event.planeU,
      planeV: event.planeV,
      zeroOffsetDeg: event.zeroOffsetDeg,
      status: TestStatus.ready,
    ));
  }

  Future<void> _onStartTest(StartTest event, Emitter<TestState> emit) async {
    if (!state.isCalibrated) {
      emit(state.copyWith(errorMessage: 'Please calibrate first'));
      return;
    }

    emit(state.copyWith(
      status: TestStatus.recording,
      startTime: DateTime.now(),
      dropDetected: false,
      reactionDetected: false,
      peakDropAngle: 180.0,
      minLegAngleDeg: state.liveAngle ?? 180.0,
      minAt: DateTime.now(),
      dropStartAt: null,
    ));

    _angleWindow.clear();
    await _preRollNoiseCharacterization();

    _autoStopTimer = Timer(_maxTestDuration, () {
      if (state.isRecording) {
        add(const StopTest());
      }
    });
  }

  void _onUpdateSensorData(UpdateSensorData event, Emitter<TestState> emit) {
    _a.setValues(event.acceleration.x, event.acceleration.y, event.acceleration.z);
    _gFiltered = (_gFiltered * _beta) + (event.acceleration * (1.0 - _beta));
    if (_gFiltered.length2 != 0) _gFiltered = _gFiltered.normalized();
    
    _gyro = event.gyroscope;
    _accelMag = math.sqrt(
      event.acceleration.x * event.acceleration.x +
      event.acceleration.y * event.acceleration.y +
      event.acceleration.z * event.acceleration.z
    ) / 9.81;

    // Calculate angular velocity
    final now = DateTime.now();
    if (_lastAngle != null && _lastAngleTime != null) {
      final dt = now.difference(_lastAngleTime!).inMicroseconds / 1e6;
      if (dt > 0) {
        _omegaDegPerSec = (event.liveAngle - _lastAngle!) / dt;
      }
    }
    
    // Update angle tracking
    _lastAngle = event.liveAngle;
    _lastAngleTime = now;

    emit(state.copyWith(
      liveAngle: event.liveAngle,
      signalQuality: event.signalQuality,
    ));

    if (state.isRecording) {
      _detectDropAndReaction(emit);
    }
  }

  void _onDetectDrop(DetectDrop event, Emitter<TestState> emit) {
    emit(state.copyWith(
      dropDetected: true,
      dropStartAt: event.timestamp,
      minLegAngleDeg: event.peakAngle,
      minAt: event.timestamp,
    ));
    
    // Set a timeout for reaction detection (5 seconds)
    Timer(const Duration(seconds: 5), () {
      if (state.dropDetected && !state.reactionDetected) {
        add(DetectReaction(DateTime.now()));
      }
    });
  }

  void _onDetectReaction(DetectReaction event, Emitter<TestState> emit) {
    emit(state.copyWith(
      reactionDetected: true,
      peakDropAngle: state.minLegAngleDeg,
    ));
    add(const StopTest());
  }

  Future<void> _onStopTest(StopTest event, Emitter<TestState> emit) async {
    if (!state.isRecording) return;

    _autoStopTimer?.cancel();

    final now = DateTime.now();
    final minLeg = state.minLegAngleDeg ?? (state.liveAngle ?? state.customBaselineAngle);
    
    // Calculate drop angle - how many degrees the leg actually dropped
    // This measures the actual movement from the starting position to the minimum position
    final startingAngle = state.customBaselineAngle;
    final rawDropAngle = (startingAngle - minLeg).clamp(0.0, 180.0);
    
    // Apply consistency validation
    final actualDropAngle = _validateDropMeasurement(rawDropAngle, startingAngle, minLeg);
    
    // Track recent drops for consistency analysis
    _recentDrops.add(actualDropAngle);
    if (_recentDrops.length > 5) {
      _recentDrops.removeAt(0);
    }
    
    print('🔍 Drop Measurement:');
    print('   Starting angle (baseline): ${startingAngle.toStringAsFixed(1)}°');
    print('   Minimum angle reached: ${minLeg.toStringAsFixed(1)}°');
    print('   Raw drop: ${rawDropAngle.toStringAsFixed(1)}°');
    print('   Validated drop: ${actualDropAngle.toStringAsFixed(1)}°');
    print('   Stability: ${(_angleVariance * 100).toStringAsFixed(1)}%');
    print('   Recent drops: ${_recentDrops.map((d) => d.toStringAsFixed(1)).join(', ')}');
    
    // Calculate drop time
    Duration? dropTime;
    if (state.dropStartAt != null && state.minAt != null) {
      dropTime = state.minAt!.difference(state.dropStartAt!);
    } else if (state.startTime != null && state.minAt != null) {
      dropTime = state.minAt!.difference(state.startTime!);
    }

    final motorVelocity = dropTime != null && dropTime.inMilliseconds > 0 
        ? (actualDropAngle / (dropTime.inMilliseconds / 1000.0))
        : 0.0;

    print('🔍 Trial results: actualDropAngle=${actualDropAngle.toStringAsFixed(1)}°, dropTime=$dropTime, motorVelocity=${motorVelocity.toStringAsFixed(1)}°/s');

    // Update the current trial with the actual drop measurement
    final updatedTrial = state.currentTrial?.copyWith(
      dropAngle: actualDropAngle,
      peakDropAngle: state.peakDropAngle,
      dropTimeMs: dropTime?.inMilliseconds.toDouble(),
      motorVelocity: motorVelocity,
    );

    emit(state.copyWith(
      status: TestStatus.trialCompleted,
      endTime: now,
      dropAngle: actualDropAngle,
      dropTime: dropTime,
      motorVelocity: motorVelocity,
      currentTrial: updatedTrial,
      showTrialDecisionDialog: true,
    ));
  }

  void _onResetTest(ResetTest event, Emitter<TestState> emit) {
    _autoStopTimer?.cancel();
    emit(const TestState());
  }

  Future<void> _onSaveTestResults(SaveTestResults event, Emitter<TestState> emit) async {
    // This would be handled by the PatientBloc when updating patient data
    emit(state.copyWith(status: TestStatus.idle));
  }

  void _startSensors() {
    const int us = 1000;
    motionSensors.accelerometerUpdateInterval = us;
    motionSensors.userAccelerometerUpdateInterval = us;
    motionSensors.gyroscopeUpdateInterval = us;

    _accelSub = motionSensors.accelerometer.listen((AccelerometerEvent e) {
      _sampleCount++;
      
      // Update filtered gravity vector
      final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
      if (next.length2 != 0) {
        _gFiltered = next.normalized();
      }
      
      // Only calculate live angle if we have calibration data
      double? liveAngle;
      if (state.gRef != null && state.planeU != null && state.planeV != null) {
        liveAngle = _calculateLiveAngle();
      }
      
      add(UpdateSensorData(
        acceleration: Vector3(e.x, e.y, e.z),
        liveAngle: liveAngle ?? 180.0,
        signalQuality: _sampleRate.toDouble(),
      ));
    });

    _gyroSub = motionSensors.gyroscope.listen((g) {
      _gyro = Vector3(g.x, g.y, g.z);
    });
  }

  void _initializeSampleRateMonitoring() {
    _sampleRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _sampleRate = _sampleCount;
      _sampleCount = 0;
    });
  }

  double _calculateLiveAngle() {
    if (state.gRef == null || state.planeU == null || state.planeV == null) {
      return 180.0;
    }

    final leg = _legAngleInPlane(_gFiltered);
    if (leg == null) return 180.0;

    // For live angle, use simpler filtering to ensure responsiveness
    // Apply basic outlier removal but don't use the heavy advanced filtering
    final cleanedAngle = _removeOutliers(leg);
    
    // Use median smoothing for live display (more responsive)
    final smoothed = _medianSmooth(cleanedAngle);
    
    // Update angle history for drop validation (separate from live angle)
    _angleHistory.add(cleanedAngle);
    if (_angleHistory.length > _historySize) {
      _angleHistory.removeAt(0);
    }
    
    // Update stability tracking
    _angleVariance = _calculateStability(_angleHistory);
    
    // Debug logging (only occasionally to avoid spam)
    if (_sampleCount % 50 == 0) {
      print('🔍 Live angle: raw=$leg, cleaned=$cleanedAngle, smoothed=$smoothed');
    }
    
    return smoothed;
  }

  double? _legAngleInPlane(Vector3 gCur) {
    if (state.gRef == null || state.planeU == null || state.planeV == null) return null;

    // Project both reference and current vectors onto the leg movement plane
    final ref = state.gRef!;
    final refU = ref.dot(state.planeU!);
    final refV = ref.dot(state.planeV!);
    final curU = gCur.dot(state.planeU!);
    final curV = gCur.dot(state.planeV!);

    // Normalize the projected vectors
    final ref2 = math.sqrt(refU * refU + refV * refV);
    final cur2 = math.sqrt(curU * curU + curV * curV);
    if (ref2 == 0 || cur2 == 0) return null;

    final refNormU = refU / ref2;
    final refNormV = refV / ref2;
    final curNormU = curU / cur2;
    final curNormV = curV / cur2;

    // Calculate the angle between the normalized vectors
    final dotProduct = (refNormU * curNormU + refNormV * curNormV).clamp(-1.0, 1.0);
    final angleBetweenVectors = math.acos(dotProduct) * 180.0 / math.pi;

    // For leg flexion measurement with inverted scale:
    // - When the leg is extended (reference), we want 180°
    // - When the leg is flexed, we want a lower angle
    // - The angle between vectors gives us the change from reference
    // - We need to invert this so 180° = extended, 0° = fully flexed
    
    // The angle between vectors gives us how much the leg has moved from reference
    // When vectors are aligned (extended), angle = 0°
    // When vectors are opposite (flexed), angle = 180°
    // We need to invert this: 180° - angleBetweenVectors
    final legAngle = 180.0 - angleBetweenVectors;
    
    // Apply the custom baseline offset if needed
    final adjustedAngle = legAngle + state.zeroOffsetDeg;
    
    // Ensure the angle is within reasonable bounds (0-180 degrees)
    final finalAngle = adjustedAngle.clamp(0.0, 180.0);
    
    print('🔍 Angle calculation: refU=$refU, refV=$refV, curU=$curU, curV=$curV');
    print('🔍 Dot product: $dotProduct, Angle between vectors: $angleBetweenVectors');
    print('🔍 Leg angle: $legAngle, zeroOffset: ${state.zeroOffsetDeg}');
    print('🔍 Adjusted angle: $adjustedAngle, Final leg angle: $finalAngle');
    print('🔍 Custom baseline: ${state.customBaselineAngle}');
    
    return finalAngle;
  }

  double _medianSmooth(double v) {
    _angleWindow.add(v);
    if (_angleWindow.length > _medianWin) _angleWindow.removeAt(0);
    final sorted = List<double>.from(_angleWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }


  double _calculateMovingAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }


  double _calculateStability(List<double> values) {
    if (values.length < 3) return 0.0;
    
    // Calculate variance
    final mean = _calculateMovingAverage(values);
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    
    // Convert to stability score (0-1, higher is more stable)
    // Lower standard deviation = higher stability
    final stability = math.exp(-stdDev / 2.0).clamp(0.0, 1.0);
    return stability;
  }

  // Outlier detection and removal (less aggressive for live angle)
  double _removeOutliers(double angle) {
    if (_angleHistory.length < 3) return angle;
    
    // Calculate median and median absolute deviation
    final sorted = List<double>.from(_angleHistory)..sort();
    final median = sorted[sorted.length ~/ 2];
    
    final deviations = sorted.map((v) => (v - median).abs()).toList()..sort();
    final mad = deviations[deviations.length ~/ 2]; // Median Absolute Deviation
    
    // Use more lenient threshold for live angle (5 MADs instead of 3)
    // Only remove extreme outliers to maintain responsiveness
    if ((angle - median).abs() > 5 * mad && mad > 0.1) {
      print('🚨 Extreme outlier detected: $angle (median: $median, MAD: $mad)');
      return median; // Return median instead of outlier
    }
    
    return angle;
  }

  // Validate drop measurement for consistency
  double _validateDropMeasurement(double rawDrop, double startingAngle, double minAngle) {
    // Basic sanity checks
    if (rawDrop < 0 || rawDrop > 180) {
      print('⚠️ Invalid drop angle: $rawDrop, using 0');
      return 0.0;
    }
    
    // Check if the drop is too small (likely noise)
    if (rawDrop < 2.0) {
      print('⚠️ Drop too small (${rawDrop.toStringAsFixed(1)}°), likely noise');
      return 0.0;
    }
    
    // Check if the drop is too large (likely error)
    if (rawDrop > 90.0) {
      print('⚠️ Drop too large (${rawDrop.toStringAsFixed(1)}°), likely error');
      return 90.0; // Cap at 90 degrees
    }
    
    // Check consistency with recent drops
    if (_recentDrops.isNotEmpty) {
      final avgRecent = _recentDrops.reduce((a, b) => a + b) / _recentDrops.length;
      final deviation = (rawDrop - avgRecent).abs();
      
      // If this drop is very different from recent ones, apply smoothing
      if (deviation > 15.0 && _recentDrops.length >= 3) {
        print('⚠️ Inconsistent drop: ${rawDrop.toStringAsFixed(1)}° vs recent avg ${avgRecent.toStringAsFixed(1)}°');
        // Blend with recent average for consistency
        return (rawDrop * 0.3) + (avgRecent * 0.7);
      }
    }
    
    // Check stability of the measurement
    if (_angleVariance < 0.3) {
      print('⚠️ Low stability (${(_angleVariance * 100).toStringAsFixed(1)}%), applying conservative adjustment');
      // If stability is low, be more conservative
      return rawDrop * 0.9; // Slightly reduce the measurement
    }
    
    return rawDrop;
  }

  // Enhanced sensor quality assessment
  double _assessSensorQuality() {
    if (_angleWindow.length < 10) return 0.0;
    
    // Calculate variance to assess noise level
    final mean = _angleWindow.reduce((a, b) => a + b) / _angleWindow.length;
    final variance = _angleWindow.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / _angleWindow.length;
    final stdDev = math.sqrt(variance);
    
    // Quality score: 0-1, where 1 is perfect
    // Lower standard deviation = higher quality
    final quality = (1.0 - (stdDev / 10.0)).clamp(0.0, 1.0);
    
    print('🔍 Sensor quality: stdDev=$stdDev, quality=$quality');
    return quality;
  }



  void _detectDropAndReaction(Emitter<TestState> emit) {
    if (!state.dropDetected) {
      // Calculate angular velocity from gyroscope (convert rad/s to deg/s)
      double gyroInPlaneDeg = 0.0;
      if (_gyro != null && state.planeU != null && state.planeV != null) {
        final n = state.planeU!.cross(state.planeV!).normalized();
        gyroInPlaneDeg = _gyro!.dot(n) * 180.0 / math.pi; // rad/s -> deg/s
      }
      
      // Angular velocity is now calculated in _onUpdateSensorData
      
      // Get adaptive thresholds
      final thresholds = _getAdaptiveThresholds();
      
      final fastDown = gyroInPlaneDeg < -thresholds['omegaDrop']!;
      final accelDip = _accelMag < thresholds['accelDip']!;
      final fallbackFast = _omegaDegPerSec < -(thresholds['omegaDrop']! * 0.7);

      print('🔍 Drop detection: liveAngle=${state.liveAngle}, gyroInPlane=$gyroInPlaneDeg, omegaDegPerSec=$_omegaDegPerSec');
      print('🔍 Conditions: fastDown=$fastDown, accelDip=$accelDip, fallbackFast=$fallbackFast');
      print('🔍 Adaptive thresholds: $thresholds');

      if ((fastDown && accelDip) || (fallbackFast && accelDip)) {
        print('🎯 DROP DETECTED!');
        add(DetectDrop(
          peakAngle: state.liveAngle ?? state.customBaselineAngle,
          timestamp: DateTime.now(),
        ));
      }
    } else if (!state.reactionDetected) {
      // Update minimum angle while falling
      if (state.minLegAngleDeg == null || (state.liveAngle ?? state.customBaselineAngle) < state.minLegAngleDeg!) {
        emit(state.copyWith(
          minLegAngleDeg: state.liveAngle ?? state.customBaselineAngle,
          minAt: DateTime.now(),
        ));
      }

      // Calculate angular velocity from gyroscope (convert rad/s to deg/s)
      double gyroInPlaneDeg = 0.0;
      if (_gyro != null && state.planeU != null && state.planeV != null) {
        final n = state.planeU!.cross(state.planeV!).normalized();
        gyroInPlaneDeg = _gyro!.dot(n) * 180.0 / math.pi; // rad/s -> deg/s
      }
      
      // Get adaptive thresholds for reaction detection
      final thresholds = _getAdaptiveThresholds();
      
      final fastUp = gyroInPlaneDeg > thresholds['omegaReaction']!;
      final accelBump = _accelMag > thresholds['accelBump']!;
      final fallbackUp = _omegaDegPerSec > (thresholds['omegaReaction']! * 0.5);

      // Also check if patient has returned to near starting position
      final currentAngle = state.liveAngle ?? state.customBaselineAngle;
      final returnedToStart = (currentAngle - state.customBaselineAngle).abs() < 10.0; // Within 10 degrees of start

      if ((fastUp && accelBump) || (fallbackUp && accelBump) || returnedToStart) {
        add(DetectReaction(DateTime.now()));
      }
    }
  }

  Future<Vector3> _captureStableReference({int samples = 60}) async {
    Vector3 sum = Vector3.zero();
    int got = 0;
    List<Vector3> samplesList = [];

    final c = Completer<Vector3>();
    StreamSubscription? sub;
    
    try {
      // Add timeout to prevent hanging
      final timeout = Future.delayed(const Duration(seconds: 15), () {
        if (!c.isCompleted) {
          c.completeError('Calibration timeout - please hold the device still and try again');
        }
      });

      sub = motionSensors.accelerometer.listen((e) {
        final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
        if (next.length2 != 0) {
          _gFiltered = next.normalized();
          sum += _gFiltered;
          samplesList.add(_gFiltered.clone());
          got++;
          
          // Check for movement during capture
          if (got > 10) {
            final recentSamples = samplesList.length > 10 ? samplesList.sublist(samplesList.length - 10) : samplesList;
            final stability = _checkStability(recentSamples);
            
            if (stability < 0.8) {
              print('⚠️ Movement detected during reference capture: stability=$stability');
              // Don't fail immediately, but warn
            }
          }
          
          if (got >= samples && !c.isCompleted) {
            // Final stability check
            final finalStability = _checkStability(samplesList);
            if (finalStability < 0.7) {
              c.completeError('Device moved too much during calibration. Please hold it very still and try again.');
              return;
            }
            
            print('🔧 Captured stable reference: ${sum.normalized()} (${got} samples, stability: $finalStability)');
            c.complete(sum.normalized());
          }
        }
      });

      await Future.any([c.future, timeout]);
      await sub.cancel();
      return sum.normalized();
    } catch (e) {
      await sub?.cancel();
      rethrow;
    }
  }

  // Check stability of accelerometer samples
  double _checkStability(List<Vector3> samples) {
    if (samples.length < 3) return 1.0;
    
    // Calculate variance in each axis
    final xValues = samples.map((s) => s.x).toList();
    final yValues = samples.map((s) => s.y).toList();
    final zValues = samples.map((s) => s.z).toList();
    
    final xVar = _calculateVariance(xValues);
    final yVar = _calculateVariance(yValues);
    final zVar = _calculateVariance(zValues);
    
    // Stability score: 0-1, where 1 is perfectly stable
    final maxVar = [xVar, yVar, zVar].reduce((a, b) => a > b ? a : b);
    final stability = (1.0 - (maxVar / 0.1)).clamp(0.0, 1.0);
    
    return stability;
  }

  double _calculateVariance(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    return variance;
  }

  // Capture the baseline angle after plane definition with quality validation
  Future<double> _captureBaselineAngle({int samples = 50}) async {
    print('🔧 Capturing baseline angle with quality validation...');
    
    // Wait a moment for user to position their leg
    await Future.delayed(const Duration(milliseconds: 1500));
    
    List<double> angleSamples = [];
    final c = Completer<double>();
    StreamSubscription? sub;
    
    try {
      final timeout = Future.delayed(const Duration(seconds: 15), () {
        if (!c.isCompleted) {
          c.completeError('Baseline capture timeout - please try again');
        }
      });

      sub = motionSensors.accelerometer.listen((e) {
        final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
        if (next.length2 != 0) {
          _gFiltered = next.normalized();
          
          // Calculate the current angle
          final currentAngle = _calculateLiveAngle();
          angleSamples.add(currentAngle);
          
          if (angleSamples.length >= samples) {
            // Validate the quality of the baseline
            final quality = _validateBaselineQuality(angleSamples);
            
            if (quality > 0.7) {
              // High quality baseline
              final avgAngle = angleSamples.reduce((a, b) => a + b) / angleSamples.length;
              print('✅ High quality baseline: ${avgAngle.toStringAsFixed(1)}° (quality: ${(quality * 100).toStringAsFixed(1)}%)');
              c.complete(avgAngle);
            } else {
              // Low quality - try again with more samples
              print('⚠️ Low quality baseline (${(quality * 100).toStringAsFixed(1)}%), collecting more samples...');
              if (angleSamples.length < samples * 2) {
                // Continue collecting more samples
                return;
              } else {
                // Use the best we have
                final avgAngle = angleSamples.reduce((a, b) => a + b) / angleSamples.length;
                print('⚠️ Using baseline despite low quality: ${avgAngle.toStringAsFixed(1)}°');
                c.complete(avgAngle);
              }
            }
          }
        }
      });

      await Future.any([c.future, timeout]);
      await sub.cancel();
      return c.future;
    } catch (e) {
      await sub?.cancel();
      rethrow;
    }
  }

  // Validate the quality of baseline angle capture
  double _validateBaselineQuality(List<double> samples) {
    if (samples.length < 10) return 0.0;
    
    // Calculate statistics
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) / samples.length;
    final stdDev = math.sqrt(variance);
    
    // Calculate coefficient of variation (lower is better)
    final cv = stdDev / mean;
    
    // Calculate range (smaller range is better)
    final sorted = List<double>.from(samples)..sort();
    final range = sorted.last - sorted.first;
    
    // Quality score based on consistency
    double quality = 1.0;
    
    // Penalize high coefficient of variation
    if (cv > 0.05) quality -= (cv - 0.05) * 10; // 5% CV is acceptable
    
    // Penalize large range
    if (range > 5.0) quality -= (range - 5.0) * 0.1; // 5° range is acceptable
    
    // Penalize if mean is too far from expected range
    if (mean < 160.0 || mean > 200.0) quality -= 0.3;
    
    return quality.clamp(0.0, 1.0);
  }


  // Get adaptive thresholds based on patient characteristics and sensor quality
  Map<String, double> _getAdaptiveThresholds() {
    final sensorQuality = _assessSensorQuality();
    
    // Base thresholds
    double omegaDrop = _omegaDropThreshDegPerSec;
    double omegaReaction = _omegaReactThreshDegPerSec;
    double accelDip = _accelDipFrac;
    double accelBump = _accelBumpFrac;
    
    // Adjust based on sensor quality
    if (sensorQuality < 0.5) {
      // Low quality sensors need more sensitive thresholds
      omegaDrop *= 0.8;
      omegaReaction *= 0.8;
      accelDip *= 0.8;
      accelBump *= 0.8;
    } else if (sensorQuality > 0.8) {
      // High quality sensors can use more precise thresholds
      omegaDrop *= 1.2;
      omegaReaction *= 1.2;
      accelDip *= 1.2;
      accelBump *= 1.2;
    }
    
    // Ensure thresholds are within reasonable bounds
    omegaDrop = omegaDrop.clamp(10.0, 100.0);
    omegaReaction = omegaReaction.clamp(10.0, 100.0);
    accelDip = accelDip.clamp(0.05, 0.3);
    accelBump = accelBump.clamp(0.05, 0.3);
    
    return {
      'omegaDrop': omegaDrop,
      'omegaReaction': omegaReaction,
      'accelDip': accelDip,
      'accelBump': accelBump,
    };
  }

  Future<Map<String, Vector3>?> _captureFlexAndBuildPlane({int samples = 30}) async {
    Vector3 sum = Vector3.zero();
    int got = 0;

    final c = Completer<Vector3>();
    StreamSubscription? sub;
    
    try {
      // Add timeout to prevent hanging
      final timeout = Future.delayed(const Duration(seconds: 10), () {
        if (!c.isCompleted) {
          c.completeError('Flex capture timeout - please try again');
        }
      });

      sub = motionSensors.accelerometer.listen((e) {
        final next = (_gFiltered * _beta) + (Vector3(e.x, e.y, e.z) * (1.0 - _beta));
        if (next.length2 != 0) {
          _gFiltered = next.normalized();
          sum += _gFiltered;
          got++;
          if (got >= samples && !c.isCompleted) {
            c.complete(sum.normalized());
          }
        }
      });

      await Future.any([c.future, timeout]);
      await sub.cancel();

      final gFlex = sum.normalized();
      if (state.gRef == null) return null;

      final delta = _angleBetween(state.gRef!, gFlex);
      if (delta < 5.0 || delta > 25.0) return null;

      final n = state.gRef!.cross(gFlex);
      if (n.length2 == 0) return null;
      final planeN = n.normalized();

      final tmp = (gFlex - state.gRef! * state.gRef!.dot(gFlex));
      if (tmp.length2 == 0) return null;

      final planeU = tmp.normalized();
      final planeV = planeN.cross(planeU).normalized();
      
      return {'u': planeU, 'v': planeV};
    } catch (e) {
      await sub?.cancel();
      rethrow;
    }
  }

  double _angleBetween(Vector3 a, Vector3 b) {
    final d = a.normalized().dot(b.normalized()).clamp(-1.0, 1.0);
    return math.acos(d) * 180.0 / math.pi;
  }

  Future<void> _preRollNoiseCharacterization({int ms = 500}) async {
    // Implementation for noise characterization
    await Future.delayed(Duration(milliseconds: ms));
  }

  // New trial management event handlers
  Future<void> _onStartNewTrial(StartNewTrial event, Emitter<TestState> emit) async {
    if (!state.isCalibrated) {
      emit(state.copyWith(errorMessage: 'Please calibrate first'));
      return;
    }

    final newTrialNumber = state.currentTrialNumber + 1;
    final newTrial = Trial(
      id: 'T${newTrialNumber.toString().padLeft(2, '0')}',
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      status: TestStatus.recording,
      startTime: DateTime.now(),
      dropDetected: false,
      reactionDetected: false,
      peakDropAngle: state.customBaselineAngle,
      minLegAngleDeg: state.liveAngle ?? state.customBaselineAngle,
      minAt: DateTime.now(),
      dropStartAt: null,
      currentTrialNumber: newTrialNumber,
      currentTrial: newTrial,
      trials: [...state.trials, newTrial],
    ));

    _angleWindow.clear();
    await _preRollNoiseCharacterization();

    _autoStopTimer = Timer(_maxTestDuration, () {
      if (state.isRecording) {
        add(const StopTest());
      }
    });
  }

  void _onEndTesting(EndTesting event, Emitter<TestState> emit) {
    emit(state.copyWith(
      status: TestStatus.testingEnded,
      showTrialDecisionDialog: false,
    ));
  }

  void _onKeepTrial(KeepTrial event, Emitter<TestState> emit) {
    if (state.currentTrial == null) return;

    final updatedTrial = state.currentTrial!.copyWith(
      isKept: true,
      notes: event.notes,
      dropAngle: state.dropAngle,
      dropTimeMs: state.dropTime?.inMilliseconds.toDouble(),
      motorVelocity: state.motorVelocity,
      peakDropAngle: state.peakDropAngle,
    );

    final updatedTrials = state.trials.map((trial) {
      return trial.id == updatedTrial.id ? updatedTrial : trial;
    }).toList();

    emit(state.copyWith(
      status: TestStatus.ready,
      trials: updatedTrials,
      currentTrial: updatedTrial,
      showTrialDecisionDialog: false,
    ));
  }

  void _onDiscardTrial(DiscardTrial event, Emitter<TestState> emit) {
    if (state.currentTrial == null) return;

    final updatedTrial = state.currentTrial!.copyWith(
      isKept: false,
      notes: event.reason,
    );

    final updatedTrials = state.trials.map((trial) {
      return trial.id == updatedTrial.id ? updatedTrial : trial;
    }).toList();

    emit(state.copyWith(
      status: TestStatus.ready,
      trials: updatedTrials,
      currentTrial: updatedTrial,
      showTrialDecisionDialog: false,
    ));
  }

  void _onSetCustomBaselineAngle(SetCustomBaselineAngle event, Emitter<TestState> emit) {
    emit(state.copyWith(
      customBaselineAngle: event.angle,
    ));
  }

  void _onAdjustCalibration(AdjustCalibration event, Emitter<TestState> emit) {
    print('🔧 Adjusting calibration: zeroOffsetDeg = ${event.zeroOffsetDeg}');
    emit(state.copyWith(
      zeroOffsetDeg: event.zeroOffsetDeg,
    ));
  }

  void _onSetManualBaseline(SetManualBaseline event, Emitter<TestState> emit) {
    print('🔧 Setting manual baseline: ${event.baselineAngle}°');
    emit(state.copyWith(
      customBaselineAngle: event.baselineAngle,
      status: TestStatus.ready,
      errorMessage: null,
    ));
  }
}
