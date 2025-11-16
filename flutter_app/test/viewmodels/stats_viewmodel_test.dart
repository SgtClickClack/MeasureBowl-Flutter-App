import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/viewmodels/stats_viewmodel.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';

/// Mock service for testing StatsViewModel
/// Returns a list of mock measurements with configurable bowl counts
class MockHistoryService {
  final List<MeasurementResult> _measurements;

  MockHistoryService({List<MeasurementResult>? initialMeasurements})
      : _measurements = initialMeasurements ?? [];

  Future<List<MeasurementResult>> getAllMeasurements() async {
    return List.from(_measurements);
  }
}

void main() {
  group('StatsViewModel', () {
    test('should calculate total number of bowls measured across all sessions',
        () async {
      // Arrange: Create a mock service with 5 measurements, each with 4 bowls
      final mockMeasurements = List.generate(5, (index) {
        return MeasurementResult(
          id: 'mock_measurement_$index',
          timestamp: DateTime.now().add(Duration(seconds: index)),
          bowls: List.generate(4, (bowlIndex) {
            return BowlMeasurement.mock(
              id: 'bowl_${index}_$bowlIndex',
              teamName: 'Team A',
              distance: 5.0 + bowlIndex,
              rank: bowlIndex + 1,
            );
          }),
        );
      });

      final mockService = MockHistoryService(
        initialMeasurements: mockMeasurements,
      );

      // Arrange: Instantiate the StatsViewModel with the mock service
      final viewModel = StatsViewModel(historyService: mockService);

      // Act: Call loadStats method (doesn't exist yet - will fail)
      await viewModel.loadStats();

      // Assert: Expect totalBowls to equal the sum of bowls in mock data
      // 5 sessions * 4 bowls/session = 20 total bowls
      expect(viewModel.totalBowls, equals(20));
    });

    test('should calculate the overall average distance in cm', () async {
      // Arrange: Create a mock service with 5 measurements, each with 4 bowls
      // Total distance across all bowls = 600 cm, so average = 30 cm (600 / 20 bowls)
      final mockMeasurements = List.generate(5, (index) {
        // Distribute distances so they sum to 120 per measurement (120 * 5 = 600 total)
        final distances = [
          25.0, // bowl 0
          30.0, // bowl 1
          35.0, // bowl 2
          30.0, // bowl 3
        ]; // Sum = 120 per measurement

        return MeasurementResult(
          id: 'mock_measurement_$index',
          timestamp: DateTime.now().add(Duration(seconds: index)),
          bowls: List.generate(4, (bowlIndex) {
            return BowlMeasurement.mock(
              id: 'bowl_${index}_$bowlIndex',
              teamName: 'Team A',
              distance: distances[bowlIndex],
              rank: bowlIndex + 1,
            );
          }),
        );
      });

      final mockService = MockHistoryService(
        initialMeasurements: mockMeasurements,
      );

      // Arrange: Instantiate the StatsViewModel with the mock service
      final viewModel = StatsViewModel(historyService: mockService);

      // Act: Call loadStats method
      await viewModel.loadStats();

      // Assert: Expect averageDistanceCm to equal 30.0 cm
      // Total distance = 600 cm (5 measurements * 120 cm each)
      // Total bowls = 20 (5 measurements * 4 bowls each)
      // Average = 600 / 20 = 30.0 cm
      expect(viewModel.averageDistanceCm, equals(30.0));
    });

    test(
        'should calculate the average distance of the closest bowl per measurement',
        () async {
      // Arrange: Create a mock service with 5 measurements
      // Each measurement has a closest bowl (rank 1) with a specific distance
      // Closest bowl distances: 10, 8, 12, 9, 11 cm
      // Expected average: (10 + 8 + 12 + 9 + 11) / 5 = 50 / 5 = 10.0 cm
      final closestDistances = [10.0, 8.0, 12.0, 9.0, 11.0];

      final mockMeasurements = List.generate(5, (index) {
        final closestDistance = closestDistances[index];
        // Create bowls where the first one (rank 1) is the closest with the specified distance
        // Other bowls have larger distances to ensure rank 1 is truly the closest
        return MeasurementResult(
          id: 'mock_measurement_$index',
          timestamp: DateTime.now().add(Duration(seconds: index)),
          bowls: [
            // Closest bowl (rank 1) with the specified distance
            BowlMeasurement.mock(
              id: 'bowl_${index}_0',
              teamName: 'Team A',
              distance: closestDistance,
              rank: 1,
            ),
            // Additional bowls with larger distances
            BowlMeasurement.mock(
              id: 'bowl_${index}_1',
              teamName: 'Team B',
              distance: closestDistance + 5.0,
              rank: 2,
            ),
            BowlMeasurement.mock(
              id: 'bowl_${index}_2',
              teamName: 'Team A',
              distance: closestDistance + 10.0,
              rank: 3,
            ),
            BowlMeasurement.mock(
              id: 'bowl_${index}_3',
              teamName: 'Team B',
              distance: closestDistance + 15.0,
              rank: 4,
            ),
          ],
        );
      });

      final mockService = MockHistoryService(
        initialMeasurements: mockMeasurements,
      );

      // Arrange: Instantiate the StatsViewModel with the mock service
      final viewModel = StatsViewModel(historyService: mockService);

      // Act: Call loadStats method
      await viewModel.loadStats();

      // Assert: Expect averageBestBowlDistanceCm to equal 10.0 cm
      // Closest bowl distances: 10, 8, 12, 9, 11 cm
      // Average = (10 + 8 + 12 + 9 + 11) / 5 = 50 / 5 = 10.0 cm
      expect(viewModel.averageBestBowlDistanceCm, equals(10.0));
    });

    test('should calculate the best single bowl distance recorded', () async {
      // Arrange: Create a mock service with multiple measurements
      // One bowl should have the absolute minimum distance (5.0 cm)
      // All other bowls should have greater distances
      final mockMeasurements = [
        // Measurement 0: Contains the best bowl (5.0 cm)
        MeasurementResult(
          id: 'mock_measurement_0',
          timestamp: DateTime.now(),
          bowls: [
            BowlMeasurement.mock(
              id: 'bowl_0_0',
              teamName: 'Team A',
              distance: 5.0, // Best single bowl distance
              rank: 1,
            ),
            BowlMeasurement.mock(
              id: 'bowl_0_1',
              teamName: 'Team B',
              distance: 15.0,
              rank: 2,
            ),
            BowlMeasurement.mock(
              id: 'bowl_0_2',
              teamName: 'Team A',
              distance: 20.0,
              rank: 3,
            ),
          ],
        ),
        // Measurement 1: All bowls have greater distances
        MeasurementResult(
          id: 'mock_measurement_1',
          timestamp: DateTime.now().add(Duration(seconds: 1)),
          bowls: [
            BowlMeasurement.mock(
              id: 'bowl_1_0',
              teamName: 'Team A',
              distance: 8.0,
              rank: 1,
            ),
            BowlMeasurement.mock(
              id: 'bowl_1_1',
              teamName: 'Team B',
              distance: 12.0,
              rank: 2,
            ),
          ],
        ),
        // Measurement 2: All bowls have greater distances
        MeasurementResult(
          id: 'mock_measurement_2',
          timestamp: DateTime.now().add(Duration(seconds: 2)),
          bowls: [
            BowlMeasurement.mock(
              id: 'bowl_2_0',
              teamName: 'Team A',
              distance: 10.0,
              rank: 1,
            ),
            BowlMeasurement.mock(
              id: 'bowl_2_1',
              teamName: 'Team B',
              distance: 18.0,
              rank: 2,
            ),
            BowlMeasurement.mock(
              id: 'bowl_2_2',
              teamName: 'Team A',
              distance: 25.0,
              rank: 3,
            ),
          ],
        ),
      ];

      final mockService = MockHistoryService(
        initialMeasurements: mockMeasurements,
      );

      // Arrange: Instantiate the StatsViewModel with the mock service
      final viewModel = StatsViewModel(historyService: mockService);

      // Act: Call loadStats method
      await viewModel.loadStats();

      // Assert: Expect bestBowlDistanceCm to equal 5.0 cm
      // The absolute minimum distance across all bowls is 5.0 cm
      expect(viewModel.bestBowlDistanceCm, equals(5.0));
    });
  });
}
