# Field Test Execution Guide

## Current Status

**Device Connection:** ❌ No device/emulator detected  
**ADB Status:** ✅ Available (version 1.0.41)

## Next Steps

### 1. Connect Device or Start Emulator

**Option A: Physical Device**
- Connect Android device via USB
- Enable USB Debugging in Developer Options
- Accept the USB debugging authorization prompt on device

**Option B: Emulator**
- Start Android Emulator from Android Studio
- Or use command: `emulator -avd <avd_name>`

### 2. Verify Connection

Once device is connected, run:
```powershell
adb devices
```

You should see your device listed.

### 3. Set Up Test Environment

Run the helper script:
```powershell
cd flutter_app
.\run_field_test.ps1 -ClearData -StartLogging
```

This will:
- Clear app data for a clean start
- Start logcat logging to `field_test_log.txt`

**Keep the logging terminal window open during testing!**

### 4. Execute Manual Test Steps

Follow the detailed steps in `FIELD_TEST_SCRIPT.md` or use the quick checklist in `FIELD_TEST_CHECKLIST.md`.

### 5. Stop Logging and Generate Report

When test is complete:
- Press `Ctrl+C` in the logging terminal to stop logcat
- Review `field_test_log.txt` for errors
- Fill out the test report below

---

## Test Report

### Test Execution Details

**Date:** _______________  
**Tester:** _______________  
**Device/Emulator:** _______________  
**App Version:** _______________  
**Test Duration:** _______________

### Phase 1: Debug Environment Setup

- [ ] Device connected successfully
- [ ] ADB logcat logging started
- [ ] App data cleared (clean start)
- [ ] App launched successfully

**Notes:**
```
[Any issues during setup]
```

### Phase 2: Settings Configuration

- [ ] Navigated to Settings → Advanced Settings
- [ ] Jack Diameter set to **60.0 mm** ✅
- [ ] Returned to main Settings
- [ ] Pro Accuracy Mode enabled (ON) ✅
- [ ] Measurement Unit set to **Imperial** (ft/in) ✅
- [ ] Show Camera Guides enabled (ON) ✅
- [ ] Settings persisted after navigation ✅

**Issues Found:**
```
[Document any issues with settings]
```

### Phase 3: Measurement Execution

- [ ] Navigated to Camera View
- [ ] Camera preview loaded successfully
- [ ] Camera guides visible (if enabled)
- [ ] Manual jack selection worked (red marker appeared)
- [ ] Measure button triggered processing
- [ ] **No crashes during processing** ✅
- [ ] Processing completed in reasonable time (2-10 seconds)
- [ ] Navigated to ResultsView automatically

**Processing Time:** _______________ seconds  
**Issues Found:**
```
[Document any crashes, freezes, or errors]
```

### Phase 4: Results Verification

#### Verification 1: Accuracy and Display Format

- [ ] Distance overlays visible on image ✅
- [ ] **Units displayed in feet/inches format** (e.g., "1 ft 2.5 in") ✅
- [ ] Pro Mode calculations appear accurate
- [ ] Overlays positioned correctly over bowls
- [ ] Ranking correct (closest bowl = rank 1)

**Sample Distance Display:** _______________  
**Issues Found:**
```
[Document any unit conversion errors or display issues]
```

#### Verification 2: Save to History

- [ ] Save button visible and enabled
- [ ] Save dialog appeared
- [ ] Entered name: **"FIELD TEST 1"**
- [ ] Save confirmed successfully
- [ ] SnackBar appeared: "Measurement saved to history"

**Issues Found:**
```
[Document any save failures]
```

#### Verification 3: History Stability

- [ ] Navigated to History View
- [ ] **"FIELD TEST 1" found in list** ✅
- [ ] Name displayed correctly: **"FIELD TEST 1"** ✅
- [ ] Swiped left to delete item
- [ ] SnackBar appeared with "UNDO" button
- [ ] Tapped UNDO button
- [ ] **Item restored successfully** ✅
- [ ] Swiped left again to delete
- [ ] Did NOT tap UNDO (permanent delete)
- [ ] **Item permanently removed** ✅
- [ ] Navigated away and back - deletion persisted ✅

**Issues Found:**
```
[Document any history, delete, or undo issues]
```

#### Verification 4: Measure Again Flow

- [ ] Tapped "Measure Again" button
- [ ] Navigated back to CameraView
- [ ] Camera reinitialized successfully
- [ ] Manual jack position cleared (if applicable)

**Issues Found:**
```
[Document any navigation issues]
```

### Phase 5: Log Analysis

**Log File:** `field_test_log.txt`

**Errors Found:**
```
[Paste any ERROR or FATAL log entries]
```

**Exceptions Found:**
```
[Paste any Exception stack traces]
```

**Type Cast Issues:**
```
[Search for int/double conversion errors]
```

**Performance Issues:**
```
[Note any slow operations or memory warnings]
```

### Critical Test Results

#### Test 2: Pro Mode Overlays
- [ ] ✅ **PASS:** Pro Mode overlays appeared correctly with imperial units
- [ ] ❌ **FAIL:** Overlays did not appear, showed wrong units, or crashed

**Details:**
```
[Record observations]
```

#### Test 5: Save/Delete Stability
- [ ] ✅ **PASS:** Save, delete, undo, and permanent delete all worked correctly
- [ ] ❌ **FAIL:** Any step failed or caused crashes

**Details:**
```
[Record observations]
```

### Issues Summary

#### Critical Issues (Blocking)
```
[Issues that prevent core functionality]
```

#### High Priority Issues
```
[Issues that significantly impact user experience]
```

#### Medium Priority Issues
```
[Issues that are noticeable but don't block functionality]
```

#### Low Priority Issues
```
[Minor issues, UI polish, etc.]
```

### Overall Test Result

- [ ] ✅ **PASS:** All critical tests passed, no blocking issues
- [ ] ⚠️ **PASS WITH ISSUES:** Core functionality works, but issues found
- [ ] ❌ **FAIL:** Critical functionality broken, blocking issues present

### Recommendations

```
[Recommendations for fixes, improvements, or next steps]
```

---

## Next Actions

1. **If PASS:** System is ready for production release
2. **If PASS WITH ISSUES:** Address high/medium priority issues before release
3. **If FAIL:** Fix critical issues and re-run test

---

## Log File Location

Logs are saved to: `flutter_app/field_test_log.txt`

Review this file for detailed error information, stack traces, and performance metrics.

