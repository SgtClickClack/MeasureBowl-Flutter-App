/// Data model representing a single bowl measurement result
class BowlMeasurement {
  final String id;
  final String color;
  final double distanceFromJack; // Distance in centimeters
  final int rank; // 1st, 2nd, 3rd place etc.

  const BowlMeasurement({
    required this.id,
    required this.color,
    required this.distanceFromJack,
    required this.rank,
  });

  /// Create a mock bowl measurement for testing purposes
  factory BowlMeasurement.mock({
    required String id,
    required String color,
    required double distance,
    required int rank,
  }) {
    return BowlMeasurement(
      id: id,
      color: color,
      distanceFromJack: distance,
      rank: rank,
    );
  }
}

/// Data model representing the complete measurement results
class MeasurementResult {
  final String id;
  final DateTime timestamp;
  final String? imagePath; // Path to captured image
  final List<BowlMeasurement> bowls;

  const MeasurementResult({
    required this.id,
    required this.timestamp,
    this.imagePath,
    required this.bowls,
  });

  /// Create measurement results with captured image
  factory MeasurementResult.fromCapturedImage({
    required String imagePath,
    List<BowlMeasurement>? bowls,
  }) {
    return MeasurementResult(
      id: 'measurement_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: imagePath,
      bowls: bowls ?? [
        // Mock bowls for now - will be replaced with actual CV processing
        BowlMeasurement.mock(
          id: 'bowl_1',
          color: 'Yellow',
          distance: 5.2,
          rank: 1,
        ),
        BowlMeasurement.mock(
          id: 'bowl_2', 
          color: 'Red',
          distance: 8.7,
          rank: 2,
        ),
        BowlMeasurement.mock(
          id: 'bowl_3',
          color: 'Black',
          distance: 12.1,
          rank: 3,
        ),
      ],
    );
  }

  /// Create mock measurement results for testing purposes
  factory MeasurementResult.createMock() {
    return MeasurementResult(
      id: 'mock_measurement_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      imagePath: null, // Will use placeholder asset
      bowls: [
        BowlMeasurement.mock(
          id: 'bowl_1',
          color: 'Yellow',
          distance: 5.2,
          rank: 1,
        ),
        BowlMeasurement.mock(
          id: 'bowl_2', 
          color: 'Red',
          distance: 8.7,
          rank: 2,
        ),
        BowlMeasurement.mock(
          id: 'bowl_3',
          color: 'Black',
          distance: 12.1,
          rank: 3,
        ),
      ],
    );
  }

  /// Get the closest bowl (rank 1)
  BowlMeasurement? get closestBowl {
    if (bowls.isEmpty) return null;
    return bowls.firstWhere((bowl) => bowl.rank == 1);
  }
}