# Runtime Permissions Guide

This guide explains how the RLD Mobile App now handles runtime permissions for file operations and sharing.

## 🔐 **Permission System Overview**

The app now properly requests permissions at runtime instead of just declaring them in the manifest. This ensures better user experience and compliance with modern Android/iOS permission models.

## 📱 **Permissions Required**

### **Storage Permissions**
- **Purpose**: Save and access CSV files
- **When requested**: Before any export operation
- **User benefit**: Can save patient data locally and share files

### **Camera Permission** (Future)
- **Purpose**: Take photos of documents or patients
- **When requested**: When camera features are used
- **User benefit**: Document patient conditions or test results

## 🚀 **How It Works**

### **1. Automatic Permission Requests**
When you try to export data, the app will:
1. **Check current permissions**
2. **Request permissions** if not granted
3. **Show explanation dialog** if needed
4. **Proceed with export** if granted
5. **Show error message** if denied

### **2. Permission Status Monitoring**
- **Security icon** (🔒) in Export Data screen
- **Real-time status** of all permissions
- **Grant/deny status** for each permission
- **Direct access** to app settings

## 🎯 **User Experience**

### **First Time Export**
1. **Tap "Export Data"** button
2. **Permission dialog appears** automatically
3. **Read explanation** of why permission is needed
4. **Tap "Allow"** to grant permission
5. **Export proceeds** normally

### **Permission Denied**
1. **Explanation dialog** appears
2. **"Grant Permission"** button opens app settings
3. **User manually enables** storage permission
4. **Return to app** and try export again

### **Permission Status Check**
1. **Tap security icon** (🔒) in Export Data screen
2. **View current status** of all permissions
3. **Grant missing permissions** directly
4. **See which permissions** are required

## 🔧 **Technical Implementation**

### **Permission Service**
```dart
// Request storage permissions
await PermissionService.requestStoragePermissions(context);

// Check permission status
bool hasPermission = await PermissionService.hasStoragePermissions();

// Show permission status dialog
PermissionService.showPermissionStatus(context);
```

### **Export Integration**
```dart
// Before any export operation
final hasPermission = await PermissionService.requestStoragePermissions(context);
if (!hasPermission) {
  throw Exception('Storage permission is required to export data');
}
```

### **Error Handling**
- **Graceful degradation**: Clear error messages
- **User guidance**: How to grant permissions
- **Retry mechanism**: Try again after granting
- **Fallback options**: Alternative access methods

## 📋 **Permission Dialog Content**

### **Storage Permission Dialog**
**Title**: "Storage Permission Required"

**Message**: 
- "Storage permission is needed to save and share CSV files with your patient data."

**Why we need this permission**:
- • Save CSV files with patient data
- • Share files via email or cloud storage
- • Export data for research and analysis
- • Backup patient information locally

**Actions**:
- **Cancel**: Dismiss dialog
- **Grant Permission**: Open app settings

## 🎨 **UI Elements Added**

### **Export Data Screen**
- **Security icon** (🔒): Check permission status
- **Permission status dialog**: View all permissions
- **Clear error messages**: When permissions denied
- **Progress indicators**: "Requesting permissions..."

### **Permission Status Dialog**
- **Visual indicators**: ✅ Granted, ❌ Denied
- **Permission names**: Storage, Camera, etc.
- **Action buttons**: Grant missing permissions
- **Status explanation**: Why each permission is needed

## 🔄 **Permission Flow**

### **Export All Data**
1. **User taps** "Export All Data"
2. **App checks** storage permissions
3. **If denied**: Show permission dialog
4. **If granted**: Proceed with export
5. **Show progress**: "Requesting permissions..."
6. **Complete export**: Success message

### **Export Individual Patient**
1. **User taps** patient in list
2. **App checks** storage permissions
3. **If denied**: Show permission dialog
4. **If granted**: Export patient data
5. **Show progress**: "Requesting permissions..."
6. **Complete export**: Success message

## 🛠️ **Troubleshooting**

### **"Permission Denied" Error**
**Cause**: User denied storage permission
**Solution**: 
1. Tap security icon (🔒) in Export Data screen
2. Tap "Grant Storage" button
3. Enable storage permission in settings
4. Return to app and try export again

### **"Storage Permission Required" Error**
**Cause**: Permission not granted before export
**Solution**:
1. The app will automatically request permission
2. Tap "Allow" in the permission dialog
3. If denied, go to app settings and enable manually

### **Permission Dialog Not Appearing**
**Cause**: Permission already granted or system issue
**Solution**:
1. Check permission status with security icon
2. Try restarting the app
3. Check device storage permissions in settings

## 📱 **Platform Differences**

### **Android**
- **Runtime permissions**: Required for Android 6+
- **Storage permission**: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
- **Manage external storage**: For Android 11+
- **Permission dialog**: System native dialog

### **iOS**
- **Privacy descriptions**: Required in Info.plist
- **User-friendly messages**: Explain why permission needed
- **Settings redirect**: Direct to app settings
- **Permission status**: Real-time monitoring

## 🎉 **Benefits**

### **For Users**
- **Clear understanding**: Why permissions are needed
- **Easy granting**: One-tap permission requests
- **Status visibility**: See what permissions are granted
- **Better control**: Grant/deny as needed

### **For Developers**
- **Compliance**: Follows platform guidelines
- **Better UX**: Smooth permission flow
- **Error handling**: Graceful permission failures
- **Maintainable**: Centralized permission logic

### **For App Store**
- **Approval**: Follows store guidelines
- **Privacy**: Transparent permission usage
- **User trust**: Clear permission explanations
- **Compliance**: Meets platform requirements

## 🚀 **Usage Examples**

### **Check Permission Status**
```dart
// In your widget
IconButton(
  onPressed: () => PermissionService.showPermissionStatus(context),
  icon: Icon(Icons.security),
  tooltip: 'Permission Status',
)
```

### **Request Permission Before Operation**
```dart
// Before file operations
final hasPermission = await PermissionService.requestStoragePermissions(context);
if (!hasPermission) {
  // Handle permission denied
  return;
}
// Proceed with file operations
```

### **Handle Permission Errors**
```dart
try {
  await CsvExportService.exportAllData(context);
} catch (e) {
  if (e.toString().contains('permission')) {
    // Show permission explanation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please grant storage permission to export data')),
    );
  }
}
```

## 🎯 **Best Practices**

### **Request Permissions When Needed**
- **Don't request all at once**: Request when feature is used
- **Explain clearly**: Why permission is needed
- **Provide alternatives**: If permission denied
- **Respect user choice**: Don't repeatedly ask

### **Handle Permission States**
- **Granted**: Proceed with operation
- **Denied**: Show explanation and alternatives
- **Permanently denied**: Guide to settings
- **Not determined**: Request permission

### **User Experience**
- **Clear messaging**: What permission does
- **Easy access**: Quick permission status check
- **Graceful fallbacks**: Alternative methods
- **No blocking**: App works without permissions

The permission system now provides a smooth, user-friendly experience while ensuring the app can properly save and share CSV files with patient data!


