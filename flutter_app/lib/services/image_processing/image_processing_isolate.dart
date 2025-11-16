import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import '../../models/detected_object.dart';
import '../detection_config.dart';
import '../../utils/jack_filter.dart';
import 'contour_detector.dart';
import 'distance_calculator.dart' show calculateBowlDistances, getBowlTeam;
import '../metrology_service.dart';

/// Finds the jack from a list of detected objects using aspect ratio and size heuristics.
///
/// The jack is a perfect sphere, which projects as a circle (aspect ratio ≈ 1.0).
/// Bowls are oblate spheroids, which project as ellipses (aspect ratio > 1.0).
/// The jack is also typically smaller than bowls (jack ~63.5mm, bowls ~120-130mm).
///
/// @param objects List of all detected objects (jack + bowls)
/// @param maxAspectRatio Maximum aspect ratio to consider (filters out noise)
/// @param minRadiusPixels Minimum radius in pixels for jack (default: 15)
/// @param maxRadiusPixels Maximum radius in pixels for jack (default: 150)
/// @return The detected jack, or null if not found
DetectedObject? findJack(
  List<DetectedObject> objects, {
  double maxAspectRatio = 1.8,
  double minRadiusPixels = 15.0,
  double maxRadiusPixels = 150.0,
}) {
  if (objects.isEmpty) {
    return null;
  }

  // First pass: Find all candidates with good aspect ratios
  final List<DetectedObject> candidates = [];

  for (final obj in objects) {
    // Filter out objects with aspect ratio > maxAspectRatio (very long/thin)
    if (obj.aspectRatio > maxAspectRatio) {
      continue;
    }

    // Size validation: Jack should be within reasonable size range
    final radius = obj.radius;
    if (radius < minRadiusPixels || radius > maxRadiusPixels) {
      debugPrint(
        "[ImageProcessor.findJack] Rejecting candidate: radius ${radius.toStringAsFixed(1)}px "
        "outside range [$minRadiusPixels, $maxRadiusPixels]px",
      );
      continue;
    }

    candidates.add(obj);
  }

  if (candidates.isEmpty) {
    debugPrint(
      "[ImageProcessor.findJack] No valid candidates found after filtering",
    );
    return null;
  }

  debugPrint(
    "[ImageProcessor.findJack] Found ${candidates.length} valid candidates "
    "(aspect ratio <= $maxAspectRatio, radius in [$minRadiusPixels, $maxRadiusPixels]px)",
  );

  // Second pass: Among candidates, prefer the one with:
  // 1. Lowest aspect ratio (most circular)
  // 2. If aspect ratios are very close (within 0.1), prefer the smaller one (jack is smaller than bowls)
  DetectedObject? bestJack;
  double minAspectRatio = double.infinity;
  final double aspectRatioTolerance =
      0.1; // Consider aspect ratios within 0.1 as "similar"

  for (final obj in candidates) {
    final isBetter = obj.aspectRatio < minAspectRatio - aspectRatioTolerance ||
        (obj.aspectRatio < minAspectRatio + aspectRatioTolerance &&
            bestJack != null &&
            obj.radius < bestJack!.radius);

    if (isBetter) {
      minAspectRatio = obj.aspectRatio;
      bestJack = obj;
    }
  }

  if (bestJack != null) {
    debugPrint(
      "[ImageProcessor.findJack] Selected jack: aspect ratio ${bestJack.aspectRatio.toStringAsFixed(3)}, "
      "radius ${bestJack.radius.toStringAsFixed(1)}px, "
      "center (${bestJack.centerX.toStringAsFixed(1)}, ${bestJack.centerY.toStringAsFixed(1)})",
    );
  }

  return bestJack;
}

// Scale validation bounds (mm per pixel)
// These bounds ensure the detected jack size is reasonable
// Typical range: 0.1-2.0 mm/pixel depending on camera distance and resolution
// Increased max to 5.0 to allow detection when camera is further away (smaller jack)
const double _minScaleMmPerPixel = 0.05; // Very close-up view
const double _maxScaleMmPerPixel =
    5.0; // Very far view or very small jack detection (increased from 3.0)

