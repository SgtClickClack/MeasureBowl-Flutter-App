import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import '../../models/detected_object.dart';
import '../detection_config.dart';

/// Fallback detection using HoughCircles when contour detection fails.
/// Uses more permissive parameters to find circles that contour detection might miss.
///
/// @param imageBytes The raw bytes of the image.
/// @param debugLogs Optional list to collect debug log messages.
/// @return A List<DetectedObject> containing all found circles.
List<DetectedObject> detectCirclesWithHough(
  Uint8List imageBytes, {
  List<String>? debugLogs,
}) {
  // Helper function to log debug messages
  void logDebug(String message) {
    if (debugLogs != null) {
      debugLogs!.add(message);
    } else {
      debugPrint(message);
    }
  }

  final matsToDispose = <cv.Mat>[];

  try {
    logDebug("[HoughCircles] Starting HoughCircles fallback detection...");

    // Decode image
    final cv.Mat originalImage = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
    if (originalImage.isEmpty) {
      logDebug("[HoughCircles] Failed to decode image");
      return [];
    }
    matsToDispose.add(originalImage);

    // Convert to grayscale
    final cv.Mat gray = cv.cvtColor(originalImage, cv.COLOR_BGR2GRAY);
    matsToDispose.add(gray);

    // Apply Gaussian blur
    final cv.Mat blurred = cv.gaussianBlur(
      gray,
      (9, 9),
      2.0,
      sigmaY: 2.0,
    );
    matsToDispose.add(blurred);

    // Detect circles using HoughCircles with permissive parameters
    logDebug(
        "[HoughCircles] Calling cv.HoughCircles with permissive parameters...");
    List<(double, double, double)> circles = [];

    try {
      // HoughCircles returns a Mat containing circle data
      final circlesMat = cv.HoughCircles(
        blurred,
        cv.HOUGH_GRADIENT,
        1.2, // dp (keep this)
        20, // minDist (lowered to find close circles)
        param1: 100, // Canny threshold (raised to reduce weak edges)
        param2:
            25, // Accumulator threshold (lowered to find less-perfect circles)
        minRadius: 10, // minRadius (raised slightly)
        maxRadius: 150, // maxRadius (greatly increased to find all bowls)
      );
      matsToDispose.add(circlesMat);

      // Extract circles from Mat
      // HoughCircles returns a Mat with shape (1, N, 3) where N is number of circles
      // Each circle is represented as (x, y, radius)
      if (circlesMat.rows > 0 && circlesMat.cols > 0) {
        // Access the data - circles are stored as float32
        for (int i = 0; i < circlesMat.cols; i++) {
          final x = circlesMat.at<double>(0, i * 3);
          final y = circlesMat.at<double>(0, i * 3 + 1);
          final radius = circlesMat.at<double>(0, i * 3 + 2);
          circles.add((x, y, radius));
        }
      }
    } catch (e) {
      logDebug("[HoughCircles] HoughCircles API error: $e");
      return [];
    }

    logDebug("[HoughCircles] HoughCircles found ${circles.length} circles");

    if (circles.isEmpty) {
      logDebug("[HoughCircles] Step 3 FAILED: HoughCircles found no circles.");
      return [];
    }

    // Convert circles to DetectedObject list
    final List<DetectedObject> results = [];
    for (final circle in circles) {
      final centerX = circle.$1;
      final centerY = circle.$2;
      final radius = circle.$3;

      // Create DetectedObject with circular shape (majorAxis == minorAxis)
      results.add(
        DetectedObject(
          centerX: centerX,
          centerY: centerY,
          majorAxis: radius * 2,
          minorAxis: radius * 2,
          angle: 0.0,
          area: math.pi * radius * radius,
        ),
      );
    }

    logDebug(
        "[HoughCircles] Converted ${results.length} circles to DetectedObject list");
    return results;
  } catch (e) {
    logDebug("[HoughCircles] Error in HoughCircles detection: $e");
    return [];
  } finally {
    // Clean up Mat objects
    final disposedMats = <Object>{};
    for (final mat in matsToDispose) {
      try {
        if (!disposedMats.contains(mat)) {
          mat.dispose();
          disposedMats.add(mat);
        }
      } catch (e) {
        logDebug("[HoughCircles] Warning: Error disposing Mat: $e");
      }
    }
  }
}

