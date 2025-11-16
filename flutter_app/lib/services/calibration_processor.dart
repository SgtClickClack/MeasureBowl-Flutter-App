import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for ChArUco camera calibration using ArUco markers
///
/// This service performs camera calibration using ChArUco boards to obtain
/// camera matrix and distortion coefficients for high-accuracy measurements.
/// The calibration process runs in a background isolate to prevent UI freezes.
class CalibrationProcessor {
  // Storage keys for calibration data
  static const String _keyCameraMatrix = 'pro_accuracy_camera_matrix';
  static const String _keyDistortionCoeffs = 'pro_accuracy_distortion_coeffs';
  static const String _keyHasCalibration = 'pro_accuracy_has_calibration';

  /// Run ChArUco calibration on a set of calibration images
  ///
  /// [imageBytesList] - List of image byte arrays from calibration captures
  /// [boardSize] - ChArUco board size (width, height) in squares
  /// [squareLength] - Length of a square in real-world units (mm)
  /// [markerLength] - Length of a marker in real-world units (mm)
  ///
  /// Returns a Map with:
  /// - 'success': bool indicating if calibration succeeded
  /// - 'cameraMatrix': 3x3 camera matrix as nested list
  /// - 'distortionCoeffs': distortion coefficients as list
  /// - 'error': String error message if calibration failed
  static Future<Map<String, dynamic>> runCalibration({
    required List<Uint8List> imageBytesList,
    required (int, int) boardSize,
    required double squareLength,
    required double markerLength,
  }) async {
    debugPrint(
      '[CalibrationProcessor] Starting ChArUco calibration with ${imageBytesList.length} images...',
    );

    // Run calibration in background isolate to prevent UI freeze
    try {
      final result = await Isolate.run(() => _runCalibrationInIsolate(
            imageBytesList,
            boardSize,
            squareLength,
            markerLength,
          ));

      if (result['success'] == true) {
        // Save calibration data
        final saved = await _saveCalibration(
          result['cameraMatrix'] as List<List<double>>,
          result['distortionCoeffs'] as List<double>,
        );
        if (!saved) {
          debugPrint(
              '[CalibrationProcessor] Warning: Failed to save calibration data');
        }
      }

      return result;
    } catch (e, s) {
      debugPrint('[CalibrationProcessor] Error in calibration: $e');
      debugPrint('[CalibrationProcessor] Stack trace: $s');
      return {
        'success': false,
        'error': 'Calibration failed: ${e.toString()}',
      };
    }
  }

