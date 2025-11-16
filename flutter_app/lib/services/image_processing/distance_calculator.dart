import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import '../../models/detected_object.dart';
import '../detection_config.dart';

/// Calculates the HSV distance between two colors, accounting for hue wrap-around.
///
/// Hue is circular (0-179 wraps to 0), so we need to handle wrap-around.
/// @param h1 First hue value (0-179)
/// @param h2 Second hue value (0-179)
/// @return Distance in hue space (0-90)
double _hueDistance(double h1, double h2) {
  final diff = (h1 - h2).abs();
  return diff < 90 ? diff : 179 - diff;
}

/// Determines which team a bowl belongs to based on HSV color comparison.
///
/// Uses Euclidean distance in HSV space with wrap-around handling for hue.
/// @param hsvPixel The HSV pixel value as Vec3b
/// @param teamA Team A color as [H, S, V] or null if not calibrated
/// @param teamB Team B color as [H, S, V] or null if not calibrated
/// @return "Team A", "Team B", or "Unknown"
String getBowlTeam(
    cv.Vec3b hsvPixel, List<double>? teamA, List<double>? teamB) {
  // If team colors are not calibrated, return Unknown
  if (teamA == null || teamB == null) {
    debugPrint(
        "[ImageProcessor] _getBowlTeam: Team colors not calibrated. Returning Unknown.");
    return "Unknown";
  }

  // Extract HSV values from pixel (OpenCV HSV: H=0-179, S=0-255, V=0-255)
  final double pixelH = hsvPixel.val[0].toDouble();
  final double pixelS = hsvPixel.val[1].toDouble();
  final double pixelV = hsvPixel.val[2].toDouble();

  // Calculate distance to Team A
  double distanceToA = 0.0;
  if (teamA.length == 3) {
    final double hueDist = _hueDistance(pixelH, teamA[0]);
    final double satDist = pixelS - teamA[1];
    final double valDist = pixelV - teamA[2];
    distanceToA =
        sqrt(hueDist * hueDist + satDist * satDist + valDist * valDist);
  }

  // Calculate distance to Team B
  double distanceToB = 0.0;
  if (teamB.length == 3) {
    final double hueDist = _hueDistance(pixelH, teamB[0]);
    final double satDist = pixelS - teamB[1];
    final double valDist = pixelV - teamB[2];
    distanceToB =
        sqrt(hueDist * hueDist + satDist * satDist + valDist * valDist);
  }

  // Simple "closest team" logic with tolerance
  // 50 is a tolerance threshold - we can tune this
  final String result;
  if (distanceToA < distanceToB && distanceToA < 50) {
    result = "Team A";
  } else if (distanceToB < distanceToA && distanceToB < 50) {
    result = "Team B";
  } else {
    result = "Unknown";
  }

  debugPrint(
      "[ImageProcessor] _getBowlTeam: Dist to A: $distanceToA, Dist to B: $distanceToB, Result: $result");
  return result;
}

