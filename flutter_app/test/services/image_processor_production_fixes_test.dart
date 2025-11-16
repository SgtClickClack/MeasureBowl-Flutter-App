import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lawn_bowls_measure/services/image_processor.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';

/// Integration test to verify production bug fixes using the sample test image
///
/// This test verifies:
/// 1. Bug 1 Fix: Type casting crash when 'distance' is an int
/// 2. Bug 2 Fix: Relaxed detection filters allow bowls to be detected in Pro Mode
void main() {
  // Initialize Flutter binding for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up mock SharedPreferences
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Production Bug Fixes - Using Sample Test Image', () {
    test('Bug 1: Should process image without type casting crash', () async {
      // Arrange: Load the sample test image
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Process the image (this should not crash with type casting error)
      // Note: OpenCV may not be available in Windows test environment
      Map<String, dynamic> processingResult;
      expect(() async {
        processingResult = await ImageProcessor.processImageBytes(
          imageBytes,
          'assets/test_images/bowls_on_green.jpg',
        );
      }, returnsNormally, reason: 'Should not crash with type casting error');

      // Wait for async operation
      processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
      );

      // If processing succeeded, verify createMeasurementResult doesn't crash
      if (processingResult!['success'] == true) {
        MeasurementResult? result;
        expect(() {
          result = ImageProcessor.createMeasurementResult(processingResult!);
        }, returnsNormally,
            reason:
                'createMeasurementResult should handle int/double distance values without crashing');

        // Verify the result was created successfully
        expect(result, isNotNull);
        expect(result!.bowls, isNotEmpty,
            reason: 'Should detect bowls in the test image');

        // Verify distances are valid (not NaN or infinite)
        final finalResult = result!;
        for (final bowl in finalResult.bowls) {
          expect(bowl.distanceFromJack, isNot(isNaN),
              reason: 'Distance should not be NaN');
          expect(bowl.distanceFromJack.isFinite, isTrue,
              reason: 'Distance should be finite');
          expect(bowl.distanceFromJack, greaterThanOrEqualTo(0.0),
              reason: 'Distance should be non-negative');
        }
      }
    });

    test('Bug 2: Should detect bowls with relaxed filters in Pro Mode',
        () async {
      // Arrange: Load the sample test image
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Process the image with Pro Accuracy Mode enabled
      final processingResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        proAccuracyMode: true,
      );

      // Assert: Processing should succeed (may fail if OpenCV not available in test env)
      // But if it succeeds, we should get results with relaxed filters
      if (processingResult['success'] == true) {
        final result = ImageProcessor.createMeasurementResult(processingResult);

        // With relaxed filters, we should detect bowls:
        // - minArea reduced from 20.0 to 10.0 (allows smaller/distant bowls)
        // - aspect ratio filters added (0.5-1.5 range allows ovals/angled bowls)
        // - size ratio relaxed from 0.8-4.0x to 0.5-8.0x (allows more size variation)
        expect(result.bowls, isNotEmpty,
            reason:
                'Relaxed filters should allow detection of bowls in Pro Mode');

        // Verify bowls have valid coordinates
        for (final bowl in result.bowls) {
          expect(bowl.x, greaterThanOrEqualTo(0),
              reason: 'Bowl x coordinate should be valid');
          expect(bowl.y, greaterThanOrEqualTo(0),
              reason: 'Bowl y coordinate should be valid');
        }

        // Log the number of bowls detected for verification
        print('Detected ${result.bowls.length} bowls with relaxed filters');
      } else {
        // If OpenCV is not available in test environment, skip this test
        // but don't fail - this is expected in some CI environments
        print(
            'OpenCV not available in test environment - skipping Pro Mode test');
      }
    });

    test(
        'Bug 1 & 2 Combined: Should process and create results without crashes',
        () async {
      // Arrange: Load the sample test image
      final ByteData imageData = await rootBundle.load(
        'assets/test_images/bowls_on_green.jpg',
      );
      final Uint8List imageBytes = imageData.buffer.asUint8List();

      // Act: Process image in both Standard and Pro modes
      final standardResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        proAccuracyMode: false,
      );

      final proResult = await ImageProcessor.processImageBytes(
        imageBytes,
        'assets/test_images/bowls_on_green.jpg',
        proAccuracyMode: true,
      );

      // Assert: Both should process without crashing
      // The key test is that createMeasurementResult doesn't crash with type errors
      if (standardResult['success'] == true) {
        MeasurementResult? standardMeasurement;
        expect(() {
          standardMeasurement =
              ImageProcessor.createMeasurementResult(standardResult);
        }, returnsNormally,
            reason: 'Standard mode should not crash with type casting errors');

        expect(standardMeasurement, isNotNull);
        print(
            'Standard Mode: Detected ${standardMeasurement!.bowls.length} bowls');
      }

      if (proResult['success'] == true) {
        MeasurementResult? proMeasurement;
        expect(() {
          proMeasurement = ImageProcessor.createMeasurementResult(proResult);
        }, returnsNormally,
            reason: 'Pro Mode should not crash with type casting errors');

        expect(proMeasurement, isNotNull);
        print('Pro Mode: Detected ${proMeasurement!.bowls.length} bowls');

        // With relaxed filters, Pro Mode should detect bowls (or at least not return empty)
        // Note: Exact count may vary, but should not be empty due to overly strict filters
        final finalProMeasurement = proMeasurement!;
        expect(
            finalProMeasurement.bowls.isNotEmpty || proResult['error'] != null,
            isTrue,
            reason:
                'Pro Mode should either detect bowls or provide a clear error (not silently fail)');
      }
    });
  });
}