/// Top-level function to process image in background isolate
/// This prevents blocking the main UI thread during CPU-intensive OpenCV operations
/// Uses the new contour-based detection pipeline
Future<Map<String, dynamic>> processImageInBackground(
  Map<String, dynamic> params,
) async {
  final Uint8List imageBytes = params['imageBytes'] as Uint8List;
  final String imagePath = params['imagePath'] as String;
  final Map<String, dynamic>? configMap =
      params['detectionConfig'] as Map<String, dynamic>?;
  final List<double>? teamAColor = params['teamAColor'] != null
      ? List<double>.from(params['teamAColor'] as List)
      : null;
  final List<double>? teamBColor = params['teamBColor'] != null
      ? List<double>.from(params['teamBColor'] as List)
      : null;
  final bool proAccuracyMode = params['proAccuracyMode'] as bool? ?? false;
  // Read manual jack position if provided
  final List<dynamic>? manualPositionList =
      params['manualJackPosition'] as List<dynamic>?;
  final Offset? manualJackPosition =
      manualPositionList != null && manualPositionList.length == 2
          ? Offset(
              (manualPositionList[0] as num).toDouble(),
              (manualPositionList[1] as num).toDouble(),
            )
          : null;
  // Read jack diameter from params
  final double jackDiameterMm =
      (params['jackDiameterMm'] as num?)?.toDouble() ?? 63.5;

  // Track Mat objects for proper disposal
  final matsToDispose = <cv.Mat>[];

  try {
    // --- Step 0: Verify OpenCV native library is available ---
    debugPrint(
      "[ImageProcessor] Isolate: Step 0: Verifying OpenCV native library...",
    );
    try {
      final testMat = cv.Mat.zeros(10, 10, cv.MatType.CV_8UC1);
      testMat.dispose();
      debugPrint(
        "[ImageProcessor] Isolate: Step 0 SUCCESS: OpenCV native library is available.",
      );
    } catch (e, s) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 0 FAILED: OpenCV native library not available.",
      );
      debugPrint("[ImageProcessor] Isolate: Error: $e");
      debugPrint("[ImageProcessor] Isolate: Stack: $s");
      return {
        'success': false,
        'error':
            'OpenCV native library not available: ${e.toString()}. Please ensure opencv_dart is properly configured for your platform.',
      };
    }

    // --- Step 1: Detect all objects using contour-based pipeline ---
    debugPrint(
      "[ImageProcessor] Isolate: Step 1: Running contour-based detection pipeline...",
    );
    // Deserialize detection config from main isolate or use defaults
    final DetectionConfig detectionConfig;
    if (configMap != null) {
      detectionConfig = DetectionConfig(
        whiteLowerHsv: List<int>.from(configMap['whiteLowerHsv'] as List),
        whiteUpperHsv: List<int>.from(configMap['whiteUpperHsv'] as List),
        blurKernelSize: configMap['blurKernelSize'] as int,
        minContourArea: (configMap['minContourArea'] as num).toDouble(),
        maxContourArea: (configMap['maxContourArea'] as num).toDouble(),
        maxAspectRatioForJack:
            (configMap['maxAspectRatioForJack'] as num).toDouble(),
      );
      debugPrint(
        "[ImageProcessor] Isolate: Step 1: Using custom detection config from main isolate",
      );
    } else {
      detectionConfig = const DetectionConfig();
      debugPrint(
        "[ImageProcessor] Isolate: Step 1: Using default detection config",
      );
    }
    // Create debug logs list to capture processing logs
    final List<String> debugLogs = [];
    List<DetectedObject> allObjects = await processImage(
      imageBytes,
      config: detectionConfig,
      debugLogs: debugLogs,
    );

    // If contour detection fails, try HoughCircles as fallback
    if (allObjects.isEmpty) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 1: Contour detection found no objects. Trying HoughCircles fallback...",
      );
      allObjects = detectCirclesWithHough(
        imageBytes,
        debugLogs: debugLogs,
      );

      if (allObjects.isEmpty) {
        debugPrint(
          "[ImageProcessor] Isolate: Step 1 FAILED: No objects detected with contour detection or HoughCircles fallback.",
        );
        return {
          'success': false,
          'error':
              'No objects detected in image. Please ensure the jack and bowls are clearly visible and well-lit.',
        };
      } else {
        debugPrint(
          "[ImageProcessor] Isolate: Step 1 SUCCESS: HoughCircles fallback detected ${allObjects.length} objects.",
        );
      }
    } else {
      debugPrint(
        "[ImageProcessor] Isolate: Step 1 SUCCESS: Detected ${allObjects.length} objects using contour detection.",
      );
    }

    // Log all detected objects for debugging consistency issues
    debugPrint(
      "[ImageProcessor] Isolate: Step 1 DETAILS: All detected objects:",
    );
    for (int i = 0; i < allObjects.length; i++) {
      final obj = allObjects[i];
      debugPrint(
        "  Object $i: center=(${obj.centerX.toStringAsFixed(1)}, ${obj.centerY.toStringAsFixed(1)}), "
        "radius=${obj.radius.toStringAsFixed(1)}px, "
        "aspectRatio=${obj.aspectRatio.toStringAsFixed(3)}, "
        "area=${obj.area.toStringAsFixed(1)}px²",
      );
    }

    // --- Step 2: Identify jack using manual position or automatic detection ---
    DetectedObject? jack;

    if (manualJackPosition != null) {
      // Use manual jack position provided by user
      debugPrint(
        "[ImageProcessor] Isolate: Step 2: Using manual jack position at (${manualJackPosition.dx}, ${manualJackPosition.dy})...",
      );
      // Create a DetectedObject from the manual position
      // Use default jack size: typical jack diameter is 63.5mm
      // Estimate radius in pixels (will be refined later with scale calculation)
      // Use a reasonable default radius of 30 pixels (will be adjusted based on actual scale)
      const defaultJackRadiusPixels = 30.0;
      jack = DetectedObject(
        centerX: manualJackPosition.dx,
        centerY: manualJackPosition.dy,
        majorAxis: defaultJackRadiusPixels * 2,
        minorAxis: defaultJackRadiusPixels * 2,
        angle: 0.0,
        area: pi * defaultJackRadiusPixels * defaultJackRadiusPixels,
      );
      debugPrint(
        "[ImageProcessor] Isolate: Step 2 SUCCESS: Using manual jack position at (${jack.centerX}, ${jack.centerY}).",
      );
    } else {
      // Use automatic detection
      debugPrint(
        "[ImageProcessor] Isolate: Step 2: Identifying jack from detected objects...",
      );
      // Lower minimum radius to 8px to handle cases where camera is further away
      // This allows detection of jacks that appear smaller in the image
      jack = findJack(
        allObjects,
        minRadiusPixels: 8.0,
        maxRadiusPixels: 150.0,
      );

      if (jack == null) {
        debugPrint(
            "[ImageProcessor] Isolate: Step 2 FAILED: No jack detected.");
        return {
          'success': false,
          'error':
              'No jack detected in image. Please ensure the jack is clearly visible and well-lit.',
        };
      }
      debugPrint(
        "[ImageProcessor] Isolate: Step 2 SUCCESS: Jack found at (${jack.centerX}, ${jack.centerY}) with aspect ratio ${jack.aspectRatio.toStringAsFixed(2)}.",
      );
    }

    // --- Step 3: Separate bowls from jack using robust geometric filtering ---
    // Use the new filterJack function with adaptive tolerance based on object sizes
    final List<DetectedObject> bowls = filterJack(allObjects, jack);
    debugPrint(
      "[ImageProcessor] Isolate: Step 3 SUCCESS: Identified ${bowls.length} bowls (excluded ${allObjects.length - bowls.length} jack/overlapping object(s)).",
    );

    // Validate bowl sizes are reasonable (bowls should be larger than jack)
    // Typical bowl diameter: 120-130mm, jack: 63.5mm
    // So bowls should be roughly 1.9-2.0x the size of jack in pixels
    // However, for complex spread-out heads, distant bowls may appear smaller due to perspective,
    // and very close bowls may appear larger. We use a more permissive range to handle these cases.
    final List<DetectedObject> validatedBowls = [];
    for (final bowl in bowls) {
      final sizeRatio = bowl.radius / jack.radius;

      // More permissive size ratio validation to handle spread-out heads:
      // - Lower minimum (0.5x) allows distant bowls that appear smaller due to perspective
      //   (Relaxed from 0.8x for production bug fix: "Pro Mode no results")
      // - Higher maximum (8.0x) allows very close bowls or bowls viewed from extreme angles
      //   (Relaxed from 4.0x for production bug fix: "Pro Mode no results")
      // This enables detection of 8+ bowls at various distances, exceeding Bowlometre's 6-bowl limit
      if (sizeRatio < 0.5 || sizeRatio > 8.0) {
        debugPrint(
          "[ImageProcessor] Isolate: Step 3 VALIDATION: Rejecting bowl at "
          "(${bowl.centerX.toStringAsFixed(1)}, ${bowl.centerY.toStringAsFixed(1)}) - "
          "size ratio ${sizeRatio.toStringAsFixed(2)}x jack (expected 0.5x-8.0x for spread-out heads). "
          "Bowl radius: ${bowl.radius.toStringAsFixed(1)}px, "
          "Jack radius: ${jack.radius.toStringAsFixed(1)}px",
        );
        continue;
      }

      validatedBowls.add(bowl);
    }

    if (validatedBowls.length != bowls.length) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 3 VALIDATION: Rejected ${bowls.length - validatedBowls.length} "
        "bowl(s) due to invalid size ratio",
      );
    }

    // Log bowl details for debugging
    if (validatedBowls.isNotEmpty) {
      debugPrint("[ImageProcessor] Isolate: Step 3 DETAILS: Validated bowls:");
      for (int i = 0; i < validatedBowls.length; i++) {
        final bowl = validatedBowls[i];
        final distanceFromJack = sqrt(
          pow(bowl.centerX - jack.centerX, 2) +
              pow(bowl.centerY - jack.centerY, 2),
        );
        final sizeRatio = bowl.radius / jack.radius;
        debugPrint(
          "  Bowl $i: center=(${bowl.centerX.toStringAsFixed(1)}, ${bowl.centerY.toStringAsFixed(1)}), "
          "radius=${bowl.radius.toStringAsFixed(1)}px (${sizeRatio.toStringAsFixed(2)}x jack), "
          "aspectRatio=${bowl.aspectRatio.toStringAsFixed(3)}, "
          "centerDistance=${distanceFromJack.toStringAsFixed(1)}px",
        );
      }
    }

    // --- Step 4: Calculate scale from jack with validation ---
    // Use the average of major and minor axes as the diameter
    final double jackRadiusPixels = jack.radius;
    final double jackDiameterPixels = jackRadiusPixels * 2;

    // Guard clause: Prevent division by zero when jack is too small
    if (jackDiameterPixels < 5.0) {
      // e.g., anything less than 5 pixels wide
      debugPrint(
        "[ImageProcessor] Isolate: Step 4 FAILED: Jack diameter ${jackDiameterPixels.toStringAsFixed(1)}px "
        "is too small to measure accurately (less than 5 pixels wide).",
      );
      return {
        'success': false,
        'error':
            'SCALE_ERROR: Jack is too small to measure accurately (less than 5 pixels wide). Please move the camera closer.',
      };
    }

    final double scaleMmPerPixel = jackDiameterMm / jackDiameterPixels;

    // Validate scale factor is within reasonable bounds
    if (scaleMmPerPixel < _minScaleMmPerPixel ||
        scaleMmPerPixel > _maxScaleMmPerPixel) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 4 FAILED: Scale $scaleMmPerPixel mm/px "
        "outside valid range [$_minScaleMmPerPixel, $_maxScaleMmPerPixel] mm/px",
      );
      debugPrint(
        "[ImageProcessor] Isolate: This suggests the wrong object was selected as jack. "
        "Jack radius: ${jackRadiusPixels.toStringAsFixed(1)}px, "
        "diameter: ${jackDiameterPixels.toStringAsFixed(1)}px",
      );
      return {
        'success': false,
        'error':
            'Invalid scale calculation detected. The detected jack size is outside expected range. '
                'Please ensure the jack is clearly visible and not obscured.',
      };
    }

    // Additional validation: Check that jack radius is reasonable
    // Jack should be roughly 20-100 pixels in typical photos
    // This is a sanity check in addition to findJack's validation
    if (jackRadiusPixels < 10.0 || jackRadiusPixels > 200.0) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 4 WARNING: Jack radius ${jackRadiusPixels.toStringAsFixed(1)}px "
        "seems unusual (expected ~20-100px). Scale: $scaleMmPerPixel mm/px",
      );
    }

    debugPrint(
      "[ImageProcessor] Isolate: Step 4 SUCCESS: Scale calculated as $scaleMmPerPixel mm/px "
      "(jack radius: ${jackRadiusPixels.toStringAsFixed(1)}px, "
      "diameter: ${jackDiameterPixels.toStringAsFixed(1)}px)",
    );

    // --- Step 5: Decode original image for color detection ---
    debugPrint(
      "[ImageProcessor] Isolate: Step 5: Decoding original image for color detection...",
    );
    final cv.Mat originalImage = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
    if (originalImage.isEmpty) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 5 FAILED: Failed to decode image for color detection.",
      );
      return {
        'success': false,
        'error': 'Failed to decode image for color detection.',
      };
    }
    matsToDispose.add(originalImage);

    debugPrint(
      "[ImageProcessor] Isolate: Step 5 SUCCESS: Original image decoded for LAB-based color detection.",
    );

    // Get original image dimensions for coordinate scaling
    final int originalImageWidth = originalImage.cols;
    final int originalImageHeight = originalImage.rows;
    debugPrint(
      "[ImageProcessor] Isolate: Original image dimensions: ${originalImageWidth}x${originalImageHeight}px",
    );

    // --- Step 6: Try Pro Accuracy (homography-based) or fall back to mm/pixel method ---
    debugPrint("[ImageProcessor] Isolate: Step 6: Calculating distances...");
    if (proAccuracyMode) {
      debugPrint(
        "[ImageProcessor] Isolate: Pro Accuracy Mode enabled by user setting.",
      );
    }

    bool usingHighAccuracy = false;
    String accuracyMessage = 'Results are an estimate.';
    List<Map<String, dynamic>> bowlResults;

    // Try to find homography matrix for Pro Accuracy
    debugPrint(
      "[ImageProcessor] Isolate: Step 6a: Attempting Pro Accuracy (homography-based measurement)...",
    );
    final homographyResult = MetrologyService.findHomographyMatrix(imageBytes);

    if (homographyResult['success'] == true) {
      // Pro Accuracy available - use homography-based measurement
      usingHighAccuracy = true;
      accuracyMessage = proAccuracyMode
          ? 'High-accuracy measurement using perspective correction (Pro Mode enabled).'
          : 'High-accuracy measurement using perspective correction.';
      debugPrint(
        "[ImageProcessor] Isolate: Step 6a SUCCESS: Homography matrix found. Using Pro Accuracy.",
      );

      final homography = homographyResult['homography'] as List<List<double>>;

      // Transform jack and bowl positions using homography
      final jackTransformed = MetrologyService.transformPoint(
        homography,
        (jack.centerX, jack.centerY),
      );

      if (jackTransformed == null) {
        debugPrint(
          "[ImageProcessor] Isolate: Step 6a WARNING: Failed to transform jack position. Falling back to mm/pixel method.",
        );
        usingHighAccuracy = false;
        accuracyMessage = 'Results are an estimate.';
        bowlResults = calculateBowlDistances(
          validatedBowls,
          jack,
          scaleMmPerPixel,
          originalImage,
          detectionConfig,
          jackDiameterMm: jackDiameterMm,
          teamAColor: teamAColor,
          teamBColor: teamBColor,
        );
      } else {
        // Transform all bowl positions
        final transformedBowls = <DetectedObject>[];
        for (final bowl in validatedBowls) {
          final bowlTransformed = MetrologyService.transformPoint(
            homography,
            (bowl.centerX, bowl.centerY),
          );

          if (bowlTransformed != null) {
            // Create a new DetectedObject with transformed coordinates
            // For distance calculation, we'll use the transformed coordinates
            // but keep the original object properties
            transformedBowls.add(bowl);
          }
        }

        // Convert image to HSV once outside the loop for efficiency and proper disposal
        cv.Mat? hsvImage;
        try {
          hsvImage = cv.cvtColor(originalImage, cv.COLOR_BGR2HSV);
          matsToDispose.add(hsvImage);
        } catch (e) {
          debugPrint(
            "[ImageProcessor] Isolate: Error converting image to HSV: $e",
          );
        }

        // Calculate distances using transformed coordinates
        // We need to calculate distances in real-world coordinates (mm)
        final bowlResultsList = <Map<String, dynamic>>[];

        for (final bowl in validatedBowls) {
          final bowlTransformed = MetrologyService.transformPoint(
            homography,
            (bowl.centerX, bowl.centerY),
          );

          if (bowlTransformed == null) continue;

          // Calculate distance in real-world coordinates (mm)
          final dx = bowlTransformed.$1 - jackTransformed.$1;
          final dy = bowlTransformed.$2 - jackTransformed.$2;
          final centerToCenterDistanceMm = sqrt(dx * dx + dy * dy);

          // Use the provided jack diameter to calculate jack radius in mm
          final double jackRadiusMm = jackDiameterMm / 2.0;
          // Convert detected bowl radius from pixels to mm using the scale
          final double bowlRadiusMm = bowl.radius * scaleMmPerPixel;

          // Calculate edge-to-edge distance in mm
          final edgeToEdgeDistanceMm =
              centerToCenterDistanceMm - jackRadiusMm - bowlRadiusMm;
          final realDistanceMm =
              edgeToEdgeDistanceMm > 0 ? edgeToEdgeDistanceMm : 0.0;

          // Team detection (using original image coordinates)
          String teamName = 'Unknown';
          if (hsvImage != null) {
            try {
              final int centerX =
                  bowl.centerX.toInt().clamp(0, hsvImage.cols - 1);
              final int centerY =
                  bowl.centerY.toInt().clamp(0, hsvImage.rows - 1);
              final cv.Vec3b centerPixel =
                  hsvImage.at<cv.Vec3b>(centerY, centerX);

              // Use the shared getBowlTeam function for consistent team detection
              teamName = getBowlTeam(centerPixel, teamAColor, teamBColor);
              debugPrint(
                "[ImageProcessor] Isolate: Bowl at (${bowl.centerX}, ${bowl.centerY}) assigned to $teamName",
              );
            } catch (e) {
              debugPrint(
                "[ImageProcessor] Isolate: Error detecting team for bowl: $e",
              );
            }
          }

          bowlResultsList.add({
            'distance': realDistanceMm,
            'x': bowl.centerX.toInt(), // Pixel x coordinate for overlay
            'y': bowl.centerY.toInt(), // Pixel y coordinate for overlay
            'area': bowl.area,
            'team': teamName,
          });
        }

        // Sort by distance
        bowlResultsList.sort((a, b) => a['distance'].compareTo(b['distance']));
        bowlResults = bowlResultsList;

        debugPrint(
          "[ImageProcessor] Isolate: Step 6a SUCCESS: Calculated ${bowlResults.length} distances using Pro Accuracy (homography-based).",
        );
      }
    } else {
      // Pro Accuracy not available - fall back to mm/pixel method
      debugPrint(
        "[ImageProcessor] Isolate: Step 6a: Pro Accuracy not available (${homographyResult['error']}). Using mm/pixel method.",
      );
      bowlResults = calculateBowlDistances(
        validatedBowls,
        jack,
        scaleMmPerPixel,
        originalImage,
        detectionConfig,
        jackDiameterMm: jackDiameterMm,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
      );
      debugPrint(
        "[ImageProcessor] Isolate: Step 6 SUCCESS: Calculated ${bowlResults.length} distances using mm/pixel method.",
      );
    }

    // Log final measurement results for debugging consistency
    if (bowlResults.isNotEmpty) {
      debugPrint(
        "[ImageProcessor] Isolate: Step 6 DETAILS: Final measurements:",
      );
      for (int i = 0; i < bowlResults.length; i++) {
        final bowl = bowlResults[i];
        final distanceCm =
            ((bowl['distance'] as num?)?.toDouble() ?? 0.0) / 10.0;
        debugPrint(
          "  Bowl $i: team=${bowl['team']}, "
          "distance=${distanceCm.toStringAsFixed(2)}cm, "
          "position=(${bowl['x'].toStringAsFixed(1)}, ${bowl['y'].toStringAsFixed(1)}), "
          "area=${bowl['area'].toStringAsFixed(1)}px²",
        );
      }
    }

    // Return successful processing results
    debugPrint(
      "[ImageProcessor] Isolate: ======================================================",
    );
    debugPrint("[ImageProcessor] Isolate: PROCESSING COMPLETE - SUCCESS");
    debugPrint(
      "[ImageProcessor] Isolate: ======================================================",
    );
    return {
      'success': true,
      'scale': scaleMmPerPixel,
      'jack_center': {'x': jack.centerX, 'y': jack.centerY},
      'jack_radius': jackRadiusPixels,
      'image_path': imagePath,
      'bowls': bowlResults,
      'using_high_accuracy': usingHighAccuracy,
      'accuracy_message': accuracyMessage,
      'debugLogs': debugLogs,
      'original_width': originalImageWidth,
      'original_height': originalImageHeight,
    };
  } catch (e, s) {
    debugPrint("======================================================");
    debugPrint("[ImageProcessor] Isolate: CRASH DETECTED IN IMAGE PROCESSOR");
    debugPrint("[ImageProcessor] Isolate: ERROR: $e");
    debugPrint("[ImageProcessor] Isolate: STACK TRACE: $s");
    debugPrint("======================================================");
    return {
      'success': false,
      'error': 'OpenCV processing failed: ${e.toString()}',
    };
  } finally {
    // --- CRITICAL MEMORY CLEANUP ---
    // Dispose all Mat objects to prevent native memory leaks
    // Use try-catch around each disposal to prevent double-free crashes.
    // IMPORTANT: Do NOT check isEmpty before disposing - it may access freed memory in release mode
    // Use identity-based tracking to prevent double disposal
    final disposedMats = <Object>{};
    for (final mat in matsToDispose) {
      try {
        // Use object identity to prevent double disposal
        if (!disposedMats.contains(mat)) {
          mat.dispose();
          disposedMats.add(mat);
        }
      } catch (e) {
        debugPrint(
            "[ImageProcessor] Isolate: Warning: Error disposing Mat: $e");
      }
    }
  }
}
