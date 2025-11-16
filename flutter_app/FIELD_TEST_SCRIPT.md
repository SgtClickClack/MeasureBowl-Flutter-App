# Comprehensive E2E Regression and Accuracy Check (Field Test Script)

## Overview

This script is designed to verify the entire system's stability and accuracy by targeting the most complex, interconnected features simultaneously. The goal is to generate concrete results to confirm:

1. The final 'int/double' type cast fix holds up in real-world scenarios.
2. The advanced perspective calculations (Pro Mode, Diameters) are accurate.
3. The full Save/History/Delete/Name UX loop is stable.

---

## Prerequisites

- Android device/emulator connected via USB or running locally
- ADB (Android Debug Bridge) installed and accessible in PATH
- Flutter app built and installed on the device
- Terminal/Command Prompt access (PowerShell recommended for Windows)

## Quick Start

For Windows users, you can use the helper script to automate setup:
```powershell
# Full setup: Clear data and start logging
.\run_field_test.ps1 -ClearData -StartLogging
```

This will handle device checks, clear app data, and start logcat logging automatically.

---

## Phase 1: Prepare Debug Environment

### Objective
Set up logging and ensure a clean testing state.

### Steps

1. **Connect Device/Emulator**
   ```bash
   # Verify device is connected
   adb devices
   ```
   - Expected: Device should appear in the list
   - If no device: Check USB debugging is enabled, or start an emulator

2. **Start Live Log Stream**
   ```bash
   # Start logcat and save to file
   adb logcat > field_test_log.txt
   ```
   - Keep this terminal window open and running
   - Logs will be captured to `field_test_log.txt`
   - **Note:** Press `Ctrl+C` later to stop logging

3. **Clear App Data (Optional but Recommended)**
   ```bash
   # Clear app data for a clean start
   adb shell pm clear com.standnmeasure.app
   ```
   - Or use the helper script: `.\run_field_test.ps1 -ClearData`
   - This ensures no residual data affects the test

4. **Launch the App**
   - Open the app on the device/emulator
   - Wait for the app to fully initialize

---

## Phase 2: Configure Maximum Difficulty (Max Data Points)

### Objective
Configure settings to maximum complexity to stress-test the system.

### Steps

1. **Navigate to Settings**
   - From the main screen, tap the **Settings** icon/button
   - Wait for Settings view to load

2. **Open Advanced Settings**
   - In the Settings view, locate and tap **"Advanced Settings"**
   - This should navigate to the Advanced Settings view

3. **Configure Jack Diameter**
   - Locate the **"Jack Diameter"** slider
   - Set the value to **60.0 mm** (non-default value)
   - Verify the label updates to show "60.0 mm"
   - **Note:** Bowl Diameter is auto-detected by the app, not configurable

4. **Return to Main Settings**
   - Tap the back button to return to the main Settings page

5. **Enable Pro Accuracy Mode**
   - Locate the **"Pro Accuracy Mode"** toggle
   - Set it to **ON** (enabled)
   - Verify the toggle shows as enabled

6. **Set Measurement Unit to Imperial**
   - Locate the **"Measurement Unit"** dropdown
   - Tap the dropdown
   - Select **"Imperial"** (ft/in)
   - Verify the dropdown now shows "Imperial"

7. **Enable Camera Guides**
   - Locate the **"Show Camera Guides"** toggle
   - Set it to **ON** (enabled)
   - Verify the toggle shows as enabled

8. **Verify Settings Are Saved**
   - Navigate back to the main screen
   - Return to Settings and verify all settings are still as configured
   - If settings reset, note this as a potential issue

---

## Phase 3: Execute the Full Measurement Loop

### Objective
Perform a complete measurement with maximum complexity settings.

### Steps

1. **Navigate to Camera View**
   - From the main screen, tap the **"Measure"** or **"Camera"** button
   - Wait for the camera preview to initialize
   - Verify camera feed is visible

2. **Verify Camera Guides (If Enabled)**
   - Check that camera guides are visible on the preview (if enabled in settings)
   - Guides should help with positioning

3. **Position Camera**
   - Position the camera over a complex, spread-out head (if possible)
   - Ensure good lighting and clear view of bowls and jack
   - If using a test image or mock setup, position accordingly

4. **Manual Jack Selection**
   - Tap on the camera preview where the jack is located
   - **Expected:** A red marker (icon) should appear at the tapped location
   - Verify the marker is visible and positioned correctly

