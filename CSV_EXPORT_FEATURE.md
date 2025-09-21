# CSV Export Feature

This document describes the comprehensive CSV export functionality implemented for the RLD Mobile App, allowing users to export patient and trial data in various formats.

## 🎯 **Overview**

The CSV export feature provides multiple ways to export patient and trial data:
- **All Data Export**: Export all patients and their trials
- **Individual Patient Export**: Export specific patient data
- **Multiple File Formats**: Different CSV files for different data views
- **Share Functionality**: Easy sharing of exported files
- **File Management**: View, share, and delete exported files

## 📁 **Export Types**

### **1. Patients Summary CSV**
**File**: `patients_summary_YYYYMMDD_HHMMSS.csv`

**Contains**:
- Patient basic information (ID, Name, Age, Gender, Condition)
- Timestamps (Created At, Last Modified)
- Trial statistics (Total, Kept, Discarded)
- Calibration information
- Custom baseline angle

**Sample Data**:
```csv
Patient ID,Name,Age,Gender,Condition,Created At,Last Modified,Total Trials,Kept Trials,Discarded Trials,Calibrated At,Drops Since Cal,Custom Baseline Angle
P001,John Doe,45,Male,Parkinson's,2024-01-15T10:30:00Z,2024-01-15T14:45:00Z,5,4,1,2024-01-15T10:35:00Z,3,180.0
```

### **2. Individual Patient Summary CSV**
**File**: `patient_{ID}_summary_YYYYMMDD_HHMMSS.csv`

**Contains**:
- Complete patient profile
- All calibration data
- Trial statistics
- Timestamps

**Sample Data**:
```csv
Field,Value
Patient ID,P001
Name,John Doe
Age,45
Gender,Male
Condition,Parkinson's
Total Trials,5
Kept Trials,4
Calibration Zero Offset,2.5
Calibration Ref X,0.0
Calibration Ref Y,0.0
Calibration Ref Z,1.0
```

### **3. Patient Trials CSV**
**File**: `patient_{ID}_trials_YYYYMMDD_HHMMSS.csv`

**Contains**:
- All trials for a specific patient
- Trial results and measurements
- Keep/Discard status
- Notes and discard reasons

**Sample Data**:
```csv
Trial ID,Timestamp,Initial Z,Final Z,Drop Angle (deg),Drop Time (ms),Motor Velocity,Peak Drop Angle (deg),Is Kept,Notes,Discard Reason
T001,2024-01-15T10:40:00Z,0.95,0.12,83.0,1250.0,0.066,83.0,Yes,Good trial,
T002,2024-01-15T10:45:00Z,0.92,0.15,77.0,1180.0,0.065,77.0,No,,Patient moved
```

### **4. Combined Trials CSV**
**File**: `all_trials_YYYYMMDD_HHMMSS.csv`

**Contains**:
- All trials from all patients
- Patient information for each trial
- Complete trial data
- Cross-patient analysis ready

**Sample Data**:
```csv
Patient ID,Patient Name,Patient Age,Patient Gender,Patient Condition,Trial ID,Timestamp,Drop Angle (deg),Drop Time (ms),Is Kept,Notes
P001,John Doe,45,Male,Parkinson's,T001,2024-01-15T10:40:00Z,83.0,1250.0,Yes,Good trial
P002,Jane Smith,52,Female,MS,T001,2024-01-15T11:00:00Z,91.0,1380.0,Yes,
```

## 🚀 **How to Use**

### **Access Export Screen**

#### **From Welcome Screen**
1. Tap **"Export Data"** button (green button)
2. Export screen opens with all options

#### **From Patient Database**
1. Tap **download icon** in app bar
2. Export screen opens with patient list

### **Export Options**

#### **Export All Data**
1. Tap **"Export All Data"** button
2. System exports all patients and trials
3. Creates multiple CSV files
4. Shows success message

#### **Export Individual Patient**
1. Scroll to patient list
2. Tap on any patient
3. System exports that patient's data
4. Creates patient-specific CSV files

#### **Share Files**
1. Tap **share icon** in app bar
2. Select files to share
3. Choose sharing method (email, cloud, etc.)

#### **Manage Files**
1. View all exported files
2. See file sizes and timestamps
3. Delete files if needed
4. Share individual or all files

## 📊 **Data Fields Explained**

### **Patient Data Fields**
- **Patient ID**: Unique identifier
- **Name**: Patient's full name
- **Age**: Patient's age
- **Gender**: Male/Female/Other
- **Condition**: Medical condition
- **Created At**: When patient was added
- **Last Modified**: Last update time
- **Total Trials**: Number of trials conducted
- **Kept Trials**: Number of kept trials
- **Discarded Trials**: Number of discarded trials
- **Calibrated At**: Last calibration timestamp
- **Drops Since Cal**: Trials since last calibration
- **Custom Baseline Angle**: Starting position angle

