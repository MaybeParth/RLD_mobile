import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class TestEvent extends Equatable {
  const TestEvent();

  @override
  List<Object?> get props => [];
}

class InitializeTest extends TestEvent {
  const InitializeTest();
}

class StartCalibration extends TestEvent {
  const StartCalibration();
}

class CalibrationComplete extends TestEvent {
  final Vector3 gRef;
  final Vector3 planeU;
  final Vector3 planeV;
  final double zeroOffsetDeg;
  final double customBaselineAngle;

  const CalibrationComplete({
    required this.gRef,
    required this.planeU,
    required this.planeV,
    required this.zeroOffsetDeg,
    this.customBaselineAngle = 180.0,
  });

  @override
  List<Object?> get props =>
      [gRef, planeU, planeV, zeroOffsetDeg, customBaselineAngle];
}

class StartTest extends TestEvent {
  const StartTest();
}

class UpdateSensorData extends TestEvent {
  final Vector3 acceleration;
  final Vector3? gyroscope;
  final double liveAngle;
  final double signalQuality;

  const UpdateSensorData({
    required this.acceleration,
    this.gyroscope,
    required this.liveAngle,
    required this.signalQuality,
  });

  @override
  List<Object?> get props =>
      [acceleration, gyroscope, liveAngle, signalQuality];
}

class DetectDrop extends TestEvent {
  final double peakAngle;
  final DateTime timestamp;

  const DetectDrop({
    required this.peakAngle,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [peakAngle, timestamp];
}

class DetectReaction extends TestEvent {
  final DateTime timestamp;

  const DetectReaction(this.timestamp);

  @override
  List<Object?> get props => [timestamp];
}

class StopTest extends TestEvent {
  const StopTest();
}

class ResetTest extends TestEvent {
  const ResetTest();
}

class SaveTestResults extends TestEvent {
  final double dropAngle;
  final Duration dropTime;
  final double motorVelocity;

  const SaveTestResults({
    required this.dropAngle,
    required this.dropTime,
    required this.motorVelocity,
  });

  @override
  List<Object?> get props => [dropAngle, dropTime, motorVelocity];
}

// New trial management events
class StartNewTrial extends TestEvent {
  const StartNewTrial();
}

class EndTesting extends TestEvent {
  const EndTesting();
}

class KeepTrial extends TestEvent {
  final String? notes;

  const KeepTrial({this.notes});

  @override
  List<Object?> get props => [notes];
}

class DiscardTrial extends TestEvent {
  final String? reason;

  const DiscardTrial({this.reason});

  @override
  List<Object?> get props => [reason];
}

class SetCustomBaselineAngle extends TestEvent {
  final double angle;

  const SetCustomBaselineAngle(this.angle);

  @override
  List<Object?> get props => [angle];
}

class AdjustCalibration extends TestEvent {
  final double zeroOffsetDeg;

  const AdjustCalibration(this.zeroOffsetDeg);

  @override
  List<Object?> get props => [zeroOffsetDeg];
}

class SetManualBaseline extends TestEvent {
  final double baselineAngle;

  const SetManualBaseline(this.baselineAngle);

  @override
  List<Object?> get props => [baselineAngle];
}
