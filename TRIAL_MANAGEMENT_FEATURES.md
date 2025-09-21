# Trial Management Features

This document describes the new trial management features implemented in the Reactive Leg Drop app to address clinical workflow requirements.

## 🎯 New Features Implemented

### 1. **Flexible Calibration with Custom Starting Position**
- **Custom Baseline Angle**: Users can now set a custom starting position (default 180°)
- **Dynamic Calibration**: The system adapts to different patient positions and equipment setups
- **Persistent Settings**: Custom baseline angles are saved per patient

### 2. **Multiple Trials Support**
- **Unlimited Trials**: No fixed number of trials - users can run as many as needed
- **Trial Tracking**: Each trial is uniquely identified and timestamped
- **Session Management**: Clear distinction between individual trials and testing sessions

### 3. **Trial Decision System**
- **Keep/Discard Dialog**: After each trial, users get a popup to decide whether to keep or discard
- **Notes Support**: Users can add notes when keeping trials or reasons when discarding
- **Visual Feedback**: Clear indication of trial status (kept vs discarded)

### 4. **Enhanced Data Management**
- **Trial Storage**: All trials are stored with complete metadata
- **Selective Saving**: Only kept trials are included in final results
- **Data Integrity**: Discarded trials are marked but preserved for audit purposes

## 🏗️ Technical Implementation

### New Models

#### Trial Model
```dart
class Trial {
  final String id;                    // Unique trial identifier (T01, T02, etc.)
  final DateTime timestamp;           // When the trial was completed
  final double? dropAngle;           // Calculated drop angle
  final double? dropTimeMs;          // Time to complete drop
  final double? motorVelocity;       // Calculated motor velocity
  final double? peakDropAngle;       // Minimum angle reached
  final bool isKept;                 // Whether trial was kept or discarded
  final String? notes;               // Optional notes or discard reason
}
```

#### Updated Patient Model
```dart
class Patient {
  // ... existing fields ...
  
  // Multiple trials support
  final List<Trial> trials;                    // All trials for this patient
  final int currentTrialNumber;               // Current trial counter
  final double customBaselineAngle;           // Custom starting position
  
  // Helper methods
  List<Trial> get keptTrials;                 // Only kept trials
  List<Trial> get discardedTrials;            // Only discarded trials
  double? get averageDropAngle;               // Average of kept trials
  double? get averageDropTime;                // Average drop time
}
```

### New BLoC Events

#### Trial Management Events
```dart
class StartNewTrial extends TestEvent;        // Start a new trial
class EndTesting extends TestEvent;           // End the testing session
class KeepTrial extends TestEvent;            // Keep the current trial
class DiscardTrial extends TestEvent;         // Discard the current trial
class SetCustomBaselineAngle extends TestEvent; // Set custom starting position
```

### New UI Components

#### Trial Decision Dialog
- **Results Summary**: Shows trial results in a clear format
- **Decision Buttons**: Keep (with optional notes) or Discard (with reason)
- **Notes Field**: Optional text input for additional context
- **Visual Design**: Color-coded results and clear action buttons

#### Enhanced Test Screen
- **Trial Counter**: Shows current trial number and total trials
- **Trial Management**: Next Trial and End Testing buttons
- **Results Summary**: Displays kept and discarded trials separately
- **Status Indicators**: Clear visual feedback for each trial state

## 🔄 Workflow

### 1. **Initial Setup**
1. Select patient from database
2. Navigate to test screen
3. Calibrate system (with custom baseline angle if needed)
4. System is ready for first trial

### 2. **Trial Execution**
1. Click "Start Trial" or "Next Trial"
2. System begins recording sensor data
3. Patient performs leg drop test
4. System detects drop and reaction events
5. Trial completes automatically or manually

### 3. **Trial Decision**
1. Trial completion triggers decision dialog
2. User reviews trial results
3. User chooses to Keep or Discard
4. Optional: Add notes or discard reason
5. System updates trial status and returns to ready state

### 4. **Session Management**
1. Continue with more trials as needed
2. Use "Next Trial" for additional trials
3. Use "End Testing" when session is complete
4. System saves all trial data and returns to idle

## 📊 Data Structure