/// Processes a single 2D image to find all jacks and bowls using contour-based detection.
///
/// This function implements a 4-stage pipeline:
/// 1. Pre-processing (Gaussian blur on BGR image to reduce sensor noise)
/// 2. Illumination-Invariant Color Segmentation (HSV conversion and mask generation)
/// 3. Post-processing (Morphological OPEN to remove noise from masks)
/// 4. Contour Detection & Filtering (Ellipse fitting and geometric filtering)
///
/// This function is memory-safe. It tracks every allocated `cv.Mat` and
/// guarantees their disposal in a `finally` block to prevent native memory leaks.
///
/// @param imageBytes The raw bytes (e.g., from a JPG or PNG) of the image.
/// @param config Optional detection configuration. Uses default if not provided.
/// @param debugLogs Optional list to collect debug log messages.
/// @return A Future<List<DetectedObject>> containing all found objects.
Future<List<DetectedObject>> processImage(
  Uint8List imageBytes, {
  DetectionConfig? config,
  List<String>? debugLogs,
}) async {
  // Use provided config or default
  final detectionConfig = config ?? const DetectionConfig();

  // Helper function to log debug messages
  void logDebug(String message) {
    if (debugLogs != null) {
      debugLogs!.add(message);
    } else {
      debugPrint(message);
    }
  }

  // --- Memory Management ---
  // This list will track ALL cv.Mat objects created.
  // They MUST be manually disposed of to prevent native memory crashes.
  final matsToDispose = <cv.Mat>[];

  // This list will hold the final Dart-native results.
  final List<DetectedObject> results = [];

  try {
    // --- STAGE 1: Pre-processing (Noise Reduction) ---

    // 1. Decode Image
    // Convert the raw Uint8List into an OpenCV Mat object.
    // We decode it as a 3-channel (BGR) color image.
    final cv.Mat originalImage = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
    if (originalImage.isEmpty) {
      throw Exception("Failed to decode image or image is empty.");
    }
    matsToDispose.add(originalImage);

    // 2. Apply Gaussian Blur (Pre-processing) - Phase I: Noise Suppression
    // Apply blur to the BGR image BEFORE color conversion to reduce sensor noise
    // and high-frequency artifacts (e.g., sharp grass blades, camera sensor noise).
    // This prevents small, false-positive "pixel-blobs" in the mask.
    // Phase I implementation: Use 5x5 kernel with sigma ≈ 1.4 as per technical audit
    // to suppress high-frequency textural noise (grass) before edge detection.
    const ksize = (5, 5);
    const sigmaX = 1.4; // Standard deviation for Gaussian kernel
    final cv.Mat blurredBgr = cv.gaussianBlur(
      originalImage,
      ksize,
      sigmaX,
      sigmaY: sigmaX,
    );
    matsToDispose.add(blurredBgr);

    // --- STAGE 2: Illumination-Invariant Color Segmentation ---

    // 3. Convert to HSV Color Space
    // This is the key to robustness against lighting changes (shadows, sun).
    // Hue (H) remains stable even if Brightness (V) changes.
    // We convert the blurred BGR image to HSV for color segmentation.
    final cv.Mat hsvImage = cv.cvtColor(blurredBgr, cv.COLOR_BGR2HSV);
    matsToDispose.add(hsvImage);

    // 4. Define Color Ranges
    // OpenCV HSV ranges: H=0-179, S=0-255, V=0-255
    // Note: With Team Calibration, we no longer need color-specific bowl detection.
    // The detector finds all circular objects, and Team Calibration assigns teams later.

    // Range 1: White Jack
    // White has a very low Saturation (S) and high Value (V). Hue (H) can be anything.
    final cv.Mat lowerWhite = cv.Mat.fromList(
      1,
      3,
      cv.MatType.CV_8UC3,
      detectionConfig.whiteLowerHsv,
    );
    final cv.Mat upperWhite = cv.Mat.fromList(
      1,
      3,
      cv.MatType.CV_8UC3,
      detectionConfig.whiteUpperHsv,
    );
    matsToDispose.add(lowerWhite);
    matsToDispose.add(upperWhite);

    // Range 2: All Bowls (dark objects)
    // Bowls are detected as dark objects (low Value/brightness) regardless of color.
    // Team assignment happens later via Team Calibration system.
    // Using low V (brightness) threshold to catch all bowl colors (red, blue, black, etc.)
    // H and S can be anything, V < 180 to catch all non-white objects
    final cv.Mat lowerBowls = cv.Mat.fromList(
      1,
      3,
      cv.MatType.CV_8UC3,
      [0, 0, 0], // H: any, S: any, V: 0 (dark)
    );
    final cv.Mat upperBowls = cv.Mat.fromList(
      1,
      3,
      cv.MatType.CV_8UC3,
      [179, 255, 180], // H: any, S: any, V: 180 (exclude bright white objects)
    );
    matsToDispose.add(lowerBowls);
    matsToDispose.add(upperBowls);

    // 5. Create Binary Masks
    // Create a mask for white objects (jack).
    final cv.Mat maskWhite = cv.inRange(hsvImage, lowerWhite, upperWhite);
    matsToDispose.add(maskWhite);

    // Create a mask for all bowls (dark objects, regardless of color)
    final cv.Mat maskBowls = cv.inRange(hsvImage, lowerBowls, upperBowls);
    matsToDispose.add(maskBowls);

    // Debug: Count non-zero pixels in masks
    final whitePixels = cv.countNonZero(maskWhite);
    final bowlPixels = cv.countNonZero(maskBowls);
    logDebug(
      "[processImage] Mask pixel counts: white (jack)=$whitePixels, "
      "bowls (all colors)=$bowlPixels",
    );

    // 6. Combine Masks
    // Combine jack and bowl masks to detect all objects
    // Use max to combine masks (equivalent to bitwise OR for binary masks)
    final cv.Mat combinedMask = cv.max(maskWhite, maskBowls);
    matsToDispose.add(combinedMask);

    final combinedPixels = cv.countNonZero(combinedMask);
    logDebug("[processImage] Combined mask pixels: $combinedPixels");

    // --- STAGE 3: Post-processing (Noise Removal) ---

    // 7. Morphological OPEN Operation
    // Apply morphological OPEN (erosion followed by dilation) to remove small,
    // isolated white pixels (false positives) from the final mask without
    // significantly altering the size of the main objects.
    // This is highly effective at cleaning the mask before contour detection.
    final kernelSize = 5; // Kernel size (5, 5) as recommended for noise removal
    final cv.Mat kernel = cv.getStructuringElement(cv.MORPH_ELLIPSE, (
      kernelSize,
      kernelSize,
    ));
    matsToDispose.add(kernel);

    // Apply opening to remove noise
    final cv.Mat processedMask = cv.morphologyEx(
      combinedMask,
      cv.MORPH_OPEN,
      kernel,
      iterations: 1,
    );
    matsToDispose.add(processedMask);

    // --- STAGE 4: Contour Detection ---

    // 8. Find Contours
    // This finds the outlines of all "blobs" in our processed binary mask.
    // cv.RETR_EXTERNAL: Only finds the outermost contours (ignores holes).
    // cv.CHAIN_APPROX_SIMPLE: Compresses contours to save memory.
    final contoursOutput = cv.findContours(
      processedMask,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );
    final cv.Contours contours = contoursOutput.$1;
    // Note: hierarchy is VecVec4i, not Mat, so we don't need to dispose it separately

    logDebug("[processImage] Found ${contours.length} contours");

    // --- STAGE 5: Contour Filtering & Ellipse Fitting ---

    // 9. Iterate, Filter, and Fit
    // CRITICAL: We do NOT dispose individual contours to avoid double-free crashes.
    // The container (contours) will be disposed in the finally block.
    int contoursFilteredByArea = 0;
    int contoursFilteredByHue = 0;
    int contoursFilteredByPoints = 0;
    int contoursFilteredByCircularity = 0;
    int contoursFilteredBySolidity = 0;
    int contoursFilteredByAspectRatio = 0;
    int contoursWithErrors = 0;
    try {
      for (var i = 0; i < contours.length; i++) {
        final cv.Contour contour = contours[i];
        try {
          // 9a. Filter by Area
          // This is the most important filter to remove noise.
          // Tune these min/max values based on test images.
          final double area = cv.contourArea(contour);

          // Enable area filter with permissive values to handle spread-out heads:
          // - Very low minimum (10.0) allows distant bowls that appear small
          //   (Relaxed from 20.0 for production bug fix: "Pro Mode no results")
          // - High maximum (50000.0) allows close bowls and handles perspective
          // This enables detection of 8+ bowls at various distances
          if (area < 10.0 || area > detectionConfig.maxContourArea) {
            contoursFilteredByArea++;
            logDebug(
              "[processImage] Rejecting contour: area ${area.toStringAsFixed(1)} "
              "outside range [10.0, ${detectionConfig.maxContourArea}]",
            );
            continue;
          }

          // 9b. CRITICAL: Check for minimum points before fitting ellipse
          // cv.fitEllipse requires at least 6 points to compute.
          // Calling it with 5 or fewer points will cause a native C++ crash.
          final int pointCount = contour.length;
          if (pointCount <= 5) {
            contoursFilteredByPoints++;
            continue;
          }

          // 9c. Fit an Ellipse (needed for precise mask-based Hue calculation)
          // This is the core logic: fit an ellipse to the contour.
          // This returns a RotatedRect, which IS the ellipse.
          // We fit it early so we can use it for the precise Hue filter.
          cv.RotatedRect? ellipse; // Store for later use in results
          try {
            ellipse = cv.fitEllipse(contour);
          } catch (e) {
            // If ellipse fitting fails, skip this contour
            contoursWithErrors++;
            logDebug("[processImage] Error fitting ellipse: $e, skipping");
            continue;
          }

          // 9d. Filter by Hue (reject green/yellow background artifacts)
          // Use precise ellipseMask method (same as classifier) for accurate Hue calculation
          // This ensures the filter and classifier use identical mean calculation methods
          double meanH = 0.0; // Default Hue if calculation fails
          cv.Mat? ellipseMask; // Make it nullable to handle disposal in catch

          try {
            // Create a precise ellipse mask using the actual RotatedRect from cv.fitEllipse
            // This ensures we only sample pixels within the true ellipse, excluding background
            ellipseMask =
                cv.Mat.zeros(hsvImage.rows, hsvImage.cols, cv.MatType.CV_8UC1);

            // Draw the precise ellipse using the RotatedRect components
            // cv.ellipse requires 7 positional arguments: img, center, axes, angle, startAngle, endAngle, color
            // thickness is a named parameter
            // Note: axes parameter uses Point where x and y represent the ellipse radii (half-axes)
            final center =
                cv.Point(ellipse!.center.x.toInt(), ellipse.center.y.toInt());
            // RotatedRect.size is full width/height, so divide by 2 for semi-axes
            final axes = cv.Point((ellipse.size.width / 2).toInt(),
                (ellipse.size.height / 2).toInt());
            final color = cv.Scalar.all(255);
            cv.ellipse(ellipseMask, center, axes, ellipse.angle, 0, 360, color,
                thickness: cv.FILLED);

            // Calculate mean using the precise mask
            final meanScalar = cv.mean(hsvImage, mask: ellipseMask);
            meanH = meanScalar.val[0];

            // Clean up the color Scalar
            color.dispose();

            // Debug: Log the calculated meanH for analysis
            logDebug(
              "[processImage] Calculated meanH: ${meanH.toStringAsFixed(2)} "
              "for contour with area: ${area.toStringAsFixed(1)}",
            );

            // Clean up the mask immediately after use
            ellipseMask.dispose();
            ellipseMask = null;
          } catch (e) {
            // If mask creation or mean calculation fails (e.g., for a malformed contour):
            // 1. Log the error
            logDebug(
              "[processImage] Error calculating Hue for contour: $e, skipping",
            );
            // 2. Clean up the mask if it was created
            if (ellipseMask != null) {
              try {
                ellipseMask.dispose();
              } catch (_) {
                // Ignore disposal errors
              }
              ellipseMask = null;
            }
            // 3. Skip this contour and move to the next one
            continue;
          }

          // 9d.5. Filter by Hue (reject green/yellow background artifacts)
          // Filter out contours with Hue in the green/yellow background range (30-42)
          // This range corresponds to the green/yellow background color that causes false positives
          // With precise ellipse masks, this filter now correctly blocks background noise
          // while allowing real bowls (Red: H=0-20, Blue: H=90-150) to pass through
          // DISABLED FOR DATA GATHERING:
          // if (meanH >= 30 && meanH <= 42) {
          //   contoursFilteredByHue++;
          //   debugPrint(
          //     "[processImage] Rejecting contour: mean Hue ${meanH.toStringAsFixed(2)} "
          //     "in background range [30, 42] (area: ${area.toStringAsFixed(1)})",
          //   );
          //   continue;
          // }

          // 9e. Filter by Circularity - Phase III: Geometric Validation
          // Bowls are oblate spheroids that appear as ellipses, not perfect circles.
          // Calculate circularity to filter out non-circular shapes like background patches,
          // shadows, or elongated artifacts.
          // Circularity = 4 * π * area / (perimeter^2)
          // A perfect circle has circularity = 1.0. Phase III implementation: Filter out
          // jagged/irregular shapes with circularity < 0.7 as per technical audit.
          final double perimeter = cv.arcLength(contour, true);
          double circularity = 0.0;
          if (perimeter > 0) {
            circularity = (4 * math.pi * area) / (perimeter * perimeter);
          }

          // Phase III: Reject contours that are not circular enough
          // Threshold of 0.7 filters out irregular contours (grass fragments, jagged noise)
          // while allowing elliptical bowls which typically have circularity > 0.7
          if (circularity < 0.7) {
            contoursFilteredByCircularity++;
            logDebug(
              "[processImage] Rejecting contour: circularity ${circularity.toStringAsFixed(3)} "
              "below threshold 0.7 (area: ${area.toStringAsFixed(1)}, perimeter: ${perimeter.toStringAsFixed(1)})",
            );
            continue;
          }

          // 9e.2. Filter by Solidity - Phase III: Geometric Validation
          // Solidity measures the density of the contour, defined as the ratio of the contour
          // area to the area of its Convex Hull. A perfectly solid, convex shape (like an intact bowl)
          // yields a Solidity value of 1.0. Complex noise clusters, fragmented shapes, or partially
          // occluded features tend to be non-convex or have significant irregularities (concavities)
          // that lead to a Solidity value far less than 1.0.
          // Phase III implementation: Filter out non-convex, fragmented shapes with solidity < 0.9
          // as per technical audit. This provides a crucial secondary defense against merged or
          // complex noise structures that might pass the circularity check.
          cv.Mat convexHullMat;
          try {
            convexHullMat = cv.convexHull(contour);
          } catch (e) {
            // If convex hull calculation fails, skip this contour
            contoursWithErrors++;
            logDebug(
                "[processImage] Error calculating convex hull: $e, skipping");
            continue;
          }

          // Convert Mat to Contour for contourArea calculation
          // convexHull returns a Mat containing the convex hull points
          // We need to extract these points and create a Contour
          final cv.Contour convexHull = cv.Contour.fromMat(convexHullMat);
          final double convexHullArea = cv.contourArea(convexHull);
          double solidity = 0.0;
          if (convexHullArea > 0) {
            solidity = area / convexHullArea;
          }

          // Clean up the Mat
          convexHullMat.dispose();

          // Phase III: Reject contours that are not solid enough
          // Threshold of 0.9 filters out fragmented, concave, or complex merged noise shapes
          // while allowing intact bowls which are convex and have solidity close to 1.0
          if (solidity < 0.9) {
            contoursFilteredBySolidity++;
            logDebug(
              "[processImage] Rejecting contour: solidity ${solidity.toStringAsFixed(3)} "
              "below threshold 0.9 (area: ${area.toStringAsFixed(1)}, "
              "convexHullArea: ${convexHullArea.toStringAsFixed(1)})",
            );
            continue;
          }

          // 9e.5. Filter by Aspect Ratio - Phase III: Geometric Validation
          // Calculate aspect ratio from the fitted ellipse
          // Aspect ratio = majorAxis / minorAxis (height / width from RotatedRect)
          // For spherical objects viewed from a relatively perpendicular angle, the aspect ratio
          // should be near 1.0. Phase III implementation: Filter out elongated shapes with
          // aspect ratio < 0.85 or > 1.15 as per technical audit. This effectively eliminates
          // detections arising from elongated noise (e.g., specific shadow structures) or objects
          // heavily distorted by extreme perspective.
          final double aspectRatio = ellipse!.size.height / ellipse.size.width;
          const double minAspectRatio = 0.85;
          const double maxAspectRatio = 1.15;
          if (aspectRatio < minAspectRatio || aspectRatio > maxAspectRatio) {
            contoursFilteredByAspectRatio++;
            logDebug(
              "[processImage] Rejecting contour: aspect ratio ${aspectRatio.toStringAsFixed(3)} "
              "outside range [$minAspectRatio, $maxAspectRatio] (area: ${area.toStringAsFixed(1)})",
            );
            continue;
          }

          // 9f. Add to Results
          // Use the ellipse that was already fitted for the Hue filter
          // Extract the properties from the RotatedRect.
          // The 'size' field contains (width, height) which corresponds to (minor, major)
          // Note: ellipse is guaranteed to be non-null here because we would have continued
          // if ellipse fitting failed earlier
          results.add(
            DetectedObject(
              centerX: ellipse!.center.x,
              centerY: ellipse.center.y,
              // 'size' is (width, height) which corresponds to (minor, major)
              minorAxis: ellipse.size.width,
              majorAxis: ellipse.size.height,
              angle: ellipse.angle,
              area: area,
            ),
          );

          // NOTE: Do NOT dispose individual contours - they are managed by the container.
          // Disposing them here causes double-free crashes when the container is disposed.
        } catch (e) {
          // Skip this contour if there's an error (e.g., fitEllipse fails)
          contoursWithErrors++;
          logDebug("Error processing contour: $e");
          // NOTE: Do NOT dispose individual contours - they are managed by the container.
          // Disposing them here causes double-free crashes when the container is disposed.
          continue;
        }
      }

      logDebug(
        "[processImage] Contour filtering: ${contours.length} total, "
        "$contoursFilteredByArea filtered by area, "
        "$contoursFilteredByHue filtered by Hue (30-42), "
        "$contoursFilteredByCircularity filtered by circularity (< 0.7), "
        "$contoursFilteredBySolidity filtered by solidity (< 0.9), "
        "$contoursFilteredByAspectRatio filtered by aspect ratio (0.85-1.15), "
        "$contoursFilteredByPoints filtered by points, "
        "$contoursWithErrors errors, "
        "${results.length} objects detected",
      );
    } finally {
      // Clean up the top-level contours container
      // CRITICAL: Always dispose the container. Individual contours are managed by the container.
      // This prevents double-free crashes that occur when disposing both individual contours and the container.
      try {
        if (contours.isNotEmpty) {
          contours.dispose();
        }
      } catch (e) {
        logDebug("Warning: Error disposing contours container: $e");
      }
    }

    // Return the final list of detected objects.
    return results;
  } catch (e) {
    // Handle any errors (e.g., image decode failure)
    logDebug("Error in processImage: $e");
    return []; // Return an empty list on failure
  } finally {
    // --- CRITICAL MEMORY CLEANUP ---
    // This block *always* runs, even if an error is thrown.
    // This guarantees we do not leak native C++ memory.
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
        logDebug("Warning: Error disposing Mat in processImage: $e");
      }
    }
  }
}
