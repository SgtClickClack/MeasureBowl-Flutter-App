import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../services/measurement_history_service.dart';
import '../models/measurement_result.dart';

/// View model responsible for managing performance analytics and statistics.
class StatsViewModel extends ChangeNotifier {
  StatsViewModel({dynamic historyService})
      : _historyService = historyService ?? MeasurementHistoryService();

  final dynamic _historyService;

  int _totalBowls = 0;

  /// Total number of bowls measured across all sessions
  int get totalBowls => _totalBowls;

  double _averageDistanceCm = 0.0;

  /// Overall average distance of all measured bowls from the jack (in cm)
  double get averageDistanceCm => _averageDistanceCm;

  double _averageBestBowlDistanceCm = 0.0;

  /// Average distance of the closest bowl per measurement (in cm)
  double get averageBestBowlDistanceCm => _averageBestBowlDistanceCm;

  double _bestBowlDistanceCm = 0.0;

  /// Best single bowl distance recorded across all measurements (in cm)
  double get bestBowlDistanceCm => _bestBowlDistanceCm;

  /// Load statistics from measurement history
  Future<void> loadStats() async {
    final history = await _getAllMeasurements();
    final total = history.fold(0, (sum, m) => sum + m.bowls.length);
    _totalBowls = total;

    // Calculate total distance across all bowls
    final totalDistance = history.fold(
      0.0,
      (sum, m) =>
          sum +
          m.bowls.fold(
            0.0,
            (innerSum, b) => innerSum + b.distanceFromJack,
          ),
    );

    // Calculate average distance (avoid division by zero)
    final average = total > 0 ? totalDistance / total : 0.0;
    _averageDistanceCm = average;

    // Calculate total best distance (sum of closest bowl per measurement)
    final totalBestDistance = history.fold(
      0.0,
      (sum, m) {
        if (m.bowls.isEmpty) return sum;
        final minDistance = m.bowls
            .map((b) => b.distanceFromJack)
            .reduce((a, b) => math.min(a, b));
        return sum + minDistance;
      },
    );

    // Calculate average best distance (avoid division by zero)
    final averageBest =
        history.isNotEmpty ? totalBestDistance / history.length : 0.0;
    _averageBestBowlDistanceCm = averageBest;

    // Calculate absolute minimum distance across all bowls
    double overallMinDistance = double.infinity;
    final allDistances =
        history.expand((m) => m.bowls.map((b) => b.distanceFromJack)).toList();

    if (allDistances.isNotEmpty) {
      overallMinDistance = allDistances.reduce(math.min);
    } else {
      overallMinDistance = 0.0;
    }

    _bestBowlDistanceCm = overallMinDistance;

    notifyListeners();
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
}
