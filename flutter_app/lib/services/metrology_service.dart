import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;

/// Service for high-accuracy metrology using homography-based perspective correction
///
/// This service detects ArUco corner markers and computes a homography matrix
/// to correct perspective distortion for accurate distance measurements.
class MetrologyService {
  // Corner marker IDs for the measurement mat
  static const int markerIdTopLeft = 10;
  static const int markerIdTopRight = 11;
  static const int markerIdBottomRight = 12;
  static const int markerIdBottomLeft = 13;

  // Real-world coordinates of corner markers in millimeters
  // These should match the physical layout of the measurement mat
  // Default assumes a square mat, but can be configured
  static const double defaultMatWidthMm = 2000.0; // 2 meters
  static const double defaultMatHeightMm = 2000.0; // 2 meters

  /// Find homography matrix from detected ArUco corner markers
  ///
  /// [imageBytes] - Image bytes containing the measurement scene with corner markers
  /// [matWidthMm] - Real-world width of the measurement mat in millimeters
  /// [matHeightMm] - Real-world height of the measurement mat in millimeters
  ///
  /// Returns a Map with:
  /// - 'success': bool indicating if homography was found
  /// - 'homography': 3x3 homography matrix as nested list (if successful)
  /// - 'error': String error message if homography calculation failed
  static Map<String, dynamic> findHomographyMatrix(
    Uint8List imageBytes, {
    double matWidthMm = defaultMatWidthMm,
    double matHeightMm = defaultMatHeightMm,
  }) {
    // Track Mat objects for proper disposal
    final matsToDispose = <cv.Mat>[];

    try {
      debugPrint('[MetrologyService] Finding homography matrix...');

      // Decode image
      final image = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (image.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to decode image',
        };
      }
      matsToDispose.add(image);

      // Convert to grayscale for marker detection
      final gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
      matsToDispose.add(gray);

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
      
      // Get ArUco dictionary
      // NOTE: The actual API signature may differ - verify after rebuild
      final dictionary = cv.getPredefinedDictionary(cv.ArucoDict.DICT_4X4_50);
      debugPrint('[MetrologyService] ArUco dictionary loaded');

      // Create ArUco detector
      // NOTE: Constructor signature may differ
      final detector = cv.ArucoDetector(dictionary);
      debugPrint('[MetrologyService] ArUco detector created');

      // Detect markers
      // NOTE: Return type may differ - may return VecPoint2f instead of List
      final (markerCorners, markerIds, _) = detector.detectMarkers(gray);
      debugPrint(
        '[MetrologyService] Detected ${markerIds.length} markers: ${markerIds.toList()}',
      );

      if (markerIds.isEmpty) {
        return {
          'success': false,
          'error': 'No ArUco markers detected in image',
        };
      }

      // Find the 4 corner markers (IDs 10, 11, 12, 13)
      final Map<int, List<cv.Point2f>> cornerMarkers = {};
      for (int i = 0; i < markerIds.length; i++) {
        final id = markerIds[i];
        if (id == markerIdTopLeft ||
            id == markerIdTopRight ||
            id == markerIdBottomRight ||
            id == markerIdBottomLeft) {
          cornerMarkers[id] = markerCorners[i];
          debugPrint('[MetrologyService] Found corner marker ID $id');
        }
      }

      // Check if all 4 corner markers were found
      if (cornerMarkers.length != 4) {
        final missing = <int>[];
        if (!cornerMarkers.containsKey(markerIdTopLeft)) missing.add(markerIdTopLeft);
        if (!cornerMarkers.containsKey(markerIdTopRight)) missing.add(markerIdTopRight);
        if (!cornerMarkers.containsKey(markerIdBottomRight)) missing.add(markerIdBottomRight);
        if (!cornerMarkers.containsKey(markerIdBottomLeft)) missing.add(markerIdBottomLeft);

        return {
          'success': false,
          'error': 'Missing corner markers: ${missing.join(", ")}. Found ${cornerMarkers.length}/4 markers.',
        };
      }

      // Extract corner points from markers
      final srcPoints = <cv.Point2f>[];
      final topLeftCorners = cornerMarkers[markerIdTopLeft]!;
      srcPoints.add(topLeftCorners[0]);
      final topRightCorners = cornerMarkers[markerIdTopRight]!;
      srcPoints.add(topRightCorners[1]);
      final bottomRightCorners = cornerMarkers[markerIdBottomRight]!;
      srcPoints.add(bottomRightCorners[2]);
      final bottomLeftCorners = cornerMarkers[markerIdBottomLeft]!;
      srcPoints.add(bottomLeftCorners[3]);

      // Create destination points (real-world coordinates in millimeters)
      final dstPoints = <cv.Point2f>[
        cv.Point2f(0.0, 0.0),
        cv.Point2f(matWidthMm, 0.0),
        cv.Point2f(matWidthMm, matHeightMm),
        cv.Point2f(0.0, matHeightMm),
      ];

      // Compute homography matrix
      // NOTE: May need VecPoint instead of List<Point2f>
      final homography = cv.getPerspectiveTransform(
        cv.VecPoint2f.fromList(srcPoints),
        cv.VecPoint2f.fromList(dstPoints),
      );
      matsToDispose.add(homography);

      // Convert Mat to nested list for serialization
      final homographyList = <List<double>>[];
      for (int i = 0; i < 3; i++) {
        final row = <double>[];
        for (int j = 0; j < 3; j++) {
          row.add(homography.at<double>(i, j));
        }
        homographyList.add(row);
      }

      return {
        'success': true,
        'homography': homographyList,
      };
      */
    } catch (e, s) {
      debugPrint('[MetrologyService] Error finding homography: $e');
      debugPrint('[MetrologyService] Stack trace: $s');
      return {
        'success': false,
        'error': 'Failed to compute homography: ${e.toString()}',
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
          debugPrint('[MetrologyService] Warning: Error disposing Mat: $e');
        }
      }
    }
  }

  /// Apply homography transformation to a point
  ///
  /// [homography] - 3x3 homography matrix as nested list
  /// [point] - Point to transform (x, y) in image coordinates
  ///
  /// Returns transformed point (x, y) in real-world coordinates
  static (double, double)? transformPoint(
    List<List<double>> homography,
    (double, double) point,
  ) {
    try {
      final x = point.$1;
      final y = point.$2;

      // Apply homography transformation
      // [x']   [h00 h01 h02] [x]
      // [y'] = [h10 h11 h12] [y]
      // [w']   [h20 h21 h22] [1]
      final w = homography[2][0] * x + homography[2][1] * y + homography[2][2];
      if (w.abs() < 1e-10) {
        return null; // Point at infinity
      }

      final xTransformed =
          (homography[0][0] * x + homography[0][1] * y + homography[0][2]) / w;
      final yTransformed =
          (homography[1][0] * x + homography[1][1] * y + homography[1][2]) / w;

      return (xTransformed, yTransformed);
    } catch (e) {
      debugPrint('[MetrologyService] Error transforming point: $e');
      return null;
    }
  }
}
