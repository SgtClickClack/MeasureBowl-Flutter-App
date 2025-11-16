import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/measurement_result.dart';
import '../services/measurement_history_service.dart';

/// State class for history notifier
class HistoryState {
  final List<MeasurementResult> measurements;
  final bool isLoading;
  final String? errorMessage;
  final MeasurementResult? lastDeletedMeasurement;

  const HistoryState({
    this.measurements = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastDeletedMeasurement,
  });

  HistoryState copyWith({
    List<MeasurementResult>? measurements,
    bool? isLoading,
    String? errorMessage,
    MeasurementResult? lastDeletedMeasurement,
  }) {
    return HistoryState(
      measurements: measurements ?? this.measurements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastDeletedMeasurement:
          lastDeletedMeasurement ?? this.lastDeletedMeasurement,
    );
  }
}

/// Notifier responsible for managing measurement history state and operations.
class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier(this._historyService) : super(const HistoryState());

  final dynamic _historyService;

  /// Initialize and load measurements from history
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final measurements = await _getAllMeasurements();
      state = state.copyWith(
        measurements: measurements,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get all measurements from the service
  /// This method can be overridden in tests via dependency injection
  Future<List<MeasurementResult>> _getAllMeasurements() async {
    final service = _historyService;

    // Try to use instance method first (for mocks/test services)
    // Check if service is not the default MeasurementHistoryService instance
    if (service is! MeasurementHistoryService) {
      // For mock services, use dynamic call
      return await (service as dynamic).getAllMeasurements();
    }

    // Default: use static method for the real service
    return await MeasurementHistoryService.getAllMeasurements();
  }

  /// Delete a measurement by ID
  Future<void> deleteMeasurement(String measurementId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _deleteMeasurement(measurementId);
      if (success) {
        // Store the deleted measurement before removing it
        final lastDeletedMeasurement =
            state.measurements.firstWhere((m) => m.id == measurementId);
        final updatedMeasurements =
            List<MeasurementResult>.from(state.measurements)
              ..removeWhere((m) => m.id == measurementId);
        state = state.copyWith(
          measurements: updatedMeasurements,
          isLoading: false,
          lastDeletedMeasurement: lastDeletedMeasurement,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Delete a measurement from the service
  /// This method can be overridden in tests via dependency injection
  Future<bool> _deleteMeasurement(String id) async {
    final service = _historyService;

    // Try to use instance method first (for mocks/test services)
    // Check if service is not the default MeasurementHistoryService instance
    if (service is! MeasurementHistoryService) {
      // For mock services, use dynamic call
      return await (service as dynamic).deleteMeasurement(id);
    }

    // Default: use static method for the real service
    return await MeasurementHistoryService.deleteMeasurement(id);
  }

  /// Restore the last deleted measurement
  Future<void> undoLastDelete() async {
    // Check if there's a last deleted measurement
    if (state.lastDeletedMeasurement == null) {
      return;
    }

    // Store the item locally
    final itemToRestore = state.lastDeletedMeasurement!;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Save the item back to the service
      await _saveMeasurement(itemToRestore);

      // Add the item back to the local list
      final updatedMeasurements =
          List<MeasurementResult>.from(state.measurements)..add(itemToRestore);

      // Re-sort the list by timestamp to maintain order (newest first)
      updatedMeasurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = state.copyWith(
        measurements: updatedMeasurements,
        isLoading: false,
        lastDeletedMeasurement: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Save a measurement to the service
  /// This method can be overridden in tests via dependency injection
  Future<bool> _saveMeasurement(MeasurementResult measurement) async {
    final service = _historyService;

    // Try to use instance method first (for mocks/test services)
    // Check if service is not the default MeasurementHistoryService instance
    if (service is! MeasurementHistoryService) {
      // For mock services, use dynamic call
      return await (service as dynamic).saveMeasurement(measurement);
    }

    // Default: use static method for the real service
    return await MeasurementHistoryService.saveMeasurement(measurement);
  }
}
