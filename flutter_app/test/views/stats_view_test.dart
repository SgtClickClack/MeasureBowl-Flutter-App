import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lawn_bowls_measure/views/stats_view.dart';
import 'package:lawn_bowls_measure/viewmodels/stats_viewmodel.dart';

/// Manual mock of StatsViewModel for testing
class MockStatsViewModel extends StatsViewModel {
  MockStatsViewModel({
    required this.mockTotalBowls,
    required this.mockOverallAvg,
    required this.mockAvgBestBowl,
    required this.mockBestBowl,
  });

  final int mockTotalBowls;
  final double mockOverallAvg;
  final double mockAvgBestBowl;
  final double mockBestBowl;

  @override
  int get totalBowls => mockTotalBowls;

  @override
  double get averageDistanceCm => mockOverallAvg;

  @override
  double get averageBestBowlDistanceCm => mockAvgBestBowl;

  @override
  double get bestBowlDistanceCm => mockBestBowl;
}

/// Helper function to create a test widget with StatsView wrapped in provider
Widget createTestWidget(StatsViewModel viewModel) {
  return MaterialApp(
    home: ChangeNotifierProvider<StatsViewModel>.value(
      value: viewModel,
      child: const StatsView(),
    ),
  );
}

void main() {
  group('StatsView', () {
    testWidgets('should display all four core performance metrics',
        (WidgetTester tester) async {
      // Arrange: Create a mock StatsViewModel with fixed, known values
      final mockViewModel = MockStatsViewModel(
        mockTotalBowls: 20,
        mockOverallAvg: 30.0,
        mockAvgBestBowl: 10.0,
        mockBestBowl: 5.0,
      );

      // Act: Pump the StatsView widget with the mock data
      await tester.pumpWidget(createTestWidget(mockViewModel));

      // Assert: Expect to find all four metric labels with their values
      expect(find.text('Total Bowls Measured: 20'), findsOneWidget);
      expect(find.text('Overall Average: 30.0 cm'), findsOneWidget);
      expect(find.textContaining('Consistency Avg: 10.0 cm'), findsOneWidget);
      expect(find.textContaining('Personal Best: 5.0 cm'), findsOneWidget);
    });
  });
}
