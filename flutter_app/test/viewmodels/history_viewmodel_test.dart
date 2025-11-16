import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/viewmodels/history_viewmodel.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';
import 'package:lawn_bowls_measure/services/measurement_history_service.dart';
import 'package:lawn_bowls_measure/providers/history_notifier_provider.dart';
import 'package:lawn_bowls_measure/providers/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock service for testing error scenarios
/// This class mimics MeasurementHistoryService but can throw errors for testing
class MockHistoryService {
  final bool shouldThrowError;
  final Exception? errorToThrow;
  List<MeasurementResult> _measurements = [];
  final List<String> _deleteMeasurementCalls = [];
  final List<MeasurementResult> _saveMeasurementCalls = [];

  MockHistoryService({
    this.shouldThrowError = false,
    this.errorToThrow,
    List<MeasurementResult>? initialMeasurements,
  }) : _measurements =
            initialMeasurements != null ? List.from(initialMeasurements) : [];

  Future<List<MeasurementResult>> getAllMeasurements() async {
    if (shouldThrowError) {
      throw errorToThrow ??
          Exception('Mock error: Failed to load measurements');
    }
    // Return the stored measurements
    return List.from(_measurements);
  }

  Future<bool> deleteMeasurement(String id) async {
    if (shouldThrowError) {
      throw errorToThrow ??
          Exception('Mock error: Failed to delete measurement');
    }
    // Track the call
    _deleteMeasurementCalls.add(id);
    // Remove the measurement from the list
    _measurements.removeWhere((m) => m.id == id);
    return true;
  }

  Future<bool> saveMeasurement(MeasurementResult measurement) async {
    if (shouldThrowError) {
      throw errorToThrow ?? Exception('Mock error: Failed to save measurement');
    }
    // Track the call
    _saveMeasurementCalls.add(measurement);
    // Add the measurement to the list if it doesn't already exist
    if (!_measurements.any((m) => m.id == measurement.id)) {
      _measurements.add(measurement);
    }
    return true;
  }

  /// Get the list of IDs that deleteMeasurement was called with
  List<String> get deleteMeasurementCalls => List.from(_deleteMeasurementCalls);

  /// Get the number of times deleteMeasurement was called
  int get deleteMeasurementCallCount => _deleteMeasurementCalls.length;

  /// Get the list of measurements that saveMeasurement was called with
  List<MeasurementResult> get saveMeasurementCalls =>
      List.from(_saveMeasurementCalls);