### Trial Data Storage
```json
{
  "id": "T01",
  "timestamp": "2024-01-15T10:30:00Z",
  "dropAngle": 45.2,
  "dropTimeMs": 1250.0,
  "motorVelocity": 36.2,
  "peakDropAngle": 134.8,
  "isKept": true,
  "notes": "Good trial, patient cooperative"
}
```

### Patient Data with Trials
```json
{
  "id": "P001",
  "name": "John Doe",
  "trials": [
    {
      "id": "T01",
      "timestamp": "2024-01-15T10:30:00Z",
      "dropAngle": 45.2,
      "isKept": true
    },
    {
      "id": "T02", 
      "timestamp": "2024-01-15T10:35:00Z",
      "dropAngle": 38.7,
      "isKept": false,
      "notes": "Patient moved during test"
    }
  ],
  "currentTrialNumber": 2,
  "customBaselineAngle": 180.0
}
```

## 🎨 UI Features

### Test Screen Layout
1. **Patient Info Card**: Patient details and identification
2. **Calibration Status**: Shows calibration state and baseline angle
3. **Live Angle Display**: Real-time angle visualization
4. **Test Controls**: Start/stop trial buttons with status indicators
5. **Trial Management**: Trial counter and session controls
6. **Results Summary**: Kept and discarded trials with visual indicators

### Trial Decision Dialog
1. **Results Display**: Clear presentation of trial metrics
2. **Action Buttons**: Keep (green) and Discard (red) with icons
3. **Notes Field**: Expandable text input for additional context
4. **Timestamp**: When the trial was completed

## 🔧 Configuration Options

### Custom Baseline Angle
- **Default**: 180° (fully extended leg)
- **Range**: 0° to 180°
- **Persistence**: Saved per patient
- **Usage**: Adapts calculations to patient's starting position

### Trial Identification
- **Format**: T01, T02, T03, etc.
- **Uniqueness**: Guaranteed unique within patient
- **Persistence**: Maintained across app sessions

## 📈 Benefits

### For Clinicians
1. **Flexible Workflow**: No fixed trial limits
2. **Quality Control**: Easy trial rejection for bad data
3. **Data Integrity**: Only good trials in final results
4. **Audit Trail**: Complete record of all attempts
5. **Customization**: Adapt to different patient positions

### For Data Analysis
1. **Clean Data**: Only kept trials in analysis
2. **Complete Record**: Full trial history preserved
3. **Metadata**: Notes and timestamps for context
4. **Flexibility**: Custom baseline angles for different setups

### For Patients
1. **Natural Workflow**: No artificial trial limits
2. **Quality Focus**: Emphasis on good trials over quantity
3. **Comfort**: Adaptable to different starting positions
4. **Transparency**: Clear feedback on trial quality

## 🚀 Usage Examples

### Starting a New Testing Session
```dart
// Navigate to test screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TestScreenBloc(patient: patient),
  ),
);

// Start first trial
context.read<TestBloc>().add(const StartNewTrial());
```

### Managing Trial Decisions
```dart
// Keep trial with notes
context.read<TestBloc>().add(KeepTrial(notes: "Excellent trial"));

// Discard trial with reason
context.read<TestBloc>().add(DiscardTrial(reason: "Patient moved"));

// Set custom baseline angle
context.read<TestBloc>().add(SetCustomBaselineAngle(170.0));
```

### Accessing Trial Data
```dart
// Get all kept trials
final keptTrials = patient.keptTrials;

// Get average drop angle
final avgDropAngle = patient.averageDropAngle;

// Get trial count
final totalTrials = patient.totalTrials;
final keptCount = patient.keptTrialsCount;
```

## 🔄 Migration from Legacy

The new system is backward compatible:
- **Legacy Data**: Existing single-trial data is preserved
- **Gradual Migration**: Can use both old and new screens
- **Data Conversion**: Legacy data can be converted to trial format
- **UI Choice**: Users can choose between old and new interfaces

## 🎯 Future Enhancements

1. **Trial Templates**: Predefined trial configurations
2. **Batch Operations**: Keep/discard multiple trials
3. **Export Options**: Export kept trials only or all trials
4. **Analytics**: Trial success rates and patterns
5. **Custom Metrics**: Additional trial measurements
6. **Session Reports**: Comprehensive testing summaries

This implementation provides a robust, flexible trial management system that addresses the clinical workflow requirements while maintaining data integrity and user experience.