  /// Internal calibration function that runs in an isolate
  ///
  /// This function performs the actual ChArUco calibration using OpenCV.
  /// It must be a top-level or static function to work with Isolate.run().
  static Map<String, dynamic> _runCalibrationInIsolate(
    List<Uint8List> imageBytesList,
    (int, int) boardSize,
    double squareLength,
    double markerLength,
  ) {
    // Track Mat objects for proper disposal
    final matsToDispose = <cv.Mat>[];

    try {
      debugPrint(
        '[CalibrationProcessor] Isolate: Processing ${imageBytesList.length} calibration images...',
      );

      // TODO: ArUco API bindings need to be verified after module compilation
      // The actual API may differ from the expected signature
      // For now, return an error indicating the API needs to be configured
      // Once the modules are compiled and bindings are available, uncomment and fix the code below
      return {
        'success': false,
        'error':
            'ArUco API bindings not yet available. The contrib modules have been enabled in pubspec.yaml, but the Dart bindings may need to be regenerated after a full rebuild. Please check the opencv_dart documentation for the correct API signatures.',
      };

      /* 
      // UNCOMMENT AND FIX AFTER VERIFYING ACTUAL API:
      
      // NOTE: All code below is commented out until API is verified
      
      // Get ArUco dictionary
      // NOTE: The actual API signature may differ - verify after rebuild
      final dictionary = cv.getPredefinedDictionary(cv.ArucoDict.DICT_4X4_50);
      debugPrint('[CalibrationProcessor] Isolate: ArUco dictionary loaded');

      // Create ArUco detector
      // NOTE: Constructor signature may differ
      final detector = cv.ArucoDetector(dictionary);
      debugPrint('[CalibrationProcessor] Isolate: ArUco detector created');

      // Lists to collect calibration data
      final List<List<cv.Point2f>> allCharucoCorners = [];
      final List<List<int>> allCharucoIds = [];

      // Process each calibration image
      for (int i = 0; i < imageBytesList.length; i++) {
        debugPrint(
          '[CalibrationProcessor] Isolate: Processing image ${i + 1}/${imageBytesList.length}...',
        );

        // Decode image
        final image = cv.imdecode(imageBytesList[i], cv.IMREAD_COLOR);
        if (image.isEmpty) {
          debugPrint(
            '[CalibrationProcessor] Isolate: Failed to decode image ${i + 1}',
          );
          continue;
        }
        matsToDispose.add(image);

        // Convert to grayscale for marker detection
        final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
        matsToDispose.add(gray);

        // Detect ArUco markers
        final (markerCorners, markerIds, _) = detector.detectMarkers(gray);
        debugPrint(
          '[CalibrationProcessor] Isolate: Image ${i + 1}: Detected ${markerIds.length} markers',
        );

        if (markerIds.isEmpty) {
          debugPrint(
            '[CalibrationProcessor] Isolate: No markers detected in image ${i + 1}, skipping...',
          );
          continue;
        }

        // Interpolate ChArUco corners from detected markers
        // Note: This is a simplified version. Full ChArUco requires a board definition.
        // For now, we'll use the marker corners directly for calibration.
        // In a full implementation, you would use cv.interpolateCornersCharuco()
        final charucoCorners = <cv.Point2f>[];
        final charucoIds = <int>[];

        // Extract corners from detected markers
        for (int j = 0; j < markerCorners.length; j++) {
          final corners = markerCorners[j];
          final id = markerIds[j];

          // Add all 4 corners of each marker
          for (int k = 0; k < 4; k++) {
            charucoCorners.add(corners[k]);
            charucoIds.add(id * 4 + k); // Create unique IDs for each corner
          }
        }

        if (charucoCorners.isNotEmpty) {
          allCharucoCorners.add(charucoCorners);
          allCharucoIds.add(charucoIds);
          debugPrint(
            '[CalibrationProcessor] Isolate: Image ${i + 1}: Added ${charucoCorners.length} corners',
          );
        }
      }

      if (allCharucoCorners.isEmpty) {
        return {
          'success': false,
          'error': 'No valid calibration data found. Ensure markers are visible in all images.',
        };
      }

      debugPrint(
        '[CalibrationProcessor] Isolate: Running camera calibration with ${allCharucoCorners.length} image sets...',
      );

      // Prepare object points (3D world coordinates)
      // For ChArUco, we need to map detected corners to their real-world positions
      // This is simplified - a full implementation would use the board definition
      final List<List<cv.Point3f>> objectPoints = [];
      for (final charucoIds in allCharucoIds) {
        final objPoints = <cv.Point3f>[];
        for (final id in charucoIds) {
          // Simplified: assume markers are on a flat plane at z=0
          // In reality, you'd calculate positions based on board layout
          final x = (id % boardSize.$1) * squareLength;
          final y = (id ~/ boardSize.$1) * squareLength;
          objPoints.add(cv.Point3f(x, y, 0.0));
        }
        objectPoints.add(objPoints);
      }

      // Get image size from first image
      final firstImage = cv.imdecode(imageBytesList[0], cv.IMREAD_COLOR);
      if (firstImage.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to decode first image for size detection',
        };
      }
      final imageSize = (firstImage.cols, firstImage.rows);
      firstImage.dispose();

      // Run camera calibration
      // Note: cv.calibrateCameraChAruco may not be available in opencv_dart
      // We'll use standard calibrateCamera as a fallback
      try {
        // Convert corners to the format expected by calibrateCamera
        final imagePoints = allCharucoCorners
            .map((corners) => corners.map((p) => cv.Point2f(p.x, p.y)).toList())
            .toList();

        final result = cv.calibrateCamera(
          objectPoints,
          imagePoints,
          imageSize,
        );

        // NOTE: calibrateCamera returns a tuple, not an object
        // Fix based on actual return type after verifying API
        // final cameraMatrix = result.cameraMatrix;
        // final distCoeffs = result.distCoeffs;

        // Convert Mat to nested list for serialization
        final cameraMatrixList = <List<double>>[];
        for (int i = 0; i < 3; i++) {
          final row = <double>[];
          for (int j = 0; j < 3; j++) {
            row.add(cameraMatrix.at<double>(i, j));
          }
          cameraMatrixList.add(row);
        }

        final distCoeffsList = <double>[];
        for (int i = 0; i < distCoeffs.rows; i++) {
          distCoeffsList.add(distCoeffs.at<double>(i, 0));
        }

        debugPrint(
          '[CalibrationProcessor] Isolate: Calibration completed successfully',
        );

        return {
          'success': true,
          'cameraMatrix': cameraMatrixList,
          'distortionCoeffs': distCoeffsList,
        };
      } catch (e) {
        debugPrint(
          '[CalibrationProcessor] Isolate: Calibration error: $e',
        );
        return {
          'success': false,
          'error': 'Camera calibration failed: ${e.toString()}',
        };
      }
      */
    } catch (e, s) {
      debugPrint('[CalibrationProcessor] Isolate: Error: $e');
      debugPrint('[CalibrationProcessor] Isolate: Stack: $s');
      return {
        'success': false,
        'error': 'Calibration processing failed: ${e.toString()}',
      };
    } finally {
      // Dispose all Mat objects
      final disposedMats = <Object>{};
      for (final mat in matsToDispose) {
        try {
          if (!disposedMats.contains(mat)) {
            mat.dispose();
            disposedMats.add(mat);
          }
        } catch (e) {
          debugPrint(
              '[CalibrationProcessor] Isolate: Warning: Error disposing Mat: $e');
        }
      }
    }
  }

