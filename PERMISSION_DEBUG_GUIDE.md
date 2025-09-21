# Permission Debug Guide

This guide helps debug why storage permissions might not be requested properly in the RLD Mobile App.

## 🔍 **Debug Features Added**

### **1. Enhanced Logging**
The app now includes detailed logging for permission requests:
- **🔐 Permission checks**: Shows current permission status
- **📱 Permission requests**: Shows what permissions are being requested
- **✅ Success messages**: Confirms when permissions are granted
- **❌ Error messages**: Shows when permissions fail

### **2. Debug Button**
Added a **bug report icon** (🐛) in the Export Data screen:
- **"Test Permissions"** button to force request all storage permissions
- **Real-time feedback** on permission status
- **Debug information** in the status message

### **3. Comprehensive Permission Check**
The app now checks multiple storage-related permissions:
- **Storage**: Basic storage access
- **Manage External Storage**: Full file system access
- **Photos**: Access to photos/media
- **Videos**: Access to video files
- **Audio**: Access to audio files

## 🚀 **How to Debug**

### **Step 1: Check Console Logs**
When you try to export data, look for these log messages:
```
🔐 Checking storage permissions...
📱 Storage status: [status]
📱 Manage external storage status: [status]
📱 Photos status: [status]
📱 Videos status: [status]
📱 Audio status: [status]
```

### **Step 2: Use Debug Button**
1. **Go to Export Data screen**
2. **Tap bug report icon** (🐛) in top-right
3. **Watch status message** for permission results
4. **Check console logs** for detailed information

### **Step 3: Check Permission Status**
1. **Tap security icon** (🔒) in Export Data screen
2. **View current permission status**
3. **See which permissions are granted/denied**

## 🔧 **Common Issues & Solutions**

### **Issue 1: No Permission Dialog Appears**
**Possible Causes**:
- Permissions already granted
- Permission request not triggered
- Android version compatibility issue

**Debug Steps**:
1. Check console logs for permission status
2. Use debug button to force request permissions
3. Check permission status dialog

### **Issue 2: Permission Denied Immediately**
**Possible Causes**:
- User previously denied permission
- Permission permanently denied
- System permission policy

**Debug Steps**:
1. Check console logs for denial reason
2. Use debug button to see detailed status
3. Guide user to app settings

### **Issue 3: Permission Granted But Export Fails**
**Possible Causes**:
- Permission check logic issue
- File system access problem
- Export service error

**Debug Steps**:
1. Check if permission is actually granted
2. Verify file system access
3. Check export service logs

## 📱 **Android Version Compatibility**

### **Android 13+ (API 33+)**
- **New permission model**: More granular permissions
- **Required permissions**: Photos, Videos, Audio instead of Storage
- **Manage External Storage**: May not be available

### **Android 11-12 (API 30-32)**
- **Scoped storage**: Limited file system access
- **Storage permission**: May not work as expected
- **Manage External Storage**: Required for full access

### **Android 10 and Below (API 29-)**
- **Legacy storage**: Full file system access
- **Storage permission**: Should work normally
- **Manage External Storage**: Not available

## 🛠️ **Debug Commands**

### **Check Permission Status**
```dart
// In your code
final hasPermission = await PermissionService.hasStoragePermissions();
print('Has storage permission: $hasPermission');
```

### **Force Request Permissions**
```dart
// In your code
final result = await PermissionService.forceRequestStoragePermissions(context);
print('Force request result: $result');
```

### **Check Individual Permissions**
```dart
// In your code
final storageStatus = await Permission.storage.status;
final photosStatus = await Permission.photos.status;
print('Storage: $storageStatus, Photos: $photosStatus');
```

## 📊 **Permission Status Meanings**

### **PermissionStatus.granted**
- **Meaning**: Permission is granted
- **Action**: Proceed with file operations
- **Log**: ✅ Permission granted

### **PermissionStatus.denied**
- **Meaning**: Permission is denied but can be requested
- **Action**: Request permission again
- **Log**: ❌ Permission denied

### **PermissionStatus.permanentlyDenied**
- **Meaning**: Permission is permanently denied
- **Action**: Guide user to app settings
- **Log**: ❌ Permission permanently denied

### **PermissionStatus.restricted**
- **Meaning**: Permission is restricted by system
- **Action**: Explain limitation to user
- **Log**: ⚠️ Permission restricted

## 🎯 **Testing Steps**

### **1. Fresh Install Test**
1. **Uninstall app** completely
2. **Reinstall app** from APK
3. **Try export** - should request permissions
4. **Check logs** for permission flow

### **2. Permission Denial Test**
1. **Deny permission** when requested
2. **Try export again** - should show explanation dialog
3. **Check logs** for denial handling
4. **Use debug button** to retry

### **3. Permission Grant Test**
1. **Grant permission** when requested
2. **Try export** - should work normally
3. **Check logs** for success flow
4. **Verify files** are created

## 🔍 **Log Analysis**

### **Successful Permission Request**
```
🔐 Checking storage permissions...
📱 Storage status: PermissionStatus.denied
📱 Photos status: PermissionStatus.denied
🔐 Requesting permissions: [Permission.storage, Permission.photos]
📱 Permission request results: {Permission.storage: PermissionStatus.granted, Permission.photos: PermissionStatus.granted}
✅ All storage permissions granted
```

### **Failed Permission Request**
```
🔐 Checking storage permissions...
📱 Storage status: PermissionStatus.denied
📱 Photos status: PermissionStatus.denied
🔐 Requesting permissions: [Permission.storage, Permission.photos]
📱 Permission request results: {Permission.storage: PermissionStatus.denied, Permission.photos: PermissionStatus.denied}
❌ Not all permissions granted, showing dialog
```

### **Already Granted Permissions**
```
🔐 Checking storage permissions...
📱 Storage status: PermissionStatus.granted
📱 Photos status: PermissionStatus.granted
✅ All storage permissions already granted
```

## 🚀 **Quick Fixes**

### **If No Permission Dialog Appears**
1. **Use debug button** to force request
2. **Check Android version** compatibility
3. **Verify permission declarations** in manifest
4. **Check console logs** for errors

### **If Permission Denied Immediately**
1. **Check if permanently denied**
2. **Guide user to app settings**
3. **Use alternative permission methods**
4. **Check system permission policies**

### **If Export Fails After Permission Granted**
1. **Verify permission is actually granted**
2. **Check file system access**
3. **Test with debug button**
4. **Check export service logs**

## 🎉 **Expected Behavior**

### **First Time Export**
1. **Permission dialog appears** automatically
2. **User grants permission**
3. **Export proceeds** normally
4. **Files are created** successfully

### **Permission Denied**
1. **Explanation dialog** appears
2. **User can retry** or go to settings
3. **Debug button** available for testing
4. **Clear error messages** shown

### **Permission Already Granted**
1. **No dialog appears**
2. **Export proceeds** immediately
3. **Success message** shown
4. **Files created** normally

The debug features should help identify exactly why permissions aren't being requested and provide clear solutions!