  /// Get the number of times saveMeasurement was called
  int get saveMeasurementCallCount => _saveMeasurementCalls.length;
}

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

  group('HistoryNotifier', () {
    test('should load and display measurements on initialization', () async {
      // Arrange: Create and save mock measurements
      final firstMockResult = MeasurementResult.createMock();
      final secondMockResult = MeasurementResult.createMock();
      await MeasurementHistoryService.saveMeasurement(firstMockResult);
      await MeasurementHistoryService.saveMeasurement(secondMockResult);

      // Arrange: Create ProviderContainer
      final container = ProviderContainer();

      // Act: Get the notifier and initialize
      final notifier = container.read(historyNotifierProvider.notifier);
      await notifier.initialize();

      // Assert: Verify measurements are loaded
      final state = container.read(historyNotifierProvider);
      expect(state.measurements.length, equals(2));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);

      // Verify measurements are present (order may vary due to sorting)
      final measurementIds = state.measurements.map((m) => m.id).toList();
      expect(measurementIds, contains(firstMockResult.id));
      expect(measurementIds, contains(secondMockResult.id));

      // Cleanup
      container.dispose();
    });

    test('should set error message on initialization failure', () async {
      // Arrange: Create a mock service that throws an error
      final mockService = MockHistoryService(
        shouldThrowError: true,
        errorToThrow: Exception('Test error: Failed to load'),
      );

      // Arrange: Create ProviderContainer with overridden history notifier provider
      final container = ProviderContainer(
        overrides: [
          historyNotifierProvider
              .overrideWith((ref) => HistoryNotifier(mockService)),
        ],
      );

      // Act: Get the notifier and initialize
      final notifier = container.read(historyNotifierProvider.notifier);
      await notifier.initialize();

      // Assert: Verify error state
      final state = container.read(historyNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Test error'));
      expect(state.measurements, isEmpty);

      // Cleanup
      container.dispose();
    });

    test('should set loading state during initialization', () async {
      // Arrange: Create ProviderContainer
      final container = ProviderContainer();
      final notifier = container.read(historyNotifierProvider.notifier);

      // Act: Initialize the notifier
      final initializeFuture = notifier.initialize();

      // Assert: Verify loading state is true during initialization
      final stateDuringLoad = container.read(historyNotifierProvider);
      expect(stateDuringLoad.isLoading, isTrue);

      // Wait for initialization to complete
      await initializeFuture;

      // Assert: Verify loading state is false after initialization
      final stateAfterLoad = container.read(historyNotifierProvider);
      expect(stateAfterLoad.isLoading, isFalse);

      // Cleanup
      container.dispose();
    });

    test(
        'should call service and remove measurement from list when deleteMeasurement is called',
        () async {
      // Arrange: Create mock service with 2 mock measurements
      // Add small delay to ensure unique IDs
      final firstMockResult = MeasurementResult.createMock();
      await Future.delayed(const Duration(milliseconds: 1));
      final secondMockResult = MeasurementResult.createMock();
      final mockService = MockHistoryService(
        initialMeasurements: [firstMockResult, secondMockResult],
      );

      // Arrange: Create ProviderContainer with overridden history notifier provider
      final container = ProviderContainer(
        overrides: [
          historyNotifierProvider
              .overrideWith((ref) => HistoryNotifier(mockService)),
        ],
      );

      // Arrange: Get the notifier and initialize
      final notifier = container.read(historyNotifierProvider.notifier);
      await notifier.initialize();

      // Assert: Verify initial state has 2 measurements
      var state = container.read(historyNotifierProvider);
      expect(state.measurements.length, equals(2));
      expect(state.measurements.map((m) => m.id).toList(),
          containsAll([firstMockResult.id, secondMockResult.id]));

      // Act: Call deleteMeasurement with the first measurement's ID
      await notifier.deleteMeasurement(firstMockResult.id);

      // Assert: Verify mock service's deleteMeasurement was called once with correct ID
      expect(mockService.deleteMeasurementCallCount, equals(1));
      expect(mockService.deleteMeasurementCalls, contains(firstMockResult.id));

      // Assert: Verify measurements list now has length 1
      state = container.read(historyNotifierProvider);
      expect(state.measurements.length, equals(1));

      // Assert: Verify measurements contains only the second measurement
      expect(state.measurements.first.id, equals(secondMockResult.id));
      expect(state.measurements.map((m) => m.id).toList(),
          isNot(contains(firstMockResult.id)));

      // Cleanup
      container.dispose();
    });

    test(
        'should restore the last deleted measurement when undoLastDelete is called',
        () async {
      // Arrange: Create a mock measurement
      final itemToDelete = MeasurementResult.createMock();
      final mockService = MockHistoryService(
        initialMeasurements: [itemToDelete],
      );

      // Arrange: Create ProviderContainer with overridden history notifier provider
      final container = ProviderContainer(
        overrides: [
          historyNotifierProvider
              .overrideWith((ref) => HistoryNotifier(mockService)),
        ],
      );

      // Arrange: Get the notifier and initialize
      final notifier = container.read(historyNotifierProvider.notifier);
      await notifier.initialize();

      // Assert: Verify initial state has 1 measurement
      var state = container.read(historyNotifierProvider);
      expect(state.measurements.length, equals(1));
      expect(state.measurements.first.id, equals(itemToDelete.id));

      // Act: Call deleteMeasurement to remove it from the list
      await notifier.deleteMeasurement(itemToDelete.id);

      // Assert: Verify measurements list is now empty
      state = container.read(historyNotifierProvider);
      expect(state.measurements, isEmpty);

      // Act: Call undoLastDelete to restore it
      await notifier.undoLastDelete();

      // Assert: Verify measurements list now has length 1
      state = container.read(historyNotifierProvider);
      expect(state.measurements.length, equals(1));

      // Assert: Verify measurements contains the original itemToDelete
      expect(state.measurements.first.id, equals(itemToDelete.id));
      expect(state.measurements, contains(itemToDelete));

      // Assert: Verify the mock service's saveMeasurement was called (to restore in persistence)
      expect(mockService.saveMeasurementCallCount, equals(1));
      expect(mockService.saveMeasurementCalls, contains(itemToDelete));

      // Cleanup
      container.dispose();
    });
  });
}
