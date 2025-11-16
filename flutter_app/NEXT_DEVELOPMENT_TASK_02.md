# Next Development Task: View Full Measurement Details from History

## Overview

Implement navigation from HistoryView to ResultsView, allowing users to tap on a measurement in the history list to view its full details. This completes the measurement history feature by enabling users to actually view the details of past measurements.

## Current State

- ✅ `HistoryView` displays a list of past measurements
- ✅ `ResultsView` can display a `MeasurementResult` with full details
- ✅ `_HistoryListItem` shows a chevron icon suggesting it's tappable
- ❌ No navigation from HistoryView to ResultsView
- ❌ ListTile items are not tappable
- ❌ Users cannot view full details of past measurements

## Implementation Steps

### Step 1: Add Navigation to HistoryView

**File**: `lib/views/history_view.dart`

**Changes**:
- Add `onTap` handler to `_HistoryListItem`'s `ListTile`
- Navigate to `ResultsView` with the selected measurement
- Use `Navigator.push` with `MaterialPageRoute`

**Key Implementation**:
```dart
ListTile(
  title: Text(formattedDate),
  subtitle: Text('${measurement.bowls.length} bowls measured'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultsView(measurementResult: measurement),
      ),
    );
  },
)
```

### Step 2: Import ResultsView

**File**: `lib/views/history_view.dart`

**Changes**:
- Add import statement for `ResultsView`

### Step 3: Create Tests

**File**: `test/views/history_view_test.dart`

**Test Cases**:
- Test that tapping a ListTile navigates to ResultsView
- Test that ResultsView receives the correct measurement
- Verify navigation flow works correctly

## Technical Considerations

### Navigation Pattern
- Follow existing navigation pattern from `CameraView` to `ResultsView`
- Use `MaterialPageRoute` for consistency
- Ensure proper context handling

### User Experience
- Maintain back navigation (automatic with Navigator.push)
- Preserve history list state when returning
- Ensure ResultsView displays correctly with historical data

### Data Integrity
- Verify that historical measurements have all required data
- Handle edge cases (missing image paths, etc.)
- Ensure ResultsView can handle both new and historical measurements

## Success Criteria

- ✅ Users can tap on a measurement in HistoryView
- ✅ Navigation to ResultsView occurs correctly
- ✅ ResultsView displays the full measurement details
- ✅ Back navigation returns to HistoryView
- ✅ UI is accessible (large tap targets)
- ✅ Tests pass with >80% coverage

## Estimated Effort

- **Navigation Implementation**: 30 minutes
- **Testing**: 30 minutes
- **Total**: 1 hour

## Dependencies

- ✅ `ResultsView` exists and accepts `MeasurementResult`
- ✅ `HistoryView` exists with list of measurements
- ✅ Navigation structure in place
- ✅ `MeasurementResult` model is complete

## Future Enhancements

- Add measurement editing capabilities
- Add share functionality from ResultsView
- Add delete option from ResultsView
- Add measurement comparison view
- Add export functionality (PDF, image)

