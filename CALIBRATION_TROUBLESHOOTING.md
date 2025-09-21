# Calibration Troubleshooting Guide

This guide will help you diagnose and fix calibration issues in the Reactive Leg Drop app.

## 🔍 **Quick Diagnosis Steps**

### 1. **Use the Debug Tool**
- Open the test screen for any patient
- Tap the **bug icon** (🐛) in the top-right corner
- This will show you:
  - If sensors are working
  - How many samples are being received
  - Real-time acceleration data
  - Step-by-step calibration process

### 2. **Check Common Issues**

#### **Sensors Not Working**
- **Symptoms**: Debug tool shows "Sensor error" or no samples
- **Causes**: 
  - Device doesn't have accelerometer
  - App permissions not granted
  - Device in airplane mode
- **Solutions**:
  - Check device has accelerometer
  - Grant motion sensor permissions
  - Disable airplane mode
  - Restart the app

#### **Calibration Fails at Reference Capture**
- **Symptoms**: Fails during "Hold Still" phase
- **Causes**:
  - Device moving too much
  - Not holding still long enough
  - Sensor noise
- **Solutions**:
  - Place device on stable surface
  - Hold completely still for 10-15 seconds
  - Try again in a quieter environment

#### **Calibration Fails at Flex Capture**
- **Symptoms**: Fails during "Gentle Flex" phase
- **Causes**:
  - Flex angle too small (< 5°)
  - Flex angle too large (> 25°)
  - Twisting during flex
  - Not returning to starting position
- **Solutions**:
  - Flex leg 5-20° (about 2-3 inches)
  - Keep movement in one plane (no twisting)
  - Return to exact starting position
  - Try a more controlled, slower movement

## 📱 **Step-by-Step Calibration Process**

### **Phase 1: Device Setup**
1. **Secure the Device**
   - Place device firmly on leg
   - Ensure it won't move during test
   - Test by gently moving leg - device should stay in place

2. **Check Signal Quality**
   - Look at signal quality indicator (top-right)
   - Should show green with high Hz value
   - If red/low, check device placement

### **Phase 2: Reference Capture**
1. **Hold Still**
   - Keep leg in starting position
   - Don't move for 10-15 seconds
   - Breathe normally but keep leg still
   - Wait for "Calibrating..." to complete

2. **Troubleshooting Reference Issues**
   - If it fails, try holding still longer
   - Check device isn't loose
   - Ensure stable environment

### **Phase 3: Flex Capture**
1. **Gentle Flex**
   - When prompted, flex leg 5-20°
   - Movement should be smooth and controlled
   - No twisting or side-to-side movement
   - Hold flex for 2-3 seconds

2. **Return to Start**
   - Slowly return to exact starting position
   - Don't overshoot or undershoot
   - Hold position for 2-3 seconds

3. **Troubleshooting Flex Issues**
   - If angle too small: flex more (but stay under 25°)
   - If angle too large: flex less (but stay over 5°)
   - If twisting detected: keep movement in one plane
   - If fails: try slower, more controlled movement

## 🛠️ **Technical Troubleshooting**

### **Check App Permissions**
1. Go to device Settings
2. Find "Apps" or "Application Manager"
3. Find "Reactive Leg Drop" app
4. Check "Permissions"
5. Ensure "Motion & Fitness" or "Sensors" is enabled

### **Check Device Compatibility**
- **Required**: Accelerometer sensor
- **Recommended**: Gyroscope sensor
- **Test**: Use debug tool to verify sensors work

### **Check Environment**
- **Stable Surface**: Place device on stable surface during reference
- **Quiet Environment**: Avoid vibrations and movement
- **Good Lighting**: Ensure you can see the device clearly
- **Comfortable Position**: Patient should be comfortable

## 🚨 **Common Error Messages & Solutions**

### **"Calibration timeout - please try again"**
- **Cause**: Process took too long (>10 seconds)
- **Solution**: 
  - Check device is secure
  - Ensure stable environment
  - Try again with faster movements

### **"Calibration failed. Please ensure you flex your leg 5-20° without twisting"**
- **Cause**: Flex angle outside acceptable range
- **Solution**:
  - Measure 5-20° (about 2-3 inches of movement)
  - Keep movement in one plane
  - Practice the movement before calibrating

### **"Sensor error: [error message]"**
- **Cause**: Hardware or permission issue
- **Solution**:
  - Check device has accelerometer
  - Grant app permissions
  - Restart device
  - Reinstall app if needed

### **"Calibration failed: [technical error]"**
- **Cause**: Internal app error
- **Solution**:
  - Restart the app
  - Check device storage space
  - Update app if available
  - Contact support with error details

## 📊 **Debug Information**

### **What to Check in Debug Tool**
1. **Sample Count**: Should increase steadily
2. **Acceleration Values**: Should change when device moves
3. **Status Messages**: Should progress through steps
4. **Error Messages**: Note any specific errors

### **Normal Values**
- **Acceleration X**: Usually 0 ± 2
- **Acceleration Y**: Usually 0 ± 2  
- **Acceleration Z**: Usually 9.8 ± 2 (gravity)
- **Sample Rate**: 100+ Hz (green indicator)

### **Problem Values**
- **All zeros**: Sensor not working
- **No change**: Device not moving
- **Extreme values**: Device loose or faulty
- **Low sample rate**: Performance issue

## 🔄 **Calibration Best Practices**

### **For Clinicians**
1. **Explain the Process**: Show patients what to expect
2. **Demonstrate Movement**: Show the correct flex motion
3. **Check Device Placement**: Ensure secure attachment
4. **Monitor Progress**: Watch for issues during calibration
5. **Have Backup Plan**: Know how to troubleshoot common issues

### **For Patients**
1. **Listen to Instructions**: Follow the step-by-step guidance
2. **Practice First**: Try the movement before calibrating
3. **Stay Relaxed**: Don't tense up during calibration
4. **Ask Questions**: Speak up if something isn't clear
5. **Be Patient**: Calibration may take a few tries

## 🆘 **When to Contact Support**

Contact support if you experience:
- Persistent sensor errors after checking permissions
- Calibration fails repeatedly with correct technique
- App crashes during calibration
- Unusual error messages not covered in this guide
- Hardware issues with the device

### **Information to Provide**
- Device model and OS version
- App version
- Exact error messages
- Steps you've already tried
- Debug tool output (if available)

## 🎯 **Success Indicators**

You'll know calibration is successful when:
- ✅ No error messages appear
- ✅ Status changes to "Ready for Testing"
- ✅ Live angle display shows current leg position
- ✅ "Start Trial" button becomes available
- ✅ Signal quality indicator is green

## 🔧 **Quick Fixes Summary**

| Problem | Quick Fix |
|---------|-----------|
| Sensors not working | Check permissions, restart app |
| Reference capture fails | Hold still longer, check device placement |
| Flex capture fails | Adjust flex angle (5-20°), no twisting |
| Timeout errors | Move faster, check device security |
| App crashes | Restart device, reinstall app |
| Low signal quality | Check device placement, environment |

Remember: Calibration is a critical step for accurate measurements. Take your time and follow the instructions carefully for best results!


