import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/test/test_bloc.dart';
import '../bloc/events/test_events.dart';
import '../bloc/states/test_states.dart';
import '../models/patients.dart';
import '../models/trial.dart';
import '../widgets/trial_decision_dialog.dart';
import '../widgets/test_instruction_dialog.dart';
import '../widgets/quick_reference_card.dart';
import '../widgets/calibration_debug_dialog.dart';
import '../widgets/calibration_adjustment_dialog.dart';
import '../widgets/enhanced_calibration_instructions.dart';
import '../widgets/enhanced_calibration_flow_dialog.dart';
import '../widgets/manual_calibration_dialog.dart';
import '../screens/patient_instructions_screen.dart';

class TestScreenBloc extends StatefulWidget {
  final Patient patient;

  const TestScreenBloc({super.key, required this.patient});

  @override
  State<TestScreenBloc> createState() => _TestScreenBlocState();
}

class _TestScreenBlocState extends State<TestScreenBloc> with TickerProviderStateMixin {
  AnimationController? _pulseController;
  AnimationController? _recordingController;
  String? _lastErrorMessage; // Track last shown error to prevent duplicates
  bool _trialDialogShown = false; // Prevent multiple trial dialogs

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
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _recordingController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test - ${widget.patient.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.straighten),
            tooltip: 'Calibrate to 180°',
            onPressed: _calibrateTo180,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showCalibrationDebug(),
            tooltip: 'Debug Calibration',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showPatientInstructions(),
            tooltip: 'Show Instructions',
          ),
          BlocBuilder<TestBloc, TestState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildSignalQuality(state.signalQuality),
              );
            },
          ),
        ],
      ),
      body: BlocListener<TestBloc, TestState>(
        listener: (context, state) {
          // Only show error snackbar if it's a new error message
          if (state.hasError && state.errorMessage != _lastErrorMessage) {
            _lastErrorMessage = state.errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } else if (!state.hasError) {
            // Clear the last error message when there's no error
            _lastErrorMessage = null;
          }
          
          if (state.isTrialCompleted && state.currentTrial != null && !_trialDialogShown) {
            _trialDialogShown = true;
            _showTrialDecisionDialog(state.currentTrial!);
          } else if (!state.isTrialCompleted) {
            // Reset dialog flag when trial is not completed
            _trialDialogShown = false;
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Reference Card
              BlocBuilder<TestBloc, TestState>(
                builder: (context, state) {
                  return QuickReferenceCard(
                    currentStep: _getCurrentStep(state),
                    onShowFullInstructions: () => _showPatientInstructions(),
                  );
                },
              ),
              
              // Patient Info Card
              _buildPatientInfoCard(),
              
              const SizedBox(height: 16),
              
              // Calibration Status
              _buildCalibrationCard(),
              
              const SizedBox(height: 16),
              
              // Live Angle Display
              _buildAngleDisplay(),
              
              const SizedBox(height: 16),
              
              // Test Controls
              _buildTestControls(),
              
              const SizedBox(height: 16),
              
              // Trial Management
              _buildTrialManagement(),
              
              const SizedBox(height: 16),
              
              // Results Summary
              _buildResultsSummary(),
            ],
          ),
        ),
      ),
    );
  }

  void _calibrateTo180() {
    final state = context.read<TestBloc>().state;
    final current = state.liveAngle;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live angle not available for calibration'), backgroundColor: Colors.orange),
      );
      return;
    }
    final newZero = state.zeroOffsetDeg + (180.0 - current);
    context.read<TestBloc>().add(AdjustCalibration(newZero));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calibrated offset set to ${newZero.toStringAsFixed(2)}°')), 
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _buildCalibrationCard() {
    return BlocBuilder<TestBloc, TestState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isCalibrated ? Icons.check_circle : Icons.warning,
                      color: state.isCalibrated ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calibration Status',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.isCalibrated 
                      ? 'Calibrated and ready for testing'
                      : 'Calibration required before testing',
                  style: TextStyle(
                    color: state.isCalibrated ? Colors.green : Colors.orange,
                  ),
                ),
                if (state.isCalibrated) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Baseline Angle: ${state.customBaselineAngle.toStringAsFixed(1)}°',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAngleDisplay() {
    return BlocBuilder<TestBloc, TestState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.rotate_right, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text("Live Angle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAngleGauge(state.liveAngle ?? 180.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAngleGauge(double angle) {
    final maxAngle = 180.0;
    final progress = (angle / maxAngle).clamp(0.0, 1.0);

    Color gaugeColor = Colors.red;
    if (angle > 120) gaugeColor = Colors.orange;
    if (angle > 150) gaugeColor = Colors.green;

    return Container(
      height: 120,
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
    return BlocBuilder<TestBloc, TestState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text("Test Control", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTestControlButtons(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestControlButtons(TestState state) {
    switch (state.status) {
      case TestStatus.idle:
        return Column(
          children: [
            if (!state.isCalibrated) ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showCalibrationFlow();
                },
                icon: const Icon(Icons.tune),
                label: const Text("Start Calibration"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _showEnhancedCalibrationInstructions();
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text("Instructions"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showCalibrationDebug();
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text("Debug"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ]
            else ...[
              ElevatedButton.icon(
                onPressed: () {
                  _showTestInstructions();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start First Trial"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _showCalibrationAdjustment();
                },
                icon: const Icon(Icons.tune),
                label: const Text("Adjust Calibration"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _setCurrentAngleAsBaseline();
                },
                icon: const Icon(Icons.my_location),
                label: const Text("Set Current as Baseline"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _showManualCalibration();
                },
                icon: const Icon(Icons.tune),
                label: const Text("Manual Calibration"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple,
                ),
              ),
            ],
          ],
        );

      case TestStatus.calibrating:
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

      case TestStatus.ready:
        return ElevatedButton.icon(
          onPressed: () {
            _showTestInstructions();
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text("Start Trial"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        );

      case TestStatus.recording:
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
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TestBloc>().add(const StopTest());
              },
              icon: const Icon(Icons.stop),
              label: const Text("Stop Recording"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );

      case TestStatus.trialCompleted:
        return const Text("Trial completed. Please decide whether to keep or discard.");

      case TestStatus.testingEnded:
        return ElevatedButton.icon(
          onPressed: () {
            context.read<TestBloc>().add(const ResetTest());
          },
          icon: const Icon(Icons.refresh),
          label: const Text("Start New Session"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );

      default:
        return const Text("Unknown state");
    }
  }

  Widget _buildTrialManagement() {
    return BlocBuilder<TestBloc, TestState>(
      builder: (context, state) {
        if (!state.hasTrials) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text("Trial Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Trial summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrialStat("Total", state.totalTrials.toString(), Colors.blue),
                    _buildTrialStat("Kept", state.keptTrialsCount.toString(), Colors.green),
                    _buildTrialStat("Discarded", state.discardedTrialsCount.toString(), Colors.red),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (state.canStartNewTrial)
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<TestBloc>().add(const StartNewTrial());
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Next Trial"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    
                    if (state.canEndTesting)
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<TestBloc>().add(const EndTesting());
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text("End Testing"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrialStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSummary() {
    return BlocBuilder<TestBloc, TestState>(
      builder: (context, state) {
        if (!state.hasTrials) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assessment, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text("Results Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Show kept trials
                if (state.keptTrials.isNotEmpty) ...[
                  const Text("Kept Trials:", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...state.keptTrials.map((trial) => _buildTrialItem(trial, true)),
                ],
                
                if (state.discardedTrials.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text("Discarded Trials:", style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  ...state.discardedTrials.map((trial) => _buildTrialItem(trial, false)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrialItem(Trial trial, bool isKept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isKept ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isKept ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isKept ? Icons.check_circle : Icons.cancel,
            color: isKept ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trial.summaryText,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  trial.formattedTimestamp,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalQuality(double quality) {
    Color qualityColor;
    IconData qualityIcon;

    if (quality < 100) {
      qualityColor = Colors.red;
      qualityIcon = Icons.signal_cellular_connected_no_internet_0_bar;
    } else if (quality < 500) {
      qualityColor = Colors.orange;
      qualityIcon = Icons.signal_cellular_alt;
    } else {
      qualityColor = Colors.green;
      qualityIcon = Icons.signal_cellular_4_bar;
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
            "${quality.toInt()} Hz",
            style: TextStyle(color: qualityColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showTrialDecisionDialog(Trial trial) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TrialDecisionDialog(
        trial: trial,
        onKeep: () {
          _trialDialogShown = false; // Reset flag
          context.read<TestBloc>().add(KeepTrial());
        },
        onDiscard: () {
          _trialDialogShown = false; // Reset flag
          context.read<TestBloc>().add(DiscardTrial());
        },
        onKeepWithNotes: (notes) {
          _trialDialogShown = false; // Reset flag
          context.read<TestBloc>().add(KeepTrial(notes: notes));
        },
      ),
    );
  }

  void _showPatientInstructions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientInstructionsScreen(
          patientName: widget.patient.name,
          onContinue: () {
            Navigator.pop(context);
          },
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }


  void _showTestInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TestInstructionDialog(
        currentPhase: 'ready',
        onStart: () {
          Navigator.pop(context);
          context.read<TestBloc>().add(const StartNewTrial());
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getCurrentStep(TestState state) {
    switch (state.status) {
      case TestStatus.idle:
        return state.isCalibrated ? 'test_ready' : 'calibration_position';
      case TestStatus.calibrating:
        return 'calibration_hold';
      case TestStatus.ready:
        return 'test_ready';
      case TestStatus.recording:
        return 'test_recording';
      case TestStatus.trialCompleted:
        return 'test_complete';
      case TestStatus.testingEnded:
        return 'test_complete';
      default:
        return 'test_ready';
    }
  }

  void _showCalibrationDebug() {
    showDialog(
      context: context,
      builder: (context) => const CalibrationDebugDialog(),
    );
  }

  void _showCalibrationAdjustment() {
    final currentState = context.read<TestBloc>().state;
    showDialog(
      context: context,
      builder: (context) => CalibrationAdjustmentDialog(
        currentAngle: currentState.liveAngle ?? currentState.customBaselineAngle,
        currentZeroOffset: currentState.zeroOffsetDeg,
        onAdjust: (zeroOffset) {
          context.read<TestBloc>().add(AdjustCalibration(zeroOffset));
        },
      ),
    );
  }

  void _showEnhancedCalibrationInstructions() {
    showDialog(
      context: context,
      builder: (context) => const EnhancedCalibrationInstructions(),
    );
  }

  void _showCalibrationFlow() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedCalibrationFlowDialog(
        currentStep: 'position',
        onNext: () {
          Navigator.pop(context);
          context.read<TestBloc>().add(const StartCalibration());
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _setCurrentAngleAsBaseline() {
    final currentState = context.read<TestBloc>().state;
    if (currentState.liveAngle != null) {
      context.read<TestBloc>().add(SetCustomBaselineAngle(currentState.liveAngle!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Baseline angle set to ${currentState.liveAngle!.toStringAsFixed(1)}°'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No angle reading available. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showManualCalibration() {
    final currentState = context.read<TestBloc>().state;
    if (currentState.liveAngle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No angle reading available. Please ensure the device is calibrated first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ManualCalibrationDialog(
        currentAngle: currentState.liveAngle!,
        onSetBaseline: (baselineAngle) {
          context.read<TestBloc>().add(SetManualBaseline(baselineAngle));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Baseline angle set to ${baselineAngle.toStringAsFixed(1)}°'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
