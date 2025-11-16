import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/services/image_processor.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';

/// Test to verify Bug 1 fix: Type casting crash when 'distance' is an int
///
/// This test ensures that createMeasurementResult can handle both int and double
/// values for the 'distance' field without crashing.
void main() {
  group('ImageProcessor - Type Casting Fix (Bug 1)', () {
    test('should handle int distance values without crashing', () {
      // Arrange: Create a processing result with int distance (the bug scenario)
      final processingResult = {
        'success': true,
        'image_path': '/test/path.jpg',
        'bowls': [
          {
            'distance': 152, // int value (this was causing the crash)
            'x': 100,
            'y': 200,
            'team': 'Team A',
          },
          {
            'distance': 250.5, // double value (should also work)
            'x': 300,
            'y': 400,
            'team': 'Team B',
          },
        ],
      };

      // Act: This should not crash with "type 'int' is not a subtype of type 'double'"
      MeasurementResult? result;
      expect(() {
        result = ImageProcessor.createMeasurementResult(processingResult);
      }, returnsNormally, reason: 'Should not crash when distance is an int');

      // Assert: Verify the result was created correctly
      expect(result, isNotNull);
      final finalResult = result!;
      expect(finalResult.bowls.length, equals(2));
      expect(finalResult.bowls[0].distanceFromJack,
          equals(15.2)); // 152mm / 10 = 15.2cm
      expect(finalResult.bowls[1].distanceFromJack,
          equals(25.05)); // 250.5mm / 10 = 25.05cm
    });

    test('should handle null distance values gracefully', () {
      // Arrange: Create a processing result with null distance
      final processingResult = {
        'success': true,
        'image_path': '/test/path.jpg',
        'bowls': [
          {
            'distance': null,
            'x': 100,
            'y': 200,
            'team': 'Team A',
          },
        ],
      };

      // Act & Assert: Should default to 0.0 without crashing
      final result = ImageProcessor.createMeasurementResult(processingResult);
      expect(result.bowls.length, equals(1));
      expect(result.bowls[0].distanceFromJack, equals(0.0));
    });

    test('should handle string distance values by parsing', () {
      // Arrange: Create a processing result with string distance (edge case)
      final processingResult = {
        'success': true,
        'image_path': '/test/path.jpg',
        'bowls': [
          {
            'distance': '152', // string value
            'x': 100,
            'y': 200,
            'team': 'Team A',
          },
        ],
      };

      // Act & Assert: Should parse string to double
      final result = ImageProcessor.createMeasurementResult(processingResult);
      expect(result.bowls.length, equals(1));
      expect(result.bowls[0].distanceFromJack,
          equals(15.2)); // 152mm / 10 = 15.2cm
    });
  });
}