### **Trial Data Fields**
- **Trial ID**: Unique trial identifier
- **Timestamp**: When trial was conducted
- **Initial Z**: Starting Z-axis value
- **Final Z**: Ending Z-axis value
- **Drop Angle**: Angle of leg drop (degrees)
- **Drop Time**: Time to complete drop (milliseconds)
- **Motor Velocity**: Calculated motor velocity
- **Peak Drop Angle**: Maximum drop angle reached
- **Is Kept**: Whether trial was kept (Yes/No)
- **Notes**: Additional notes for kept trials
- **Discard Reason**: Reason for discarding trial

### **Calibration Data Fields**
- **Calibration Zero Offset**: Zero point offset
- **Calibration Ref X/Y/Z**: Reference gravity vector
- **Calibration U X/Y/Z**: Sagittal plane U vector
- **Calibration V X/Y/Z**: Sagittal plane V vector

## 🔧 **Technical Implementation**

### **File Structure**
```
lib/
├── services/
│   └── csv_export_service.dart    # Core export logic
├── screens/
│   └── csv_export_screen.dart     # Export UI
└── models/
    ├── patients.dart              # Patient data model
    └── trial.dart                 # Trial data model
```

### **Key Components**

#### **CsvExportService**
- **exportAllData()**: Export all patients and trials
- **exportPatientData()**: Export specific patient
- **shareCsvFiles()**: Share exported files
- **getExportedFiles()**: List exported files
- **clearExportedFiles()**: Delete all exports

#### **CsvExportScreen**
- **Export Options**: UI for different export types
- **Patient List**: Individual patient export
- **File Management**: View and manage exports
- **Status Display**: Export progress and results

### **File Storage**
- **Location**: `Documents/RLD_Exports/`
- **Naming**: Timestamp-based file names
- **Format**: Standard CSV with proper escaping
- **Encoding**: UTF-8

## 📱 **User Interface**

### **Export Screen Layout**

#### **Header**
- **Title**: "CSV Export"
- **Share Button**: Share all files
- **Delete Button**: Clear all files

#### **Export Status**
- **Success**: Green banner with checkmark
- **Error**: Red banner with error message
- **Progress**: Loading indicator during export

#### **Export Options Card**
- **Export All Data**: Blue button with download icon
- **Individual Patients**: List of patients with export buttons

#### **Patient List**
- **Patient Info**: Name, age, gender, condition
- **Trial Stats**: Total trials, kept trials
- **Export Button**: Individual export option

#### **Exported Files**
- **File List**: All exported CSV files
- **File Info**: Name, size, timestamp
- **Share Button**: Share individual files

## 🎨 **Visual Design**

### **Color Scheme**
- **Primary**: Green for export actions
- **Success**: Green for success messages
- **Error**: Red for error messages
- **Info**: Blue for information

### **Icons**
- **Download**: Export actions
- **Share**: File sharing
- **Delete**: File deletion
- **Person**: Patient information
- **Description**: CSV files

### **Layout**
- **Cards**: Organized content sections
- **Lists**: Patient and file listings
- **Buttons**: Clear action buttons
- **Status**: Prominent status messages

## 🔒 **Data Privacy & Security**

### **Local Storage**
- Files stored locally on device
- No cloud uploads by default
- User controls file sharing

### **Data Anonymization**
- Patient names can be anonymized
- Sensitive data can be excluded
- Export options for different privacy levels

### **File Management**
- User can delete all exports
- No automatic cloud backup
- Full control over data sharing

## 📈 **Use Cases**

### **Clinical Research**
- Export all patient data for analysis
- Cross-patient trial comparisons
- Statistical analysis ready format

### **Patient Management**
- Individual patient reports
- Trial history tracking
- Progress monitoring

### **Data Backup**
- Local data backup
- Transfer between devices
- Long-term data storage

### **Sharing & Collaboration**
- Share with healthcare providers
- Send to research teams
- Export for external analysis

## 🚀 **Future Enhancements**

### **Planned Features**
- **Excel Export**: .xlsx format support
- **PDF Reports**: Formatted patient reports
- **Cloud Integration**: Direct cloud upload
- **Data Filtering**: Export specific date ranges
- **Custom Fields**: User-defined export fields

### **Advanced Options**
- **Data Encryption**: Secure file encryption
- **Batch Processing**: Multiple export types
- **Scheduled Exports**: Automatic exports
- **Template System**: Custom export templates

## 🎉 **Benefits**

### **For Clinicians**
- **Easy Data Export**: One-tap export functionality
- **Multiple Formats**: Different views for different needs
- **Patient Management**: Individual patient tracking
- **Research Ready**: Analysis-ready data format

### **For Researchers**
- **Complete Dataset**: All patient and trial data
- **Standardized Format**: Consistent CSV structure
- **Cross-Patient Analysis**: Combined data views
- **Statistical Ready**: Direct import to analysis tools

### **For Data Management**
- **Local Control**: Files stored locally
- **Easy Sharing**: Built-in sharing functionality
- **File Organization**: Timestamped file naming
- **Clean Export**: Proper CSV formatting

The CSV export feature provides a comprehensive solution for data export, sharing, and management, making it easy to work with patient and trial data in external tools and systems.


