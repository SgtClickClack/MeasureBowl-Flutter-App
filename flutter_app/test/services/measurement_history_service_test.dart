import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/services/measurement_history_service.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize Flutter binding for SharedPreferences
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

  group('MeasurementHistoryService', () {
    test('can save a measurement and retrieve it', () async {
      // Arrange: Create a mock measurement result
      final mockResult = MeasurementResult.createMock();

      // Act: Save the measurement
      final saveSuccess = await MeasurementHistoryService.saveMeasurement(
        mockResult,
      );

      // Assert: Save should succeed
      expect(saveSuccess, isTrue);

      // Act: Retrieve all measurements
      final results = await MeasurementHistoryService.getAllMeasurements();

      // Assert: Should have exactly one measurement
      expect(results.length, equals(1));
      expect(results.first.id, equals(mockResult.id));
      expect(results.first.timestamp, equals(mockResult.timestamp));
      expect(results.first.bowls.length, equals(mockResult.bowls.length));
    });

    test('can get a single measurement by ID', () async {
      // Arrange: Save a mock measurement result
      final mockResult = MeasurementResult.createMock();
      await MeasurementHistoryService.saveMeasurement(mockResult);

      // Act: Get the measurement by ID
      final retrievedResult =
          await MeasurementHistoryService.getMeasurement(mockResult.id);

      // Assert: Should return non-null and match the saved result
      expect(retrievedResult, isNotNull);
      expect(retrievedResult!.id, equals(mockResult.id));
      expect(retrievedResult.timestamp, equals(mockResult.timestamp));
      expect(retrievedResult.bowls.length, equals(mockResult.bowls.length));
    });

    test('returns null when getting non-existent measurement by ID', () async {
      // Arrange: Don't save anything

      // Act: Try to get a measurement with a non-existent ID
      final result =
          await MeasurementHistoryService.getMeasurement('non_existent_id');

      // Assert: Should return null
      expect(result, isNull);
    });

    test('can delete a measurement by ID', () async {
      // Arrange: Save two mock results
      final firstResult = MeasurementResult.createMock();
      final secondResult = MeasurementResult.createMock();
      await MeasurementHistoryService.saveMeasurement(firstResult);
      await MeasurementHistoryService.saveMeasurement(secondResult);

      // Act: Delete the first measurement
      final deleteSuccess =
          await MeasurementHistoryService.deleteMeasurement(firstResult.id);

      // Assert: Delete should succeed
      expect(deleteSuccess, isTrue);

      // Act: Get all measurements
      final allResults = await MeasurementHistoryService.getAllMeasurements();

      // Assert: Should have only one measurement (the second one)
      expect(allResults.length, equals(1));
      expect(allResults.first.id, equals(secondResult.id));
    });

    test('returns false when deleting non-existent measurement', () async {
      // Arrange: Don't save anything

      // Act: Try to delete a non-existent measurement
      final deleteSuccess =
          await MeasurementHistoryService.deleteMeasurement('non_existent_id');

      // Assert: Should return false
      expect(deleteSuccess, isFalse);
    });

    test('can get measurement count', () async {
      // Arrange: Save three mock results
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );

      // Act: Get the measurement count
      final count = await MeasurementHistoryService.getMeasurementCount();

      // Assert: Should return 3
      expect(count, equals(3));
    });

    test('returns zero count when no measurements exist', () async {
      // Arrange: Don't save anything

      // Act: Get the measurement count
      final count = await MeasurementHistoryService.getMeasurementCount();

      // Assert: Should return 0
      expect(count, equals(0));
    });

    test('can clear all measurements', () async {
      // Arrange: Save multiple mock results
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );
      await MeasurementHistoryService.saveMeasurement(
        MeasurementResult.createMock(),
      );

      // Verify measurements exist before clearing
      final beforeClear = await MeasurementHistoryService.getAllMeasurements();
      expect(beforeClear.length, equals(3));

      // Act: Clear all measurements
      await MeasurementHistoryService.clearAllMeasurements();

      // Assert: All measurements should be cleared
      final afterClear = await MeasurementHistoryService.getAllMeasurements();
      expect(afterClear, isEmpty);

      // Assert: Count should be 0
      final count = await MeasurementHistoryService.getMeasurementCount();
      expect(count, equals(0));
    });
  });
}
