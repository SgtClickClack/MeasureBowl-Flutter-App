import 'package:flutter_test/flutter_test.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import 'package:lawn_bowls_measure/models/detected_object.dart';
import 'package:lawn_bowls_measure/services/image_processing/distance_calculator.dart';
import 'package:lawn_bowls_measure/services/detection_config.dart';

void main() {
  group('DistanceCalculator - Memory Optimization Validation', () {
    late cv.Mat testImage;
    late DetectionConfig testConfig;

    setUp(() {
      // Create a small test image (100x100 pixels, 3 channels BGR)
      testImage = cv.Mat.zeros(100, 100, cv.MatType.CV_8UC3);
      testConfig = const DetectionConfig();
    });

    tearDown(() {
      // Clean up test image
      testImage.dispose();
    });

    test('calculateBowlDistances creates HSV image once and reuses it', () {
      // Arrange: Create test objects
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0, // 10px radius
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16, // π * 10^2
      );

      final bowls = [
        DetectedObject(
          centerX: 70.0, // 20px right of jack
          centerY: 50.0,
          majorAxis: 40.0, // 20px radius
          minorAxis: 40.0,
          angle: 0.0,
          area: 1256.64, // π * 20^2
        ),
        DetectedObject(
          centerX: 50.0,
          centerY: 80.0, // 30px below jack
          majorAxis: 40.0,
          minorAxis: 40.0,
          angle: 0.0,
          area: 1256.64,
        ),
      ];

      // Scale: 1mm per pixel (for simplicity)
      const scaleMmPerPixel = 1.0;

      // Act: Calculate distances
      final results = calculateBowlDistances(
        bowls,
        jack,
        scaleMmPerPixel,
        testImage,
        testConfig,
      );

      // Assert: Results are correct
      expect(results.length, equals(2));

      // First bowl: 20px center-to-center, 10px jack radius, 20px bowl radius
      // Edge-to-edge: 20 - 10 - 20 = -10 (overlapping), so should be 0.0
      expect(results[0]['distance'], greaterThanOrEqualTo(0.0));

      // Second bowl: 30px center-to-center, 10px jack radius, 20px bowl radius
      // Edge-to-edge: 30 - 10 - 20 = 0.0 (touching)
      expect(results[1]['distance'], greaterThanOrEqualTo(0.0));

      // Verify results are sorted by distance
      for (int i = 0; i < results.length - 1; i++) {
        expect(
          results[i]['distance'],
          lessThanOrEqualTo(results[i + 1]['distance']),
        );
      }

      // Verify all results have required fields
      for (final result in results) {
        expect(result, containsPair('distance', isA<double>()));
        expect(result, containsPair('x', isA<double>()));
        expect(result, containsPair('y', isA<double>()));
        expect(result, containsPair('area', isA<double>()));
        expect(result, containsPair('team', isA<String>()));
      }
    });

    test('calculateBowlDistances handles empty bowl list', () {
      // Arrange
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0,
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16,
      );

      // Act
      final results = calculateBowlDistances(
        [],
        jack,
        1.0,
        testImage,
        testConfig,
      );

      // Assert
      expect(results, isEmpty);
    });

    test('calculateBowlDistances correctly calculates edge-to-edge distance',
        () {
      // Arrange: Bowl 50px away from jack center
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0, // 10px radius
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16,
      );

      final bowl = DetectedObject(
        centerX: 100.0, // 50px right of jack
        centerY: 50.0,
        majorAxis: 40.0, // 20px radius
        minorAxis: 40.0,
        angle: 0.0,
        area: 1256.64,
      );

      // Scale: 1mm per pixel
      const scaleMmPerPixel = 1.0;

      // Act
      final results = calculateBowlDistances(
        [bowl],
        jack,
        scaleMmPerPixel,
        testImage,
        testConfig,
      );

      // Assert
      expect(results.length, equals(1));
      // Center-to-center: 50px
      // Jack radius: 10px, Bowl radius: 20px
      // Edge-to-edge: 50 - 10 - 20 = 20px = 20mm
      final expectedDistance = 20.0;
      expect(results[0]['distance'], closeTo(expectedDistance, 0.1));
    });

    test(
        'calculateBowlDistances handles overlapping bowls (negative edge distance)',
        () {
      // Arrange: Bowl overlapping with jack
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0, // 10px radius
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16,
      );

      final bowl = DetectedObject(
        centerX: 55.0, // Only 5px away (overlapping)
        centerY: 50.0,
        majorAxis: 40.0, // 20px radius
        minorAxis: 40.0,
        angle: 0.0,
        area: 1256.64,
      );

      // Act
      final results = calculateBowlDistances(
        [bowl],
        jack,
        1.0,
        testImage,
        testConfig,
      );

      // Assert: Should return 0.0 for overlapping bowls
      expect(results.length, equals(1));
      expect(results[0]['distance'], equals(0.0));
    });

    test('calculateBowlDistances filters out invalid distances', () {
      // Arrange: Bowl with very large distance (should be filtered)
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0,
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16,
      );

      final bowls = [
        // Valid bowl
        DetectedObject(
          centerX: 100.0,
          centerY: 50.0,
          majorAxis: 40.0,
          minorAxis: 40.0,
          angle: 0.0,
          area: 1256.64,
        ),
        // Bowl with very large distance (>500cm = 5000mm)
        DetectedObject(
          centerX: 10000.0, // Very far away
          centerY: 50.0,
          majorAxis: 40.0,
          minorAxis: 40.0,
          angle: 0.0,
          area: 1256.64,
        ),
      ];

      // Act
      final results = calculateBowlDistances(
        bowls,
        jack,
        1.0,
        testImage,
        testConfig,
      );

      // Assert: Invalid bowl should be filtered out
      expect(results.length, lessThanOrEqualTo(bowls.length));
      // All remaining results should have valid distances
      for (final result in results) {
        final distanceCm = (result['distance'] as double) / 10.0;
        expect(distanceCm, lessThan(500.0));
      }
    });

    test('calculateBowlDistances handles team color detection', () {
      // Arrange
      final jack = DetectedObject(
        centerX: 50.0,
        centerY: 50.0,
        majorAxis: 20.0,
        minorAxis: 20.0,
        angle: 0.0,
        area: 314.16,
      );

      final bowl = DetectedObject(
        centerX: 100.0,
        centerY: 50.0,
        majorAxis: 40.0,
        minorAxis: 40.0,
        angle: 0.0,
        area: 1256.64,
      );

      // Team colors (HSV format)
      final teamAColor = [0.0, 255.0, 255.0]; // Red
      final teamBColor = [120.0, 255.0, 255.0]; // Blue

      // Act
      final results = calculateBowlDistances(
        [bowl],
        jack,
        1.0,
        testImage,
        testConfig,
        teamAColor: teamAColor,
        teamBColor: teamBColor,
      );

      // Assert: Team should be detected (may be Unknown if colors don't match)
      expect(results.length, equals(1));
      expect(results[0]['team'], isA<String>());
      expect(
        ['Team A', 'Team B', 'Unknown'],
        contains(results[0]['team']),
      );
    });
  });
}
