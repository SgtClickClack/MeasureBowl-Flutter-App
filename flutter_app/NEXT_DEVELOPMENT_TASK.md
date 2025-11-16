# Next Development Task: Measurement History Feature

## Overview

Implement a Measurement History feature that allows users to save and view past measurements. This addresses a key gap where users currently lose measurements after viewing results.

## Current State

- ✅ `CacheService` exists for processing cache (temporary, auto-expires after 7 days)
- ❌ No persistent user-accessible measurement history
- ❌ No way to view past measurements
- ❌ Measurements are lost after navigating away from results

## Implementation Steps

### Step 1: Create Measurement History Service

**File**: `lib/services/measurement_history_service.dart`

**Responsibilities**:
- Save measurements to persistent storage (SharedPreferences)
- Retrieve saved measurements
- Delete individual or all measurements
- Handle storage limits (e.g., max 100 measurements)

**Key Methods**:
```dart
class MeasurementHistoryService {
  static Future<void> saveMeasurement(MeasurementResult result);
  static Future<List<MeasurementResult>> getAllMeasurements();
  static Future<MeasurementResult?> getMeasurement(String id);
  static Future<void> deleteMeasurement(String id);
  static Future<void> clearAllMeasurements();
  static Future<int> getMeasurementCount();
}
```

**Storage Strategy**:
- Use SharedPreferences to store JSON-encoded list of measurements
- Key: `'measurement_history'`
- Limit to 100 most recent measurements (FIFO)
- Store as JSON array for easy serialization

### Step 2: Create History View

**File**: `lib/views/history_view.dart`

**UI Components**:
- List view of past measurements
- Each item shows:
  - Thumbnail of captured image (if available)
  - Timestamp (formatted: "2 hours ago", "Jan 15, 2025")
  - Number of bowls detected
  - Distance of closest bowl
- Tap item to view full results (navigate to ResultsView)
- Swipe to delete (optional)
- Empty state message when no history

**Navigation**:
- Add history button to camera view header (icon: `Icons.history`)
- Navigate to HistoryView
- From HistoryView, navigate to ResultsView with selected measurement

### Step 3: Update Results View

**Changes**:
- Add "Save to History" button (if not already saved)
- Show "Saved" indicator if already in history
- Auto-save option (configurable via settings, default: true)

### Step 4: Update Camera View

**Changes**:
- Add history button to header (top-right, next to settings)
- Navigate to HistoryView on tap

### Step 5: Create Tests

**Files**:
- `test/services/measurement_history_service_test.dart`
- `test/views/history_view_test.dart`

**Test Cases**:
- Save measurement
- Retrieve all measurements
- Delete measurement
- Storage limit enforcement
- JSON serialization/deserialization
- Widget rendering
- Navigation flow

## Technical Considerations

### Storage Limits
- Maximum 100 measurements (oldest deleted first)
- Each measurement ~5-10KB (JSON + metadata)
- Total storage: ~500KB-1MB (acceptable)

### Performance
- Load measurements lazily (only when HistoryView opens)
- Cache measurement list in memory after first load
- Use ListView.builder for efficient scrolling

### Data Migration
- No migration needed (new feature)
- Future: Consider migrating to SQLite if storage needs grow

## Success Criteria

- ✅ Users can save measurements to history
- ✅ Users can view list of past measurements
- ✅ Users can view full details of past measurements
- ✅ Users can delete measurements
- ✅ Storage is limited and managed
- ✅ UI is accessible (large buttons, high contrast)
- ✅ Tests pass with >80% coverage

## Estimated Effort

- **Service Implementation**: 2 hours
- **History View UI**: 2 hours
- **Integration & Navigation**: 1 hour
- **Testing**: 1 hour
- **Total**: 6 hours

## Dependencies

- ✅ `shared_preferences` already in `pubspec.yaml`
- ✅ `MeasurementResult` model exists
- ✅ Navigation structure in place
- ✅ Image file handling already implemented

## Future Enhancements

- Search/filter measurements
- Export measurements (PDF, CSV)
- Share measurements
- Cloud sync (when Firebase integration complete)
- Statistics/analytics view

