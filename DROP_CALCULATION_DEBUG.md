# Drop Calculation Debug Guide

## 🔍 **Issues Identified and Fixed**

I found several critical issues with the drop calculation after calibration:

### **1. Angle Calculation Logic**
- **Problem**: The angle calculation in `_legAngleInPlane` was using incorrect baseline angle logic
- **Fix**: Updated to properly use `customBaselineAngle` and `zeroOffsetDeg`

### **2. Missing Debug Information**
- **Problem**: No visibility into what's happening during calibration and drop detection
- **Fix**: Added comprehensive debug logging

### **3. Calibration Data Validation**
- **Problem**: No verification that calibration data is being set correctly
- **Fix**: Added logging to track calibration process

## 🔧 **What I Fixed**

### **1. Updated Angle Calculation**
```dart
// OLD (incorrect):
final leg = (_baselineAngle - (rawInPlane + state.zeroOffsetDeg)).clamp(0.0, 180.0);

// NEW (correct):
final angleDiff = rawInPlane - state.zeroOffsetDeg;
final leg = (state.customBaselineAngle - angleDiff).clamp(0.0, 180.0);
```

### **2. Added Debug Logging**
- **Calibration process**: Logs gRef, planeU, planeV capture
- **Angle calculation**: Logs all intermediate values
- **Drop detection**: Logs conditions and thresholds

## 🚀 **How to Test**

### **Step 1: Install Updated App**
1. **App is already installed** with debug logging
2. **Open the app** and go to test screen

### **Step 2: Test Calibration**
1. **Start calibration** process
2. **Watch console logs** for:
   ```
   🔍 Calibration: gRef captured = [values]
   🔍 Calibration: planeU = [values], planeV = [values]
   🔍 Calibration: Complete! Ready for testing.
   ```

### **Step 3: Test Drop Detection**
1. **Start recording** after calibration
2. **Move your leg** to simulate a drop
3. **Watch console logs** for:
   ```
   🔍 Angle calculation: refU=, refV=, curU=, curV=
   🔍 Raw in plane: [angle], zeroOffset: [offset], customBaseline: [baseline]
   🔍 Final leg angle: [angle]
   🔍 Drop detection: liveAngle=[angle], gyroInPlane=[velocity], omegaDegPerSec=[velocity]
   🔍 Conditions: fastDown=[bool], accelDip=[bool], fallbackFast=[bool]
   🔍 Thresholds: omegaDrop=[threshold], accelDipFrac=[threshold]
   ```

### **Step 4: Look for Drop Detection**
- **If drop is detected**: You'll see `🎯 DROP DETECTED!`
- **If not detected**: Check the threshold values and conditions

## 🔍 **Debug Information to Watch**

### **Calibration Success Indicators**
```
🔍 Calibration: gRef captured = [Vector3 with values]
🔍 Calibration: planeU = [Vector3 with values], planeV = [Vector3 with values]
🔍 Calibration: Complete! Ready for testing.
```

### **Angle Calculation Debug**
```
🔍 Angle calculation: refU=[value], refV=[value], curU=[value], curV=[value]
🔍 Raw in plane: [angle], zeroOffset: [offset], customBaseline: [baseline]
🔍 Final leg angle: [calculated angle]
```

### **Drop Detection Debug**
```
🔍 Drop detection: liveAngle=[angle], gyroInPlane=[velocity], omegaDegPerSec=[velocity]
🔍 Conditions: fastDown=[bool], accelDip=[bool], fallbackFast=[bool]
🔍 Thresholds: omegaDrop=[threshold], accelDipFrac=[threshold]
```

## 🐛 **Common Issues to Check**

### **1. Calibration Issues**
- **If calibration fails**: Check that you're flexing your leg 5-20° during flex phase
- **If gRef is zero**: Sensor might not be working properly
- **If planeU/planeV are zero**: Flex movement might be too small or too large

### **2. Angle Calculation Issues**
- **If liveAngle is always 180**: Calibration data might not be set
- **If angles don't change**: Sensor data might not be updating
- **If angles are wrong**: Check the calculation logic

### **3. Drop Detection Issues**
- **If no drops detected**: Check thresholds and conditions
- **If false drops**: Thresholds might be too sensitive
- **If drops detected but no reaction**: Reaction detection might have issues

## 📱 **Expected Behavior**

### **✅ Successful Calibration**
1. **gRef captured** with non-zero values
2. **planeU and planeV** captured with non-zero values
3. **Status changes** to "ready"

### **✅ Successful Drop Detection**
1. **liveAngle changes** as you move your leg
2. **Drop conditions** become true when you drop your leg
3. **"DROP DETECTED!"** message appears

### **✅ Successful Reaction Detection**
1. **Reaction conditions** become true when you return your leg
2. **Trial completes** with proper timing

## 🔧 **Next Steps**

1. **Test the app** with the debug logging
2. **Check console output** for the debug messages
3. **Identify which part** of the process is failing
4. **Report back** with the specific debug output you see

The debug logging will help us identify exactly where the drop calculation is failing!