5. **Initiate Measurement**
   - Tap the **"Measure"** button
   - **Expected Behaviors:**
     - Button should show processing state (e.g., "Processing..." or spinner)
     - App should NOT crash
     - Processing time should be reasonable (typically 2-10 seconds)
   - Wait for processing to complete

6. **Verify Navigation to Results**
   - After processing, the app should automatically navigate to ResultsView
   - If an error occurs, check the log file for details

---

## Phase 4: Verify Results and UX Loop

### Objective
Verify measurement accuracy, display formatting, and complete the save/history/delete workflow.

### Verification 1: Accuracy and Display Format

1. **Check Distance Overlays**
   - On the ResultsView, verify that distance overlays are visible on the image
   - **Critical Check:** Verify distances are displayed in **feet and inches** format
   - Expected format: `"1 ft 2.5 in"` or similar (not centimeters)
   - Verify multiple bowls show ranked distances (e.g., "1. 0 ft 5.2 in", "2. 0 ft 8.1 in")

2. **Verify Pro Mode Calculations**
   - If Pro Mode is enabled, verify that distance calculations appear accurate
   - Check that overlays are positioned correctly over bowls
   - Verify ranking is correct (closest bowl should be rank 1)

### Verification 2: Save to History

1. **Locate Save Button**
   - On the ResultsView, locate the **"Save to History"** button (save icon in the top bar)
   - Verify the button is visible and enabled

2. **Save Measurement**
   - Tap the **"Save to History"** button
   - **Expected:** A dialog should appear prompting for a measurement name

3. **Enter Measurement Name**
   - In the dialog, enter a unique name: **"FIELD TEST 1"**
   - Tap **"Save"** or **"Confirm"** button
   - **Expected:**
     - Dialog should close
     - A SnackBar should appear with message: "Measurement saved to history"
     - Save button should change state (may become disabled or show saved state)

### Verification 3: History Stability

1. **Navigate to History View**
   - From ResultsView, locate and tap the **"History"** button/icon
   - Or navigate back and access History from the main menu
   - Wait for HistoryView to load

2. **Verify Saved Measurement**
   - In the HistoryView, locate the measurement named **"FIELD TEST 1"**
   - **Expected:**
     - The measurement should appear in the list
     - The name "FIELD TEST 1" should be displayed correctly
     - Timestamp and other details should be visible

3. **Test Undo Functionality**
   - Locate the "FIELD TEST 1" item in the history list
   - **Swipe left** on the item (or use delete gesture)
   - **Expected:**
     - Item should be dismissed/deleted
     - A SnackBar should appear with message: "Measurement deleted"
     - SnackBar should have an **"UNDO"** button

4. **Restore Measurement**
   - Tap the **"UNDO"** button in the SnackBar
   - **Expected:**
     - SnackBar should disappear
     - The "FIELD TEST 1" measurement should reappear in the list
     - Item should be restored with all original data

5. **Permanent Delete**
   - Swipe left on "FIELD TEST 1" again to delete
   - **DO NOT** tap UNDO this time
   - Wait for SnackBar to disappear (or manually dismiss it)
   - **Expected:**
     - Item should be permanently removed from the list
     - History list should update to reflect the deletion

6. **Verify Deletion Persists**
   - Navigate away from HistoryView and return
   - Verify "FIELD TEST 1" is no longer in the list
   - This confirms the deletion was persisted

### Verification 4: Measure Again Flow

1. **Return to Results View**
   - If still on HistoryView, navigate back
   - Or perform a new measurement to get to ResultsView

2. **Tap Measure Again**
   - On ResultsView, locate and tap the **"Measure Again"** button
   - **Expected:**
     - Should navigate back to CameraView
     - Camera should reinitialize
     - Manual jack position should be cleared (if applicable)

---

## Phase 5: Final Data Collection

### Objective
Collect logs and compile test results.

### Steps

1. **Stop Log Collection**
   - In the terminal running `adb logcat`, press `Ctrl+C` to stop logging
   - Verify `field_test_log.txt` file was created and contains log data

2. **Review Log File**
   - Open `field_test_log.txt` in a text editor
   - Search for keywords:
     - `ERROR` or `FATAL` - Check for any critical errors
     - `Exception` - Look for exceptions that might indicate issues
     - `crash` - Check for crash reports
   - Note any suspicious entries