  /// Save calibration data to persistent storage
  static Future<bool> _saveCalibration(
    List<List<double>> cameraMatrix,
    List<double> distortionCoeffs,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCameraMatrix, jsonEncode(cameraMatrix));
      await prefs.setString(_keyDistortionCoeffs, jsonEncode(distortionCoeffs));
      await prefs.setBool(_keyHasCalibration, true);
      debugPrint('[CalibrationProcessor] Calibration data saved');
      return true;
    } catch (e) {
      debugPrint('[CalibrationProcessor] Error saving calibration: $e');
      return false;
    }
  }

  /// Load calibration data from persistent storage
  ///
  /// Returns a Map with 'cameraMatrix' and 'distortionCoeffs', or null if not available
  static Future<Map<String, dynamic>?> loadCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCalibration = prefs.getBool(_keyHasCalibration) ?? false;

      if (!hasCalibration) {
        return null;
      }

      final cameraMatrixJson = prefs.getString(_keyCameraMatrix);
      final distCoeffsJson = prefs.getString(_keyDistortionCoeffs);

      if (cameraMatrixJson == null || distCoeffsJson == null) {
        return null;
      }

      final cameraMatrix = (jsonDecode(cameraMatrixJson) as List)
          .map(
              (row) => (row as List).map((e) => (e as num).toDouble()).toList())
          .toList();
      final distortionCoeffs = (jsonDecode(distCoeffsJson) as List)
          .map((e) => (e as num).toDouble())
          .toList();

      return {
        'cameraMatrix': cameraMatrix,
        'distortionCoeffs': distortionCoeffs,
      };
    } catch (e) {
      debugPrint('[CalibrationProcessor] Error loading calibration: $e');
      return null;
    }
  }

  /// Check if calibration data exists
  static Future<bool> hasCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasCalibration) ?? false;
    } catch (e) {
      debugPrint('[CalibrationProcessor] Error checking calibration: $e');
      return false;
    }
  }

  /// Clear stored calibration data
  static Future<bool> clearCalibration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCameraMatrix);
      await prefs.remove(_keyDistortionCoeffs);
      await prefs.setBool(_keyHasCalibration, false);
      debugPrint('[CalibrationProcessor] Calibration data cleared');
      return true;
    } catch (e) {
      debugPrint('[CalibrationProcessor] Error clearing calibration: $e');
      return false;
    }
  }
}