/// Calculates distances from jack to bowls using ellipse edge distances.
///
/// This function calculates the distance from the edge of the jack (circular)
/// to the edge of each bowl (elliptical), accounting for their actual shapes.
///
/// @param bowls List of detected bowl objects
/// @param jack The detected jack object
/// @param scaleMmPerPixel Scale factor to convert pixels to millimeters
/// @param originalImage The original BGR color image Mat (for team detection)
/// @param config The DetectionConfig (for jack detection parameters)
/// @param jackDiameterMm Jack diameter in millimeters for measurement calculations
/// @param teamAColor Team A HSV color [H, S, V] or null if not calibrated
/// @param teamBColor Team B HSV color [H, S, V] or null if not calibrated
/// @return List of bowl results with distances and teams, sorted by distance
List<Map<String, dynamic>> calculateBowlDistances(
  List<DetectedObject> bowls,
  DetectedObject jack,
  double scaleMmPerPixel,
  cv.Mat originalImage,
  DetectionConfig config, {
  double jackDiameterMm = 63.5,
  List<double>? teamAColor,
  List<double>? teamBColor,
}) {
  debugPrint(
    "[ImageProcessor._calculateBowlDistances] Isolate: Calculating distances for ${bowls.length} bowls...",
  );
  debugPrint(
    "[ImageProcessor._calculateBowlDistances] Scale: $scaleMmPerPixel mm/px, "
    "Jack: center=(${jack.centerX.toStringAsFixed(1)}, ${jack.centerY.toStringAsFixed(1)}), "
    "radius=${jack.radius.toStringAsFixed(1)}px, "
    "Jack diameter: ${jackDiameterMm}mm",
  );
  final List<Map<String, dynamic>> bowlResults = [];

  // Use the provided jack diameter to calculate jack radius in pixels
  // Convert jack diameter from mm to pixels using the scale
  final double jackRadiusMm = jackDiameterMm / 2.0;
  final double jackRadiusPixels = jackRadiusMm / scaleMmPerPixel;

  // Convert image to HSV once outside the loop for efficiency
  cv.Mat? hsvImage;
  try {
    hsvImage = cv.cvtColor(originalImage, cv.COLOR_BGR2HSV);
  } catch (e) {
    debugPrint(
      "[ImageProcessor._calculateBowlDistances] Error converting image to HSV: $e",
    );
  }

  for (final bowl in bowls) {
    // Calculate center-to-center distance
    final double dx = bowl.centerX - jack.centerX;
    final double dy = bowl.centerY - jack.centerY;
    final double centerToCenterDistance = sqrt(dx * dx + dy * dy);

    // Calculate edge-to-edge distance
    // Subtract both radii from center-to-center distance
    // Use the detected bowl radius directly (already in pixels)
    final double edgeToEdgeDistance =
        centerToCenterDistance - jackRadiusPixels - bowl.radius;

    // Ensure distance is non-negative (in case of overlapping objects)
    final double pixelDistance =
        edgeToEdgeDistance > 0 ? edgeToEdgeDistance : 0.0;

    // Convert to real-world distance in millimeters
    final double realDistanceMm = pixelDistance * scaleMmPerPixel;
    final double realDistanceCm = realDistanceMm / 10.0;

    // Debug logging for all bowls to track consistency
    debugPrint(
      "[ImageProcessor._calculateBowlDistances] Bowl at (${bowl.centerX.toStringAsFixed(1)}, ${bowl.centerY.toStringAsFixed(1)}): "
      "centerDist=${centerToCenterDistance.toStringAsFixed(1)}px, "
      "edgeDist=${edgeToEdgeDistance.toStringAsFixed(1)}px, "
      "realDist=${realDistanceCm.toStringAsFixed(2)}cm",
    );

    // Debug logging for 0.0 cm results
    if (realDistanceMm < 1.0) {
      debugPrint(
        "[ImageProcessor._calculateBowlDistances] WARNING: Bowl at (${bowl.centerX}, ${bowl.centerY}) has very small distance: ${realDistanceMm}mm (${realDistanceCm}cm)",
      );
      debugPrint("  - Center-to-center: ${centerToCenterDistance}px");
      debugPrint("  - Jack radius: ${jackRadiusPixels}px");
      debugPrint(
          "  - Bowl radius (detected): ${bowl.radius.toStringAsFixed(1)}px");
      debugPrint("  - Edge-to-edge: ${edgeToEdgeDistance}px");
    }

    // --- TEAM DETECTION STEP ---
    // Sample center pixel of bowl from pre-converted HSV image
    String teamName = 'Unknown';
    if (hsvImage != null) {
      try {
        // Sample center pixel of bowl
        final int centerX = bowl.centerX.toInt().clamp(0, hsvImage.cols - 1);
        final int centerY = bowl.centerY.toInt().clamp(0, hsvImage.rows - 1);
        final cv.Vec3b centerPixel = hsvImage.at<cv.Vec3b>(centerY, centerX);
        teamName = getBowlTeam(centerPixel, teamAColor, teamBColor);
        debugPrint(
          "[ImageProcessor] _getBowlTeam: Bowl at (${bowl.centerX.toStringAsFixed(1)}, ${bowl.centerY.toStringAsFixed(1)}) assigned to $teamName",
        );
      } catch (e) {
        debugPrint(
          "[ImageProcessor._calculateBowlDistances] Error detecting team for bowl: $e",
        );
      }
    }

    bowlResults.add({
      'distance': realDistanceMm,
      'x': bowl.centerX.toInt(), // Pixel x coordinate for overlay
      'y': bowl.centerY.toInt(), // Pixel y coordinate for overlay
      'area': bowl.area,
      'team': teamName, // Use the detected team
    });
  }

  // Dispose HSV image after processing all bowls
  hsvImage?.dispose();

  // Validation: Filter bowls with invalid sizes or distances
  // This helps ensure consistent measurements by rejecting outliers
  final validBowls = bowlResults.where((bowl) {
    final distanceCm = ((bowl['distance'] as num?)?.toDouble() ?? 0.0) / 10.0;
    final area = (bowl['area'] as num?)?.toDouble() ?? 0.0;
    final x = (bowl['x'] as num?)?.toDouble() ?? 0.0;
    final y = (bowl['y'] as num?)?.toDouble() ?? 0.0;

    // Validate distance is reasonable (not too small, not impossibly large)
    // Typical lawn bowls distances: 0.1cm to 500cm
    if (distanceCm < 0.1) {
      debugPrint(
        "[ImageProcessor._calculateBowlDistances] VALIDATION: Removing bowl at "
        "(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}) - distance too small: "
        "${distanceCm.toStringAsFixed(2)}cm",
      );
      return false;
    }

    if (distanceCm > 500.0) {
      debugPrint(
        "[ImageProcessor._calculateBowlDistances] VALIDATION: Removing bowl at "
        "(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}) - distance too large: "
        "${distanceCm.toStringAsFixed(2)}cm (likely detection error)",
      );
      return false;
    }

    // Validate bowl area is reasonable
    // Typical bowl area: 1000-50000 pixels depending on camera distance
    // Lowered to 30.0 to match relaxed contour detection filter
    // DISABLED FOR DATA GATHERING:
    // if (area < 30.0) {
    //   debugPrint(
    //     "[ImageProcessor._calculateBowlDistances] VALIDATION: Removing bowl at "
    //     "(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}) - area too small: "
    //     "${area.toStringAsFixed(1)}px² (likely noise)",
    //   );
    //   return false;
    // }

    if (area > 100000.0) {
      debugPrint(
        "[ImageProcessor._calculateBowlDistances] VALIDATION: Removing bowl at "
        "(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}) - area too large: "
        "${area.toStringAsFixed(1)}px² (likely detection error)",
      );
      return false;
    }

    return true;
  }).toList();

  // Log validation results
  final rejectedCount = bowlResults.length - validBowls.length;
  if (rejectedCount > 0) {
    debugPrint(
      "[ImageProcessor._calculateBowlDistances] VALIDATION: Rejected $rejectedCount bowl(s) "
      "due to invalid size or distance",
    );
  }

  // Sort by distance (closest first)
  validBowls.sort((a, b) => a['distance'].compareTo(b['distance']));

  // Return all valid bowls (no artificial limit)
  // This enables detection of 8+ bowls in complex spread-out heads,
  // exceeding Bowlometre's 6-bowl limit and proving "Stand 'n' Measure" superiority
  final result = validBowls;
  debugPrint(
    "[ImageProcessor._calculateBowlDistances] Isolate: Calculated distances for ${result.length} valid bowls (filtered out ${bowlResults.length - validBowls.length} with 0.0cm).",
  );
  return result;
}