3. **Compile Test Results**

   **Test 2: Pro Mode Overlays**
   - ✅ **PASS:** Pro Mode overlays appeared correctly with imperial units
   - ❌ **FAIL:** Overlays did not appear, showed wrong units, or crashed
   - **Notes:** [Record any observations]

   **Test 5: Save/Delete Stability**
   - ✅ **PASS:** Save, delete, undo, and permanent delete all worked correctly
   - ❌ **FAIL:** Any step failed or caused crashes
   - **Notes:** [Record any observations]

4. **Document Issues**
   - List any crashes, freezes, or unexpected behaviors
   - Note any UI inconsistencies
   - Record any performance issues (slow processing, lag, etc.)

---

## Expected Results Summary

### Successful Test Indicators

✅ **No Crashes:** App should remain stable throughout all operations  
✅ **Correct Units:** Distances should display in feet and inches when Imperial is selected  
✅ **Pro Mode Works:** Advanced calculations should function correctly  
✅ **Save Works:** Measurements should save with custom names  
✅ **History Works:** Saved measurements should appear in history  
✅ **Undo Works:** Deleted items should be restorable via UNDO  
✅ **Delete Works:** Permanent deletion should remove items from history  
✅ **Navigation Works:** All navigation between views should be smooth  

### Common Issues to Watch For

⚠️ **Type Cast Errors:** Look for errors related to int/double conversions in logs  
⚠️ **Unit Conversion Errors:** Verify imperial conversion is accurate  
⚠️ **Persistent Data Issues:** Settings or history not saving/loading correctly  
⚠️ **UI State Issues:** Buttons not updating, overlays not appearing  
⚠️ **Performance Issues:** Excessive processing time or memory usage  

---

## Troubleshooting

### If App Crashes
1. Check `field_test_log.txt` for stack traces
2. Note the exact step where crash occurred
3. Try repeating the step to see if it's reproducible

### If Settings Don't Save
1. Verify app has storage permissions
2. Check logs for file I/O errors
3. Try restarting the app and checking if settings persist

### If Measurement Fails
1. Verify camera permissions are granted
2. Check logs for image processing errors
3. Ensure good lighting and clear view of bowls/jack

### If History Doesn't Update
1. Check logs for database/storage errors
2. Verify the measurement was actually saved (check save confirmation)
3. Try refreshing the history view

---

## Test Report Template

```
FIELD TEST REPORT
Date: [DATE]
Device: [DEVICE MODEL/EMULATOR]
App Version: [VERSION]

Phase 1: Debug Environment
- [ ] Device connected successfully
- [ ] Logging started
- [ ] App data cleared (if applicable)

Phase 2: Settings Configuration
- [ ] Jack Diameter set to 60.0 mm
- [ ] Pro Accuracy Mode enabled
- [ ] Measurement Unit set to Imperial
- [ ] Camera Guides enabled
- [ ] Settings persisted after navigation

Phase 3: Measurement Execution
- [ ] Camera view loaded
- [ ] Manual jack selection worked
- [ ] Measure button triggered processing
- [ ] No crashes during processing
- [ ] Processing completed in reasonable time
- [ ] Navigated to ResultsView

Phase 4: Results Verification
- [ ] Distance overlays visible
- [ ] Units displayed in feet/inches format
- [ ] Pro Mode calculations accurate
- [ ] Save button functional
- [ ] Measurement saved with name "FIELD TEST 1"
- [ ] History view shows saved measurement
- [ ] Undo functionality works
- [ ] Permanent delete works
- [ ] Measure Again navigates correctly

Phase 5: Data Collection
- [ ] Logs collected successfully
- [ ] No critical errors in logs
- [ ] Test results documented

ISSUES FOUND:
[List any issues here]

OVERALL RESULT: PASS / FAIL
```

---

## Notes

- **Bowl Diameter:** The app automatically detects bowl diameter from images. There is no manual setting for bowl diameter in the current implementation.
- **Jack Diameter:** Only Jack Diameter is configurable in Advanced Settings (range: 60.0-70.0 mm).
- **Log File Location:** The log file `field_test_log.txt` will be created in the directory where you ran the `adb logcat` command.
- **Test Duration:** This comprehensive test should take approximately 15-30 minutes to complete thoroughly.

---

## Next Steps After Testing

1. Review all collected logs for errors
2. Document any issues found
3. If issues are found, create bug reports with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Log excerpts
   - Device/environment information
4. If all tests pass, this confirms the system is stable and ready for release

