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

## Mock Data

The app currently uses mock measurement data for testing:
- 3 sample bowls (Yellow, Red, Black)
- Realistic distance measurements (5.2cm, 8.7cm, 12.1cm)
- Proper ranking system (1st, 2nd, 3rd place)

Replace the `MeasurementResult.createMock()` calls with actual measurement data once camera and processing are implemented.