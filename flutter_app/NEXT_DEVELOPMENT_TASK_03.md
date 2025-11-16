# Next Development Task: Settings View

## Overview

Implement a Settings View for the Flutter app that allows users to configure app preferences, measurement settings, and other options. Currently, the settings icon in CameraView navigates to TeamCalibrationView, but there's no dedicated settings page. This feature will provide a centralized location for app configuration.

## Current State

- ✅ `CameraView` has a settings icon button (currently navigates to `TeamCalibrationView`)
- ✅ `TeamCalibrationView` exists for team color calibration
- ✅ `HelpView` exists for help/instructions
- ✅ `HistoryView` exists for measurement history
- ❌ No dedicated `SettingsView` exists
- ❌ No settings service or ViewModel for managing app preferences
- ❌ No persistent storage for user settings

## Implementation Steps

### Step 1: Create Settings Service

**File**: `lib/services/settings_service.dart`

**Responsibilities**:
- Save and retrieve user settings from persistent storage (SharedPreferences)
- Provide default settings values
- Handle settings updates and persistence

**Key Methods**:
```dart
class SettingsService {
  static Future<AppSettings> getSettings();
  static Future<bool> saveSettings(AppSettings settings);
  static Future<AppSettings> resetToDefaults();
}
```

**Settings Model**:
```dart
class AppSettings {
  // Measurement settings
  final bool autoSaveMeasurements;
  final String defaultUnit; // 'cm', 'mm', 'inches'
  final bool highAccuracyMode;
  
  // Display settings
  final bool showGrid;
  final bool showInstructions;
  
  // Other settings
  final bool enableHapticFeedback;
  final String theme; // 'light', 'dark', 'system'
}
```

### Step 2: Create Settings ViewModel

**File**: `lib/viewmodels/settings_viewmodel.dart`

**Responsibilities**:
- Manage settings state
- Load settings from service
- Update settings and persist changes
- Provide reactive updates to UI

**Key Methods**:
```dart
class SettingsViewModel extends ChangeNotifier {
  Future<void> loadSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> resetToDefaults();
  AppSettings get settings;
  bool get isLoading;
  String? get errorMessage;
}
```

### Step 3: Create Settings View

**File**: `lib/views/settings_view.dart`

**UI Components**:
- Settings sections (Measurement, Display, General)
- Toggle switches for boolean settings
- Dropdown/segmented controls for unit selection
- Save/Reset buttons
- Loading and error states
- Accessible design (large buttons, high contrast)

**Sections**:
1. **Measurement Settings**
   - Auto-save measurements toggle
   - Default unit selector (cm/mm/inches)
   - High accuracy mode toggle

2. **Display Settings**
   - Show grid toggle
   - Show instructions toggle

3. **General Settings**
   - Haptic feedback toggle
   - Theme selector (if applicable)

### Step 4: Update CameraView Navigation

**File**: `lib/views/camera_view.dart`

**Changes**:
- Update settings icon button to navigate to `SettingsView` instead of `TeamCalibrationView`
- Keep TeamCalibrationView accessible from SettingsView if needed

### Step 5: Create Tests

**Files**:
- `test/services/settings_service_test.dart`
- `test/viewmodels/settings_viewmodel_test.dart`
- `test/views/settings_view_test.dart`

**Test Cases**:
- Load settings from storage
- Save settings to storage
- Reset to defaults
- Settings persistence
- Widget rendering
- Navigation from CameraView
- Settings updates reflect in UI

## Technical Considerations

### Storage Strategy
- Use SharedPreferences for local storage
- Store settings as JSON for easy serialization
- Key: `'app_settings'`

### Default Values
- Provide sensible defaults for all settings
- Ensure app works correctly with default settings

### State Management
- Use ChangeNotifier pattern (consistent with other ViewModels)
- Provide loading and error states
- Notify listeners on settings changes

### User Experience
- Auto-save settings on change (optional, or explicit Save button)
- Show confirmation on Reset
- Provide visual feedback on save
- Maintain accessibility standards

## Success Criteria

- ✅ Users can access SettingsView from CameraView
- ✅ Users can view current settings
- ✅ Users can modify settings
- ✅ Settings persist across app restarts
- ✅ Settings can be reset to defaults
- ✅ UI is accessible (large buttons, high contrast)
- ✅ Tests pass with >80% coverage

## Estimated Effort

- **Settings Service**: 1 hour
- **Settings ViewModel**: 1 hour
- **Settings View UI**: 2 hours
- **Navigation Updates**: 30 minutes
- **Testing**: 1.5 hours
- **Total**: 6 hours

## Dependencies

- ✅ `shared_preferences` already in `pubspec.yaml`
- ✅ Navigation structure in place
- ✅ ViewModel pattern established
- ✅ UI component patterns established

## Future Enhancements

- Add more settings options (notifications, privacy, etc.)
- Add settings import/export
- Add settings sync (when cloud sync is available)
- Add settings search/filter
- Add settings categories/tabs
- Integrate with system settings (theme, accessibility)

