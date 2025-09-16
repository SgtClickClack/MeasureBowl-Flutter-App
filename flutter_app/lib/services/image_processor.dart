import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:opencv_dart/opencv.dart' as cv;
import '../models/measurement_result.dart';

/// Service class for processing images using OpenCV to detect jack and calculate measurements
class ImageProcessor {
  // Standard jack diameter in millimeters (World Bowls regulation size)
  static const double _jackDiameterMm = 63.5;

  /// Process captured image to detect jack and calculate measurement scale
  /// 
  /// Returns a Map containing:
  /// - 'success': bool indicating if processing succeeded
  /// - 'scale': double scale factor (mm per pixel)
  /// - 'jack_center': Map with 'x' and 'y' coordinates of jack center
  /// - 'jack_radius': double radius of detected jack in pixels
  /// - 'error': String error message if processing failed
  static Future<Map<String, dynamic>> processImage(String imagePath) async {
    try {
      // Verify OpenCV native library is available
      try {
        // Test basic OpenCV functionality to ensure native libraries are loaded
        final testMat = cv.Mat.zeros(10, 10, cv.MatType.CV_8UC1);
        testMat.dispose(); // Clean up test matrix
      } catch (e) {
        return {
          'success': false,
          'error': 'OpenCV native library not available: ${e.toString()}. Please ensure opencv_dart is properly configured for your platform.'
        };
      }

      // Load the image from file
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        return {
          'success': false,
          'error': 'Image file not found: $imagePath'
        };
      }

      // Read image bytes and load into OpenCV Mat
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final cv.Mat originalImage = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      
      if (originalImage.isEmpty) {
        return {
          'success': false,
          'error': 'Failed to decode image. Please ensure the image file is a valid format (JPG, PNG, etc.)'
        };
      }

      // Step 1: Convert to grayscale for better processing
      final cv.Mat grayImage = cv.cvtColor(originalImage, cv.COLOR_BGR2GRAY);

      // Step 2: Apply Gaussian blur to reduce noise and improve detection
      final cv.Mat blurredImage = cv.gaussianBlur(
        grayImage, 
        (9, 9),  // Kernel size
        2.0,     // Sigma X
        sigmaY: 2.0,     // Sigma Y
      );

      // Step 3: Use Hough Circle Transform to detect circles (jack and bowls)
      final cv.Mat circles = cv.HoughCircles(
        blurredImage,
        cv.HOUGH_GRADIENT,
        1.0,        // Accumulator resolution (inverse ratio)
        30.0,       // Minimum distance between circle centers
        param1: 50.0, // Higher threshold for edge detection
        param2: 30.0, // Accumulator threshold for center detection
        minRadius: 10,  // Minimum circle radius in pixels
        maxRadius: 100, // Maximum circle radius in pixels
      );

      // Step 4: Process detected circles to find the jack
      final Map<String, dynamic> jackData = _findJack(circles);
      
      if (!jackData['found']) {
        // Clean up memory
        originalImage.dispose();
        grayImage.dispose();
        blurredImage.dispose();
        circles.dispose();
        
        return {
          'success': false,
          'error': 'No jack detected in image. Please ensure the jack is clearly visible and well-lit.'
        };
      }

      // Step 5: Calculate scale using jack diameter
      final double jackRadiusPixels = jackData['radius'];
      final double jackDiameterPixels = jackRadiusPixels * 2;
      final double scaleMmPerPixel = _jackDiameterMm / jackDiameterPixels;

      // Step 6: Detect bowls using contour analysis
      final List<Map<String, dynamic>> bowlResults = _detectBowls(
        grayImage, 
        jackData['x'], 
        jackData['y'], 
        jackRadiusPixels, 
        scaleMmPerPixel
      );

      // Clean up OpenCV Mat objects
      originalImage.dispose();
      grayImage.dispose();
      blurredImage.dispose();
      circles.dispose();

      // Return successful processing results
      return {
        'success': true,
        'scale': scaleMmPerPixel,
        'jack_center': {
          'x': jackData['x'],
          'y': jackData['y']
        },
        'jack_radius': jackRadiusPixels,
        'image_path': imagePath,
        'bowls': bowlResults,
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'OpenCV processing failed: ${e.toString()}'
      };
    }
  }

  /// Detect bowls using contour analysis
  /// 
  /// Returns a List of bowl data containing:
  /// - distance: edge-to-edge distance from jack in millimeters
  /// - x, y: center position of bowl
  /// - area: contour area in pixels
  static List<Map<String, dynamic>> _detectBowls(
    cv.Mat grayImage, 
    double jackCenterX, 
    double jackCenterY, 
    double jackRadiusPixels, 
    double scaleMmPerPixel
  ) {
    final List<Map<String, dynamic>> bowlResults = [];
    
    try {
      // Step 1: Apply adaptive threshold for clean binary image
      final cv.Mat thresholdImage = cv.adaptiveThreshold(
        grayImage,
        255,  // Max value
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,  // Adaptive method
        cv.THRESH_BINARY,  // Threshold type
        11,   // Block size for threshold calculation
        2,    // Constant subtracted from mean
      );

      // Step 2: Find contours
      final (contours, hierarchy) = cv.findContours(
        thresholdImage,
        cv.RETR_EXTERNAL,  // Retrieve only external contours
        cv.CHAIN_APPROX_SIMPLE,  // Compress horizontal, vertical segments
      );

      // Step 3: Filter and process contours to identify bowls
      for (int i = 0; i < contours.length; i++) {
        final contour = contours[i];
        
        // Calculate contour area
        final double contourArea = cv.contourArea(contour);
        
        // Filter by area - bowls should be larger than jack but not too large
        final double minBowlArea = (jackRadiusPixels * jackRadiusPixels * 3.14) * 1.5; // 1.5x jack area
        final double maxBowlArea = (jackRadiusPixels * jackRadiusPixels * 3.14) * 8.0;  // 8x jack area
        
        if (contourArea < minBowlArea || contourArea > maxBowlArea) {
          continue; // Skip contours that are too small or too large
        }

        // Check if contour is reasonably circular using circularity ratio
        final double perimeter = cv.arcLength(contour, true);
        final double circularity = 4 * 3.14159 * contourArea / (perimeter * perimeter);
        
        // Filter by circularity - bowls should be reasonably round (0.3 to 1.0)
        if (circularity < 0.3) {
          continue; // Skip non-circular shapes
        }

        // Step 4: Find center of contour using moments
        final moments = cv.moments(contour);
        if (moments.m00 == 0) continue; // Skip if moments calculation failed
        
        final double bowlCenterX = moments.m10 / moments.m00;
        final double bowlCenterY = moments.m01 / moments.m00;

        // Step 5: Find closest point on contour to jack center
        double minDistanceToJack = double.infinity;
        
        // Contour points are stored as a list of cv.Point objects
        for (int j = 0; j < contour.length; j++) {
          final point = contour[j];  // Access point directly from list
          final double dx = point.x.toDouble() - jackCenterX;
          final double dy = point.y.toDouble() - jackCenterY;
          final double distanceToJack = sqrt(dx * dx + dy * dy);
          
          if (distanceToJack < minDistanceToJack) {
            minDistanceToJack = distanceToJack;
          }
        }

        // Step 6: Calculate edge-to-edge distance
        final double edgeToEdgePixels = minDistanceToJack - jackRadiusPixels;
        
        // Skip if bowl is too close to or overlapping with jack
        if (edgeToEdgePixels <= 0) {
          continue;
        }

        // Step 7: Convert to millimeters
        final double edgeToEdgeMm = edgeToEdgePixels * scaleMmPerPixel;

        // Add bowl result
        bowlResults.add({
          'distance': edgeToEdgeMm,
          'x': bowlCenterX,
          'y': bowlCenterY,
          'area': contourArea,
          'circularity': circularity,
        });
      }

      // Clean up threshold image and hierarchy  
      thresholdImage.dispose();
      hierarchy.dispose();
      
      // Note: contours is a list of points, not Mat objects, so no need to dispose individual contours

    } catch (e) {
      // If contour analysis fails, return empty list
      print('Error in bowl detection: $e');
    }

    // Step 8: Sort bowls by distance (closest first) and limit to reasonable number
    bowlResults.sort((a, b) => a['distance'].compareTo(b['distance']));
    
    // Return up to 8 bowls (reasonable maximum for a game)
    return bowlResults.take(8).toList();
  }

  /// Find the jack among detected circles using heuristics
  /// 
  /// The jack is typically:
  /// - Smaller than bowls
  /// - More circular/uniform
  /// - Often positioned centrally or prominently
  static Map<String, dynamic> _findJack(cv.Mat circles) {
    if (circles.rows == 0) {
      return {'found': false};
    }

    // Get all detected circles
    final List<Map<String, dynamic>> detectedCircles = [];
    
    // HoughCircles returns Mat with shape (1, N, 3) where N is number of circles
    // Each circle has [x, y, radius] at channels 0, 1, 2
    final int numCircles = circles.cols;
    
    for (int i = 0; i < numCircles; i++) {
      // Extract circle parameters using opencv_dart API format
      final double x = circles.at<double>(0, i, 0);      // x coordinate
      final double y = circles.at<double>(0, i, 1);      // y coordinate  
      final double radius = circles.at<double>(0, i, 2); // radius
      
      detectedCircles.add({
        'x': x,
        'y': y,
        'radius': radius,
      });
    }

    if (detectedCircles.isEmpty) {
      return {'found': false};
    }

    // Sort circles by radius (jack should be smaller than bowls)
    detectedCircles.sort((a, b) => a['radius'].compareTo(b['radius']));

    // For now, select the smallest circle as the jack
    // This can be enhanced with more sophisticated heuristics later
    final jack = detectedCircles.first;
    
    return {
      'found': true,
      'x': jack['x'],
      'y': jack['y'],
      'radius': jack['radius'],
    };
  }

  /// Create a MeasurementResult with real OpenCV detection data
  /// Uses real jack detection and bowl contour analysis results
  static MeasurementResult createMeasurementResult(
    Map<String, dynamic> processingResult
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
    final Map<String, dynamic> jackCenter = processingResult['jack_center'];
    final List<Map<String, dynamic>> bowlDetections = processingResult['bowls'] ?? [];

    // Convert detected bowls to BowlMeasurement objects
    final List<BowlMeasurement> realBowls = [];
    
    for (int i = 0; i < bowlDetections.length; i++) {
      final bowlData = bowlDetections[i];
      final double distanceMm = bowlData['distance'];
      
      // Assign colors based on detection order (could be enhanced with color analysis)
      final List<String> bowlColors = ['Red', 'Blue', 'Green', 'Yellow', 'Black', 'White', 'Orange', 'Purple'];
      final String bowlColor = i < bowlColors.length ? bowlColors[i] : 'Bowl ${i + 1}';
      
      realBowls.add(BowlMeasurement(
        id: 'detected_bowl_${i + 1}',
        color: bowlColor,
        distanceFromJack: distanceMm / 10.0, // Convert mm to cm
        rank: i + 1, // Already sorted by distance in _detectBowls
      ));
    }

    // If no bowls detected, add a message bowl
    if (realBowls.isEmpty) {
      realBowls.add(BowlMeasurement(
        id: 'no_bowls',
        color: 'No Bowls',
        distanceFromJack: 0.0,
        rank: 1,
      ));
    }

    return MeasurementResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      bowls: realBowls,
      imagePath: imagePath,
    );
  }
}