# Storage Permission Test Guide

## 🎯 **Simplified Approach**

I've simplified the app to only request the basic storage permissions that should definitely show up in your device settings.

## 📱 **What Changed**

### **Android Manifest (Simplified)**
```xml
<!-- Essential storage permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### **Permission Service (Simplified)**
- **Only requests**: `Permission.storage`
- **Removed**: All the complex Android 13+ permissions
- **Focus**: Basic storage access that works on all Android versions

## 🚀 **How to Test**

### **Step 1: Fresh Install**
1. **Uninstall the app** completely from your device
2. **Install the new APK** (the one we just built)
3. **Open the app**

### **Step 2: Check Device Settings**
1. **Go to Settings** → **Apps** → **accelerometer** (or whatever the app name is)
2. **Tap "Permissions"**
3. **You should now see "Storage" permission** listed
4. **If it's not there, the app might not be installed properly**

### **Step 3: Test Permission Request**
1. **Open the app**
2. **Go to "Export Data" screen**
3. **Tap "Export All Data"**
4. **Permission dialog should appear** asking for storage permission
5. **Grant the permission**

### **Step 4: Verify in Settings**
1. **Go back to Settings** → **Apps** → **accelerometer**
2. **Tap "Permissions"**
3. **Storage permission should now be "Allowed"**

## 🔍 **What to Look For**

### **In Device Settings**
- **App should appear** in the apps list
- **Storage permission should be visible** in the permissions list
- **Permission should be toggleable** (can be turned on/off)

### **In App**
- **Permission dialog should appear** when trying to export
- **Console logs should show** permission request process
- **Export should work** after granting permission

## 🐛 **If Still Not Working**

### **Check App Installation**
1. **Make sure you uninstalled** the old version completely
2. **Install the new APK** from the build folder
3. **Check if the app appears** in your app drawer

### **Check Android Version**
1. **Go to Settings** → **About Phone** → **Android Version**
2. **Note your Android version** (this affects which permissions are available)

### **Try Manual Permission Grant**
1. **Go to Settings** → **Apps** → **accelerometer**
2. **Tap "Permissions"**
3. **Look for "Storage" or "Files and Media"**
4. **Toggle it ON** if available

## 📋 **Expected Results**

### **✅ Success Indicators**
- App appears in device settings
- Storage permission is visible and toggleable
- Permission dialog appears when exporting
- Export functionality works after granting permission

### **❌ Failure Indicators**
- App doesn't appear in device settings
- No storage permission visible
- No permission dialog when exporting
- Export fails with permission error

## 🔧 **Next Steps**

If this simplified approach works, we can add back the Android 13+ permissions later. The key is to get the basic storage permission working first.

**Try the fresh install and let me know what you see in your device settings!**


