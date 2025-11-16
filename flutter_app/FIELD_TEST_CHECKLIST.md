# Field Test Quick Checklist

## Pre-Test Setup
- [ ] Device/emulator connected
- [ ] ADB accessible in PATH
- [ ] App installed on device
- [ ] Run: `.\run_field_test.ps1 -ClearData -StartLogging` (or manually start logcat)

## Phase 1: Settings Configuration
- [ ] Navigate to Settings → Advanced Settings
- [ ] Set Jack Diameter to **60.0 mm**
- [ ] Return to main Settings
- [ ] Enable **Pro Accuracy Mode** (ON)
- [ ] Set **Measurement Unit** to **Imperial** (ft/in)
- [ ] Enable **Show Camera Guides** (ON)
- [ ] Verify settings persist (navigate away and back)

## Phase 2: Measurement
- [ ] Navigate to Camera View
- [ ] Verify camera preview loads
- [ ] Tap preview to place red marker on jack (Manual Jack Selection)
- [ ] Tap **Measure** button
- [ ] Verify no crash during processing
- [ ] Verify processing completes (2-10 seconds typical)
- [ ] Verify navigation to ResultsView

## Phase 3: Results Verification
- [ ] **Distance overlays visible** on image
- [ ] **Units in feet/inches format** (e.g., "1 ft 2.5 in")
- [ ] **Pro Mode calculations accurate** (overlays positioned correctly)
- [ ] Tap **Save to History** button
- [ ] Enter name: **"FIELD TEST 1"**
- [ ] Confirm save
- [ ] Verify SnackBar: "Measurement saved to history"

## Phase 4: History & Delete Flow
- [ ] Navigate to History View
- [ ] Find **"FIELD TEST 1"** in list
- [ ] Verify name displays correctly
- [ ] **Swipe left** on item to delete
- [ ] Verify SnackBar with **"UNDO"** button appears
- [ ] Tap **UNDO** button
- [ ] Verify item restored in list
- [ ] Swipe left again to delete
- [ ] **DO NOT** tap UNDO (let SnackBar dismiss)
- [ ] Verify item permanently removed
- [ ] Navigate away and back - verify deletion persists

## Phase 5: Measure Again
- [ ] From ResultsView, tap **"Measure Again"**
- [ ] Verify navigation back to CameraView
- [ ] Verify camera reinitializes

## Post-Test
- [ ] Stop logcat (Ctrl+C in terminal)
- [ ] Review `field_test_log.txt` for errors
- [ ] Document any issues found
- [ ] Complete test report

## Critical Checks
- ✅ **No crashes** throughout entire test
- ✅ **Imperial units** display correctly (ft/in)
- ✅ **Save/Delete/Undo** all work correctly
- ✅ **Settings persist** after navigation
- ✅ **Pro Mode** calculations are accurate

## Issues Found
```
[Document any issues here]
```

## Test Result: PASS / FAIL
Date: _______________
Tester: _______________

