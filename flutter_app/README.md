# Lawn Bowls Measure - Flutter Mobile App

A Flutter mobile application for measuring distances between lawn bowls and the jack using computer vision.

## Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                 # App entry point and theme configuration
│   ├── models/
│   │   └── measurement_result.dart   # Data models for measurements and bowls
│   └── views/
│       ├── camera_view.dart      # Camera feed with measure button
│       └── results_view.dart     # Measurement results display
├── pubspec.yaml                  # Flutter dependencies
└── README.md                     # This file
```

## Features Implemented

### CameraView
- Black background placeholder for camera feed
- Large, accessible circular "Measure" button
- High contrast design optimized for elderly users
- Loading animation during measurement processing
- Automatic navigation to results after measurement

### ResultsView
- Displays measurement results with ranked bowl distances
- Color-coded bowl indicators
- Semi-transparent overlay panel with large, readable fonts
- "Measure Again" button to return to camera view
- Proper timestamp formatting

### Accessibility Features
- Large touch targets (minimum 60x120 pixels for buttons)
- High contrast color scheme (white text on dark backgrounds)
- Large fonts (16-28px) for better readability
- Clear visual hierarchy and iconography

## Getting Started

1. **Install Flutter SDK** (if not already installed)
   - Follow the official Flutter installation guide: https://docs.flutter.dev/get-started/install

2. **Create a new Flutter project** and replace the generated files with these:
   ```bash
   flutter create lawn_bowls_measure
   cd lawn_bowls_measure
   # Replace the generated lib/ folder and pubspec.yaml with the files from this flutter_app/ directory
   ```

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Next Steps

This foundational code provides the static UI shell. To complete the mobile app, you'll need to:

1. **Camera Integration**: Replace the black placeholder with actual camera feed using the `camera` plugin
2. **Image Processing**: Integrate OpenCV for Flutter or similar computer vision library
3. **Distance Calculations**: Port the measurement algorithms from your web MVP
4. **Data Persistence**: Add local storage for measurement history
5. **Advanced Features**: Perspective correction, ellipse detection, calibration system

## Design Philosophy

The UI is designed specifically for elderly users with:
- **Large Visual Elements**: Buttons, text, and icons are sized generously
- **High Contrast**: White text on dark backgrounds for better visibility  
- **Simple Navigation**: Minimal steps between camera and results
- **Clear Feedback**: Loading states and visual confirmations
- **Portrait Orientation**: Optimized for one-handed phone use

## HSV Color Calibration Tools

The app includes two tools for tuning HSV color ranges for object detection:

### Python Calibration Tool (Development)

A standalone Python script for rapid HSV range tuning on test images:

**Location:** `tools/hsv_calibrator.py`

**Usage:**
```bash
# Use default test image
python tools/hsv_calibrator.py

# Use custom image
python tools/hsv_calibrator.py path/to/your/image.jpg
```

**Features:**
- 6 interactive trackbars for H, S, V min/max values
- Real-time mask visualization
- Real-time masked result preview
- Save HSV ranges to file
- Load preset ranges for different colors (Red, Blue, Black, White, Yellow)
- Keyboard shortcuts:
  - `s`: Save current ranges
  - `r`: Reset to default red ranges
  - `1-6`: Load color presets
  - `q`: Quit

**Requirements:**
- Python 3.x
- OpenCV (`pip install opencv-python`)
- NumPy (`pip install numpy`)

### Flutter HSV Calibration Tool (In-Field)

An integrated calibration tool accessible from the Settings menu:

**Access:** Settings → HSV Color Calibration → Open HSV Calibration Tool

**Features:**
- Live camera preview with real-time mask overlay
- 6 sliders for HSV bounds (H: 0-179, S: 0-255, V: 0-255)
- Load preset ranges for different colors
- Export HSV ranges in DetectionConfig format
- Optimized for in-field calibration using actual device camera

**Usage:**
1. Navigate to Settings from the main camera view
2. Scroll to "HSV Color Calibration" section
3. Tap "Open HSV Calibration Tool"
4. Adjust sliders to fine-tune color detection
5. Use the preset button to load default ranges for specific colors
6. Use the code button to view/copy the HSV ranges in Dart format

**Best Practices:**
- Calibrate in the same lighting conditions where you'll use the app
- Test with multiple test images (bright sun, cloudy, shadow)
- Start with the default presets and adjust incrementally
- Higher S_Min values ensure color purity (reject desaturated colors)
- Appropriate V_Min values handle shadows (lower = more permissive)

## Mock Data

The app currently uses mock measurement data for testing:
- 3 sample bowls (Yellow, Red, Black)
- Realistic distance measurements (5.2cm, 8.7cm, 12.1cm)
- Proper ranking system (1st, 2nd, 3rd place)

Replace the `MeasurementResult.createMock()` calls with actual measurement data once camera and processing are implemented.