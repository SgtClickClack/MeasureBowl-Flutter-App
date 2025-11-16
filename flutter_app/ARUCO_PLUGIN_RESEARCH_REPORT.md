# ArUco Plugin Research Report

**Date:** 2024  
**Purpose:** Identify a Flutter OpenCV plugin with ArUco/calib3d module support for high-accuracy metrology implementation

---

## Executive Summary

After thorough research, **no Flutter OpenCV plugin currently provides reliable, documented ArUco module support** that would enable the high-accuracy homography-based measurement pipeline. The current `opencv_dart: ^1.0.4` plugin explicitly does not include ArUco/calib3d modules, as confirmed by multiple code comments throughout the codebase.

---

## Current Situation

### Current Plugin: `opencv_dart: ^1.0.4`

**Status:** ❌ **Does NOT include ArUco/calib3d modules**

**Evidence from Codebase:**
- `lib/services/calibration_processor.dart:278-291`: Multiple functions explicitly state "ArUco support is not yet available in opencv_dart package"
- `lib/services/metrology_service.dart:227-232`: ArUco detection functions are stubbed with "ArUco marker detection not available - opencv_dart does not include ArUco module"
- All ArUco-related functions return `null` or `false` with debug messages indicating missing module support

**What `opencv_dart` DOES provide:**
- Core OpenCV image processing (Mat, imdecode, cvtColor, etc.)
- Contour detection and analysis
- Basic computer vision operations
- Cross-platform support (Android, iOS, Windows, Linux, macOS)

**What `opencv_dart` DOES NOT provide:**
- ArUco marker detection (`getPredefinedDictionary`, `detectMarkers`)
- ChArUco corner interpolation
- Camera calibration with ChArUco (`calibrateCameraChAruco`)
- Perspective transformation via homography (`getPerspectiveTransform` from calib3d)

---

## Alternative Plugin Research

### 1. `flutter_cv2_camera`

**Status:** ⚠️ **Not Suitable**

**Findings:**
- Primary focus: Real-time camera streaming, not general OpenCV operations
- Platform support: Currently Linux only (Android/iOS support "planned")
- ArUco support: Not explicitly documented; would require custom C++ integration
- Architecture: Camera-focused plugin, not a general OpenCV wrapper

**Verdict:** Not a drop-in replacement. Would require significant architectural changes and custom C++ development to add ArUco support.

---

### 2. `flutter_camera_processing`

**Status:** ⚠️ **Not Suitable**

**Findings:**
- Integrates OpenCV via Dart FFI
- Focus: Camera stream processing, not static image analysis
- ArUco support: Not explicitly documented
- Requires custom C++ integration for ArUco module

**Verdict:** Similar to `flutter_cv2_camera` - camera-focused, not a general OpenCV solution. Would require custom development.

---

### 3. `dartcv4` (Mentioned in pubspec.lock)

**Status:** ❓ **Unknown**

**Findings:**
- Appears as a dependency in `pubspec.lock` (version 1.1.6)
- Not found as a direct dependency in `pubspec.yaml`
- Likely a transitive dependency
- No evidence of ArUco support in research

**Verdict:** Requires further investigation, but appears to be a transitive dependency, not a primary OpenCV plugin.

---

## Research Limitations

**Conflicting Information:**
- Some web search results claim `opencv_dart` version 0.6.7 includes ArUco support
- However, the project uses version 1.0.4, and the codebase explicitly documents missing ArUco support
- No definitive evidence found that any version of `opencv_dart` actually includes ArUco modules

**Unverified Claims:**
- Web search results suggesting ArUco support may be based on:
  - Outdated information
  - Confusion with other OpenCV bindings (Python, C++)
  - Speculative documentation

---

## Recommended Path Forward

### Option 1: Wait for `opencv_dart` to Add ArUco Support (Recommended for Short Term)

**Action Items:**
1. Monitor `opencv_dart` GitHub repository for ArUco module additions
2. Submit feature request/issue to `opencv_dart` maintainers requesting ArUco/calib3d support
3. Continue using mm/pixel method with accurate user warnings (now properly implemented)

**Pros:**
- No migration required
- Maintains current architecture
- Plugin is actively maintained

**Cons:**
- Timeline uncertain
- Blocks high-accuracy metrology implementation

---

### Option 2: Fork and Extend `opencv_dart` (Medium Complexity)

**Action Items:**
1. Fork `opencv_dart` repository
2. Add ArUco/calib3d module bindings using Dart FFI
3. Build and test native libraries for all target platforms
4. Maintain fork until upstream adds support

**Pros:**
- Full control over implementation
- Can add exactly what's needed

**Cons:**
- Significant development effort
- Ongoing maintenance burden
- Platform-specific native library builds required

---

### Option 3: Custom Dart FFI Bindings (High Complexity)

**Action Items:**
1. Create custom Dart FFI bindings directly to OpenCV C++ libraries
2. Implement ArUco/calib3d functions as needed
3. Build native libraries for all platforms
4. Integrate with existing codebase

**Pros:**
- Minimal dependencies
- Only include what's needed

**Cons:**
- Very high development effort
- Complex native build process
- Platform-specific maintenance

---

### Option 4: Hybrid Approach - Platform Channels (High Complexity)

**Action Items:**
1. Use `opencv_dart` for existing functionality
2. Create platform-specific native code (Kotlin/Swift) for ArUco operations
3. Use Flutter platform channels to bridge between Dart and native code
4. Implement ArUco detection in native code, return results to Dart

**Pros:**
- Leverages existing `opencv_dart` for most operations
- Native code can use full OpenCV C++ API

**Cons:**
- Platform-specific code required (Android/iOS)
- Complex integration
- Maintenance across multiple codebases

---

## Conclusion

**Current Blocker:** No Flutter OpenCV plugin provides documented, reliable ArUco/calib3d module support.

**Immediate Action:** The fake accuracy hack has been reverted. The app now correctly shows "Results are an estimate" warnings when high-accuracy metrology is not available.

**Recommended Next Steps:**
1. **Short Term:** Continue with mm/pixel method, properly warning users about accuracy limitations
2. **Medium Term:** Engage with `opencv_dart` maintainers to request ArUco/calib3d support
3. **Long Term:** Evaluate Option 2 (fork and extend) if upstream support is not forthcoming

**Critical Decision Required:** The project must choose between:
- **Simple & Automatic (Current):** mm/pixel method - easy to use but inaccurate
- **Perfect & Consistent (Goal):** Homography method - accurate but requires ArUco support that doesn't exist

Until ArUco support is available, the project cannot achieve "perfect and consistent" measurements. The current implementation correctly reflects this limitation to users.

---

## Files Referenced

- `flutter_app/lib/services/calibration_processor.dart` - ArUco stubs
- `flutter_app/lib/services/metrology_service.dart` - ArUco detection stubs
- `flutter_app/lib/services/image_processing/image_processing_isolate.dart` - Fixed accuracy flag
- `flutter_app/lib/views/results_view.dart` - Accuracy warning display
- `flutter_app/pubspec.yaml` - Current dependencies

---

## Research Sources

- pub.dev package listings
- GitHub repository searches
- Web search for Flutter OpenCV plugins
- Codebase analysis of current implementation
- Plugin documentation reviews

