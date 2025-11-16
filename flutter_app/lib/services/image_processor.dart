import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/measurement_result.dart';
import '../models/detected_object.dart';
import 'detection_config_service.dart';
import 'team_color_service.dart';
import 'image_processing/image_processing_isolate.dart';

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

/// Helper function to convert team string to BowlTeam enum
BowlTeam _stringToBowlTeam(String teamString) {
  switch (teamString.toLowerCase()) {
    case 'team a':
      return BowlTeam.teamA;
    case 'team b':
      return BowlTeam.teamB;
    default:
      return BowlTeam.unknown;
  }
}

/// Service class for processing images using OpenCV to detect jack and calculate measurements
class ImageProcessor {
  /// Process captured image to detect jack and calculate measurement scale
  ///
  /// Returns a Map containing:
  /// - 'success': bool indicating if processing succeeded
  /// - 'scale': double scale factor (mm per pixel)
  /// - 'jack_center': Map with 'x' and 'y' coordinates of jack center
  /// - 'jack_radius': double radius of detected jack in pixels
  /// - 'error': String error message if processing failed
  static Future<Map<String, dynamic>> processImage(String imagePath) async {
    debugPrint("======================================================");
    debugPrint(
      "[ImageProcessor] Starting new process (Version 19 - Optimized Color & Jack Filter)...",
    );
    debugPrint("[ImageProcessor] Image path: $imagePath");
    debugPrint("======================================================");

    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      return {'success': false, 'error': 'Image file not found: $imagePath'};
    }

    final Uint8List imageBytes = await imageFile.readAsBytes();
    return await processImageBytes(imageBytes, imagePath);
  }

  /// Process image from bytes (internal method)
  /// This method now uses compute() to run processing in a background isolate
  ///
  /// [proAccuracyMode] enables high-accuracy processing when true.
  /// [manualJackPosition] is the manually selected jack position from user tap.
  /// [jackDiameterMm] is the jack diameter in millimeters for measurement calculations.
  static Future<Map<String, dynamic>> processImageBytes(
    Uint8List imageBytes,
    String imagePath, {
    bool proAccuracyMode = false,
    Offset? manualJackPosition,
    double jackDiameterMm = 63.5,
  }) async {
    debugPrint(
      "[ImageProcessor] MainThread: Calling 'compute' to run processing in background isolate...",
    );

    // Load detection config in main isolate (SharedPreferences works here)
    final detectionConfig = await DetectionConfigService.loadConfig();
    final hasCustomConfig = await DetectionConfigService.hasCustomConfig();
    debugPrint(
      "[ImageProcessor] MainThread: Loaded ${hasCustomConfig ? 'custom' : 'default'} detection config",
    );

    // Load team colors in main isolate (SharedPreferences works here)
    final teamAColor = await TeamColorService.getTeamAColor();
    final teamBColor = await TeamColorService.getTeamBColor();
    debugPrint(
      "[ImageProcessor] MainThread: Team A color: ${teamAColor != null ? 'calibrated' : 'not calibrated'}, "
      "Team B color: ${teamBColor != null ? 'calibrated' : 'not calibrated'}",
    );

    // Serialize config to pass through isolate boundary
    final configMap = {
      'whiteLowerHsv': detectionConfig.whiteLowerHsv,
      'whiteUpperHsv': detectionConfig.whiteUpperHsv,
      'blurKernelSize': detectionConfig.blurKernelSize,
      'minContourArea': detectionConfig.minContourArea,
      'maxContourArea': detectionConfig.maxContourArea,
      'maxAspectRatioForJack': detectionConfig.maxAspectRatioForJack,
    };

    // Use compute() to run the processing in a background isolate
    // This prevents blocking the main UI thread during CPU-intensive OpenCV operations
    return await compute(processImageInBackground, {
      'imageBytes': imageBytes,
      'imagePath': imagePath,
      'detectionConfig': configMap,
      'teamAColor': teamAColor,
      'teamBColor': teamBColor,
      'proAccuracyMode': proAccuracyMode,
      'manualJackPosition': manualJackPosition != null
          ? [manualJackPosition.dx, manualJackPosition.dy]
          : null,
      'jackDiameterMm': jackDiameterMm,
    });
  }

  /// Create a MeasurementResult with real OpenCV detection data
  /// Uses real jack detection and bowl contour analysis results
  static MeasurementResult createMeasurementResult(
    Map<String, dynamic> processingResult,
  ) {
    if (!processingResult['success']) {
      // Return error result with empty bowls list
      return MeasurementResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        bowls: [],
        imagePath: '',
      );
    }

    final String imagePath = processingResult['image_path'];
    final List<Map<String, dynamic>> bowlDetections =
        processingResult['bowls'] ?? [];
    // Read Pro Accuracy flag from processing results
    final bool usingHighAccuracy =
        processingResult['using_high_accuracy'] ?? false;
    final String? accuracyMessage = processingResult['accuracy_message'];
    // Read original image dimensions for coordinate scaling
    final int? originalImageWidth = processingResult['original_width'] as int?;
    final int? originalImageHeight =
        processingResult['original_height'] as int?;

    // Convert detected bowls to BowlMeasurement objects
    final List<BowlMeasurement> realBowls = [];

    for (int i = 0; i < bowlDetections.length; i++) {
      final bowlData = bowlDetections[i];
      final double distanceMm =
          double.tryParse(bowlData['distance'].toString()) ?? 0.0;

      // Use detected team from team detection, fallback to "Unknown"
      final String bowlTeam = bowlData['team'] ?? 'Unknown';
      final BowlTeam teamEnum = _stringToBowlTeam(bowlTeam);

      realBowls.add(
        BowlMeasurement(
          id: 'detected_bowl_${i + 1}',
          teamName: bowlTeam,
          team: teamEnum,
          distanceFromJack: distanceMm / 10.0, // Convert mm to cm
          rank: i + 1, // Already sorted by distance
          x: (bowlData['x'] as int?) ?? 0,
          y: (bowlData['y'] as int?) ?? 0,
        ),
      );
    }

    // If no bowls detected, add a message bowl
    if (realBowls.isEmpty) {
      realBowls.add(
        const BowlMeasurement(
          id: 'no_bowls',
          teamName: 'No Bowls',
          distanceFromJack: 0.0,
          rank: 1,
          x: 0,
          y: 0,
        ),
      );
    }

    return MeasurementResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      bowls: realBowls,
      imagePath: imagePath,
      usingHighAccuracy: usingHighAccuracy,
      accuracyMessage: accuracyMessage,
      originalImageWidth: originalImageWidth,
      originalImageHeight: originalImageHeight,
    );
  }
}
