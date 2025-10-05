import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../models/trial.dart';

enum TestStatus {
  idle,
  calibrating,
  ready,
  recording,
  completed,
  trialCompleted,
  testingEnded
}

class TestState extends Equatable {
  final TestStatus status;
  final double? liveAngle;
  final double? peakDropAngle;
  final double? dropAngle;
  final Duration? dropTime;
  final double? motorVelocity;
  final double signalQuality;
  final bool dropDetected;
  final bool reactionDetected;
  final DateTime? startTime;
  final DateTime? endTime;
  final Vector3? gRef;
  final Vector3? planeU;
  final Vector3? planeV;
  final double zeroOffsetDeg;
  final String? errorMessage;
  final DateTime? dropStartAt;
  final double? minLegAngleDeg;
  final DateTime? minAt;

  // Trial management
  final List<Trial> trials;
  final int currentTrialNumber;
  final Trial? currentTrial;
  final double customBaselineAngle;
  final bool showTrialDecisionDialog;

  const TestState({
    this.status = TestStatus.idle,
    this.liveAngle,
    this.peakDropAngle,
    this.dropAngle,
    this.dropTime,
    this.motorVelocity,
    this.signalQuality = 0.0,
    this.dropDetected = false,
    this.reactionDetected = false,
    this.startTime,
    this.endTime,
    this.gRef,
    this.planeU,
    this.planeV,
    this.zeroOffsetDeg = 0.0,
    this.errorMessage,
    this.dropStartAt,
    this.minLegAngleDeg,
    this.minAt,
    this.trials = const [],
    this.currentTrialNumber = 0,
    this.currentTrial,
    this.customBaselineAngle = 180.0,
    this.showTrialDecisionDialog = false,
  });

  @override
  List<Object?> get props => [
        status,
        liveAngle,
        peakDropAngle,
        dropAngle,
        dropTime,
        motorVelocity,
        signalQuality,
        dropDetected,
        reactionDetected,
        startTime,
        endTime,
        gRef,
        planeU,
        planeV,
        zeroOffsetDeg,
        errorMessage,
        dropStartAt,
        minLegAngleDeg,
        minAt,
        trials,
        currentTrialNumber,
        currentTrial,
        customBaselineAngle,
        showTrialDecisionDialog,
      ];

  TestState copyWith({
    TestStatus? status,
    double? liveAngle,
    double? peakDropAngle,
    double? dropAngle,
    Duration? dropTime,
    double? motorVelocity,
    double? signalQuality,
    bool? dropDetected,
    bool? reactionDetected,
    DateTime? startTime,
    DateTime? endTime,
    Vector3? gRef,
    Vector3? planeU,
    Vector3? planeV,
    double? zeroOffsetDeg,
    String? errorMessage,
    DateTime? dropStartAt,
    double? minLegAngleDeg,
    DateTime? minAt,
    List<Trial>? trials,
    int? currentTrialNumber,
    Trial? currentTrial,
    double? customBaselineAngle,
    bool? showTrialDecisionDialog,
  }) {
    return TestState(
      status: status ?? this.status,
      liveAngle: liveAngle ?? this.liveAngle,
      peakDropAngle: peakDropAngle ?? this.peakDropAngle,
      dropAngle: dropAngle ?? this.dropAngle,
      dropTime: dropTime ?? this.dropTime,
      motorVelocity: motorVelocity ?? this.motorVelocity,
      signalQuality: signalQuality ?? this.signalQuality,
      dropDetected: dropDetected ?? this.dropDetected,
      reactionDetected: reactionDetected ?? this.reactionDetected,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      gRef: gRef ?? this.gRef,
      planeU: planeU ?? this.planeU,
      planeV: planeV ?? this.planeV,
      zeroOffsetDeg: zeroOffsetDeg ?? this.zeroOffsetDeg,
      errorMessage: errorMessage ?? this.errorMessage,
      dropStartAt: dropStartAt ?? this.dropStartAt,
      minLegAngleDeg: minLegAngleDeg ?? this.minLegAngleDeg,
      minAt: minAt ?? this.minAt,
      trials: trials ?? this.trials,
      currentTrialNumber: currentTrialNumber ?? this.currentTrialNumber,
      currentTrial: currentTrial ?? this.currentTrial,
      customBaselineAngle: customBaselineAngle ?? this.customBaselineAngle,
      showTrialDecisionDialog:
          showTrialDecisionDialog ?? this.showTrialDecisionDialog,
    );
  }

  bool get isCalibrated => gRef != null && planeU != null && planeV != null;
  bool get isRecording => status == TestStatus.recording;
  bool get isCompleted => status == TestStatus.completed;
  bool get hasError => errorMessage != null;
  bool get isTrialCompleted => status == TestStatus.trialCompleted;
  bool get isTestingEnded => status == TestStatus.testingEnded;

  // Trial management helpers
  List<Trial> get keptTrials => trials.where((trial) => trial.isKept).toList();
  List<Trial> get discardedTrials =>
      trials.where((trial) => !trial.isKept).toList();
  int get totalTrials => trials.length;
  int get keptTrialsCount => keptTrials.length;
  int get discardedTrialsCount => discardedTrials.length;
  bool get hasTrials => trials.isNotEmpty;
  bool get canStartNewTrial => isCalibrated && !isRecording;
  bool get canEndTesting => trials.isNotEmpty;
}
