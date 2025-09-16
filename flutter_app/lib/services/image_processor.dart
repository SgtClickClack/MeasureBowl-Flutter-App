import 'dart:io';
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
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'OpenCV processing failed: ${e.toString()}'
      };
    }
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
    
    // HoughCircles returns data in format [x, y, radius] for each circle
    // The cols value represents number of circles * 3 (x, y, r values)
    final int numCircles = circles.cols ~/ 3;
    
    for (int i = 0; i < numCircles; i++) {
      // Extract circle parameters (x, y, radius)
      // Each circle has 3 values: x, y, radius
      final double x = circles.at<double>(0, i * 3);
      final double y = circles.at<double>(0, i * 3 + 1);
      final double radius = circles.at<double>(0, i * 3 + 2);
      
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

  /// Create a MeasurementResult with real jack data and mock bowl data
  /// This bridges the gap until full bowl detection is implemented
  static MeasurementResult createMeasurementResult(
    Map<String, dynamic> processingResult
  ) {
    if (!processingResult['success']) {
      // Return error result with mock data
      return MeasurementResult.withCapturedImage('');
    }

    final String imagePath = processingResult['image_path'];
    final double scale = processingResult['scale'];
    final Map<String, dynamic> jackCenter = processingResult['jack_center'];

    // Create mock bowls with realistic distances using the real scale
    final List<BowlMeasurement> mockBowls = [
      BowlMeasurement(
        id: '1',
        color: 'Red',
        distanceFromJack: (45 * scale), // 45 pixels from jack
        rank: 1,
      ),
      BowlMeasurement(
        id: '2', 
        color: 'Blue',
        distanceFromJack: (67 * scale), // 67 pixels from jack
        rank: 2,
      ),
      BowlMeasurement(
        id: '3',
        color: 'Green', 
        distanceFromJack: (89 * scale), // 89 pixels from jack
        rank: 3,
      ),
    ];

    return MeasurementResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      jackPosition: [jackCenter['x'], jackCenter['y']],
      bowls: mockBowls,
      imagePath: imagePath,
    );
  }
}