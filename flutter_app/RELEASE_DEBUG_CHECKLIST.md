# Release Build Debugging Checklist

Use this checklist to systematically identify issues when the app works in Debug but fails in Release mode.

## Step 1: Visual Integrity (The "Terrible" Look)

### Icons/Images
- [ ] **Missing Icons:** Are app icons missing (showing empty squares or 'X' marks)?
  - **Cause:** Assets got stripped by resource shrinking
  - **Location to check:** App launcher icon, in-app icons
  
- [ ] **Missing Images:** Are any images in the app missing or showing placeholders?
  - **Cause:** Asset files not properly referenced or stripped
  - **Location to check:** `assets/icon/` directory, any image assets

### Layout
- [ ] **Squashed Layout:** Is everything compressed into one corner or overlapping?
  - **Cause:** Rendering engine behaving differently in release mode
  - **Note:** Specific screen where this occurs: _______________
  
- [ ] **Wrong Sizing:** Are UI elements (buttons, text) the wrong size?
  - **Cause:** Resource references broken or theme not loading
  - **Note:** Which elements: _______________

### Text
- [ ] **Wrong Font:** Is the font completely different or missing?
  - **Cause:** Font resources stripped or not loaded
  - **Note:** Which text elements: _______________
  
- [ ] **Invisible Text:** Is text present but invisible (white on white, etc.)?
  - **Cause:** Theme colors not loading properly
  - **Note:** Which screens: _______________

## Step 2: Functional Integrity (The "Doesn't Function" Part)

### Launch
- [ ] **Instant Crash:** Does the app crash immediately on opening?
  - **Error message (if visible):** _______________
  - **Logcat error:** _______________
  
- [ ] **Splash Screen:** Does it get stuck on splash screen?
  - **How long does it stay:** _______________
  
- [ ] **App Opens:** Does the app successfully launch?
  - **Time to launch:** _______________

### Permissions
- [ ] **Camera Permission Prompt:** Does it ask for Camera permission when first opened?
  - **If no:** Permission request code may be stripped
  
- [ ] **Permission Granted:** After granting permission, does it work?
  - **If no:** Permission handling code may be stripped

### Camera Feed
- [ ] **Black Screen:** Is the camera preview just black?
  - **Cause:** Camera plugin classes stripped by ProGuard
  
- [ ] **Camera Works:** Can you see the camera view?
  - **If yes:** Camera initialization is working
  
- [ ] **Preview Quality:** Is the preview quality correct?
  - **Note any issues:** _______________

### Interactions
- [ ] **Measure Button:** When you tap "Measure", does anything happen?
  - **Even just a ripple effect?** Yes / No
  - **If nothing:** Button handler may be stripped
  
- [ ] **Button Response:** Does the button respond but fail?
  - **What happens:** _______________
  
- [ ] **Other Buttons:** Do other interactive elements work?
  - **Which ones work:** _______________
  - **Which ones don't:** _______________

### Image Processing
- [ ] **OpenCV Functions:** Does image processing work?
  - **Cause:** OpenCV native libraries or JNI bindings may be stripped
  - **Error (if any):** _______________

## Step 3: Error Logs Collection

### Logcat Output
Run this command while testing:
```bash
adb logcat | grep -i "flutter\|error\|exception\|crash"
```

**Key errors found:**
- [ ] ClassNotFoundException
- [ ] NoSuchMethodError
- [ ] MissingResourceException
- [ ] Native method not found
- [ ] Other: _______________

### Flutter Verbose Output
When running `flutter run --release --verbose`, note:
- [ ] **Build warnings:** Any ProGuard/R8 warnings?
- [ ] **Runtime errors:** Any errors in the verbose output?
- [ ] **Asset loading errors:** Any missing asset warnings?

## Step 4: Specific Symptoms Summary

**What exactly looks "terrible"?**
- [ ] Missing icons/images
- [ ] Broken layout
- [ ] Wrong text/fonts
- [ ] Wrong colors
- [ ] Other: _______________

**What exactly "doesn't function"?**
- [ ] Crashes on launch
- [ ] No camera permission prompt
- [ ] Black camera screen
- [ ] Buttons don't respond
- [ ] Image processing fails
- [ ] Other: _______________

**At what point does it fail?**
- [ ] Immediately on app launch
- [ ] When requesting camera permission
- [ ] When initializing camera
- [ ] When tapping Measure button
- [ ] During image processing
- [ ] Other: _______________

## Step 5: Quick Diagnosis

Based on the checklist above, the likely cause is:

- [ ] **Resource Shrinking:** Missing icons/images → Disable `shrinkResources`
- [ ] **Code Minification:** Crashes or missing functionality → Disable `minifyEnabled` or enhance ProGuard rules
- [ ] **Native Code Stripping:** Camera/OpenCV failures → Add ProGuard rules for native methods
- [ ] **Plugin Classes Stripped:** Specific plugin failures → Add keep rules for that plugin

## Next Steps

1. **If resources are missing:** Disable `shrinkResources` in `build.gradle`
2. **If code is broken:** Disable `minifyEnabled` temporarily, then enhance ProGuard rules
3. **If native code fails:** Add comprehensive native method keep rules
4. **If plugins fail:** Add keep rules for specific plugin packages

---

**Date:** _______________
**Device:** _______________
**Android Version:** _______________
**App Version:** _______________

