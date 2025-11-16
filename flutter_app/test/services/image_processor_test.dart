import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lawn_bowls_measure/services/image_processor.dart';
import 'package:lawn_bowls_measure/services/team_color_service.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';

void main() {
  // Initialize Flutter binding for asset loading and SharedPreferences
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up mock SharedPreferences once before all tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  // Clear SharedPreferences before each test to ensure clean state
  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('ImageProcessor', () {
    test('should return non-zero coordinates for detected bowls', () async {
      // Arrange: Load a static test image file that is known to contain bowls
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Call processImageBytes to get processing results
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
      );

      // Act: Convert processing result to MeasurementResult
      final result = ImageProcessor.createMeasurementResult(processingResult);

      // Assert: Expect processing to succeed and bowls to be detected
      // Note: This test will fail in Red Phase if:
      // 1. OpenCV is not available in test environment (expected in some CI environments)
      // 2. No bowls are detected (processing failed)
      // 3. Coordinates are hardcoded to 0 (the actual Red Phase failure we're testing for)
      expect(processingResult['success'], isTrue,
          reason: 'Image processing should succeed');
      expect(result.bowls.isNotEmpty, isTrue,
          reason: 'At least one bowl should be detected in the test image');

      // Assert: Expect the first bowl's x coordinate to NOT be 0
      // This will fail in Red Phase because coordinates are currently hardcoded to 0
      expect(result.bowls.first.x, isNot(equals(0)),
          reason:
              'Bowl x coordinate should be detected from image processing, not hardcoded to 0');

      // Assert: Expect the first bowl's y coordinate to NOT be 0
      // This will fail in Red Phase because coordinates are currently hardcoded to 0
      expect(result.bowls.first.y, isNot(equals(0)),
          reason:
              'Bowl y coordinate should be detected from image processing, not hardcoded to 0');
    });

    test('should detect team for bowls when team colors are calibrated',
        () async {
      // Arrange: Calibrate team colors
      // Use sample HSV values (H: 0-179, S: 0-255, V: 0-255)
      // Team A: Reddish color (H ~0-10)
      // Team B: Bluish color (H ~100-120)
      await TeamColorService.saveTeamAColor([5.0, 200.0, 200.0]);
      await TeamColorService.saveTeamBColor([110.0, 200.0, 200.0]);

      // Arrange: Load a static test image file that is known to contain bowls
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Call processImageBytes to get processing results
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
      );

      // Act: Convert processing result to MeasurementResult
      final result = ImageProcessor.createMeasurementResult(processingResult);

      // Assert: Expect processing to succeed and bowls to be detected
      expect(processingResult['success'], isTrue,
          reason: 'Image processing should succeed');
      expect(result.bowls.isNotEmpty, isTrue,
          reason: 'At least one bowl should be detected in the test image');

      // Assert: Expect the first bowl's team to NOT be unknown
      // This will fail in Red Phase because team detection doesn't work properly
      // or team colors aren't being used correctly
      expect(result.bowls.first.team, isNot(equals(BowlTeam.unknown)),
          reason:
              'Bowl team should be detected when team colors are calibrated, not default to unknown');
    });

    test(
        'isolate should prioritize manualJackPosition over automatic detection',
        () async {
      // Arrange: Load a static test image file
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Arrange: Define a manual jack position
      final manualJack = const Offset(200, 300);

      // Act: Call processImageBytes with the manualJackPosition
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        manualJackPosition: manualJack,
      );

      // Assert: The results map from the isolate should contain jack_center
      // which matches the manual position (not the auto-detected one)
      expect(processingResult['success'], isTrue,
          reason: 'Image processing should succeed');
      expect(processingResult['jack_center'], isNotNull,
          reason: 'jack_center should be present in results');

      final jackCenter =
          processingResult['jack_center'] as Map<String, dynamic>;
      final jackX = jackCenter['x'] as double;
      final jackY = jackCenter['y'] as double;

      // Assert: The jack center should match the manual position
      // This will fail (Red Phase) because the isolate doesn't use manualJackPosition yet
      expect(jackX, equals(manualJack.dx),
          reason:
              'Jack X coordinate should match manual position, not auto-detected position');
      expect(jackY, equals(manualJack.dy),
          reason:
              'Jack Y coordinate should match manual position, not auto-detected position');
    });

    // Note: Bowl diameter setting has been removed. The app now uses detected bowl radius
    // directly from the image instead of a user-provided diameter setting.

    test(
        'should return a different distance when a different jackDiameterMm is used',
        () async {
      // Arrange: Load a static test image file
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act 1: Call processImageBytes with the default diameter
      final result1 = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        jackDiameterMm: 63.5,
      );

      // Assert: Processing should succeed and bowls should be detected
      expect(result1['success'], isTrue,
          reason: 'Image processing should succeed with default jack diameter');
      expect(result1['bowls'], isNotNull,
          reason: 'Bowls should be detected in the test image');
      final bowls1 = result1['bowls'] as List;
      expect(bowls1.isNotEmpty, isTrue,
          reason: 'At least one bowl should be detected');

      // Act 1: Get the first bowl's distance
      final distanceDefault =
          (bowls1.first as Map<String, dynamic>)['distance'] as double;

      // Act 2: Call processImageBytes again with a different diameter
      final result2 = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        jackDiameterMm: 60.0,
      );

      // Assert: Processing should succeed and bowls should be detected
      expect(result2['success'], isTrue,
          reason: 'Image processing should succeed with custom jack diameter');
      expect(result2['bowls'], isNotNull,
          reason: 'Bowls should be detected in the test image');
      final bowls2 = result2['bowls'] as List;
      expect(bowls2.isNotEmpty, isTrue,
          reason: 'At least one bowl should be detected');

      // Act 2: Get the first bowl's distance
      final distanceCustom =
          (bowls2.first as Map<String, dynamic>)['distance'] as double;

      // Assert: Expect the two distances to be different
      // This will fail (Red Phase) because the hardcoded jackDiameterMm is not being used
      // in the distance calculation (or the isolate isn't reading it), resulting in
      // distanceDefault and distanceCustom being identical
      expect(distanceDefault, isNot(equals(distanceCustom)),
          reason: 'Distance should change when jack diameter changes. '
              'Default diameter (63.5mm) distance: $distanceDefault, '
              'Custom diameter (60.0mm) distance: $distanceCustom');
    });

    test(
        'should correctly process a complex head with 8+ bowls at various distances',
        () async {
      // Arrange: Load a complex test image with 8+ bowls at various distances
      // This test image should contain bowls both close to the camera and far away
      // (spread-out head scenario) to prove we can handle more than Bowlometre's 6-bowl limit
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/complex_head_8_bowls.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Call processImageBytes to get processing results
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/complex_head_8_bowls.jpg',
      );

      // Act: Convert processing result to MeasurementResult
      final result = ImageProcessor.createMeasurementResult(processingResult);

      // Assert: Expect processing to succeed
      expect(processingResult['success'], isTrue,
          reason:
              'Image processing should succeed for complex head with 8+ bowls');

      // Assert: Expect at least 8 bowls to be detected in the raw processing result
      // This will fail (Red Phase) if:
      // 1. ContourDetector filters (area, circularity, hue) are too strict and reject
      //    distant or partially occluded bowls
      // 2. Size ratio validation in image_processing_isolate.dart rejects bowls outside
      //    1.3x-3.0x jack size (distant bowls may appear smaller than this ratio)
      expect(processingResult['bowls'], isNotNull,
          reason: 'Bowls list should be present in processing result');
      final bowlsList = processingResult['bowls'] as List;
      expect(bowlsList.length, greaterThanOrEqualTo(8),
          reason:
              'Should detect at least 8 bowls to prove we exceed Bowlometre\'s 6-bowl limit. '
              'Detected: ${bowlsList.length} bowls. '
              'This test fails (Red Phase) if ContourDetector filters or size ratio validation '
              'are too strict for distant bowls.');

      // Assert: Expect at least 8 bowls in the MeasurementResult
      // This verifies the full pipeline from detection to result creation
      expect(result.bowls.length, greaterThanOrEqualTo(8),
          reason: 'MeasurementResult should contain at least 8 bowls. '
              'Found: ${result.bowls.length} bowls. '
              'This proves "Stand \'n\' Measure" can handle complex spread-out heads '
              'that Bowlometre cannot process.');
    });

    test(
        'should not return an excessive number of bowls (noise filter sanity check)',
        () async {
      // Arrange: Load the static test image file that is known to contain bowls
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Call processImageBytes to get processing results
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
      );

      // Assert: Expect processing to succeed
      expect(processingResult['success'], isTrue,
          reason: 'Image processing should succeed');

      // Assert: Expect the number of detected bowls to be within a reasonable limit
      // This test will fail (Red Phase) because the current relaxed filters
      // (set during the 'exceed Bowlometre limit' TDD cycle) allow noise and texture
      // to be detected as bowls, resulting in an excessive number of false positives
      expect(processingResult['bowls'], isNotNull,
          reason: 'Bowls list should be present in processing result');
      final bowlsList = processingResult['bowls'] as List;
      expect(bowlsList.length, lessThan(20),
          reason:
              'Should not detect more than 20 bowls (noise filter sanity check). '
              'Detected: ${bowlsList.length} bowls. '
              'This test fails (Red Phase) if the relaxed filters are too permissive '
              'and detect noise/texture as bowls. A typical lawn bowls head contains '
              '8-16 bowls maximum, so detecting 20+ suggests false positives from noise.');
    });
  });
}
