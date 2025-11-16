import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/views/history_view.dart';
import 'package:lawn_bowls_measure/views/results_view.dart';
import 'package:lawn_bowls_measure/viewmodels/history_viewmodel.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/providers/history_notifier_provider.dart';
import 'package:lawn_bowls_measure/providers/settings_notifier_provider.dart';
import 'package:lawn_bowls_measure/services/settings_service.dart';

/// Mock SettingsService for testing
class MockSettingsService extends SettingsService {
  final AppSettings settingsToReturn;
  MockSettingsService({required this.settingsToReturn});

  @override
  Future<AppSettings> loadSettings() async => settingsToReturn;

  @override
  Future<void> saveSettings(AppSettings settings) async {}
}

/// Manual mock of SettingsNotifier for testing
class MockSettingsNotifier extends SettingsNotifier {
  MockSettingsNotifier(this.mockSettings)
      : super(MockSettingsService(settingsToReturn: mockSettings)) {
    state = mockSettings;
  }

  final AppSettings mockSettings;
}

/// Manual mock of HistoryNotifier for testing
class MockHistoryNotifier extends HistoryNotifier {
  MockHistoryNotifier({
    required this.mockIsLoading,
    this.mockErrorMessage,
    required this.mockMeasurements,
  }) : super(MockHistoryService(initialMeasurements: mockMeasurements)) {
    state = HistoryState(
      measurements: mockMeasurements,
      isLoading: mockIsLoading,
      errorMessage: mockErrorMessage,
    );
  }

  final bool mockIsLoading;
  final String? mockErrorMessage;
  final List<MeasurementResult> mockMeasurements;
  final List<String> _deleteMeasurementCalls = [];
  int undoLastDeleteCallCount = 0;

  @override
  Future<void> deleteMeasurement(String measurementId) async {
    _deleteMeasurementCalls.add(measurementId);
    final updatedMeasurements = List<MeasurementResult>.from(state.measurements)
      ..removeWhere((m) => m.id == measurementId);
    state = state.copyWith(measurements: updatedMeasurements);
  }

  @override
  Future<void> undoLastDelete() async {
    undoLastDeleteCallCount++;
    // In a real implementation, this would restore the last deleted measurement
  }

  /// Get the list of IDs that deleteMeasurement was called with
  List<String> get deleteMeasurementCalls => List.from(_deleteMeasurementCalls);

  /// Get the number of times deleteMeasurement was called
  int get deleteMeasurementCallCount => _deleteMeasurementCalls.length;
}

/// Mock HistoryService for testing
class MockHistoryService {
  final List<MeasurementResult> initialMeasurements;
  MockHistoryService({required this.initialMeasurements});
}

/// Helper function to create a test widget with HistoryView wrapped in providers
Widget createTestWidget(MockHistoryNotifier historyNotifier) {
  // Create a default mock SettingsNotifier for tests
  final mockSettings = AppSettings(
    proAccuracyMode: false,
    measurementUnit: MeasurementUnit.metric,
    themeMode: AppThemeMode.system,
  );

  final mockSettingsNotifier = MockSettingsNotifier(mockSettings);

  return ProviderScope(
    overrides: [
      settingsNotifierProvider.overrideWith((ref) => mockSettingsNotifier),
      historyNotifierProvider.overrideWith((ref) => historyNotifier),
    ],
    child: const MaterialApp(
      home: HistoryView(),
    ),
  );
}

void main() {
  group('HistoryView', () {
    testWidgets('should display a loading indicator when loading',
        (WidgetTester tester) async {
      // Arrange: Configure the mock HistoryViewModel with isLoading = true
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: true,
        mockErrorMessage: null,
        mockMeasurements: [],
      );

      // Act: Pump the HistoryView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find one CircularProgressIndicator and zero ListView or error messages
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.textContaining('Error'), findsNothing);
    });

    testWidgets('should display an error message on error',
        (WidgetTester tester) async {
      // Arrange: Configure the mock HistoryViewModel with isLoading = false and errorMessage = 'Test Error'
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: 'Test Error',
        mockMeasurements: [],
      );

      // Act: Pump the HistoryView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find a Text widget with 'Test Error'
      expect(find.text('Test Error'), findsOneWidget);
    });

    testWidgets('should display "No history" when list is empty',
        (WidgetTester tester) async {
      // Arrange: Configure the mock HistoryViewModel with isLoading = false, errorMessage = null, and measurements = []
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [],
      );

      // Act: Pump the HistoryView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find a Text widget with 'No measurement history found'
      expect(find.text('No measurement history found'), findsOneWidget);
    });

    testWidgets('should display a list of measurements when available',
        (WidgetTester tester) async {
      // Arrange: Create a mock list of MeasurementResult objects (2 items)
      // Create a mock MeasurementResult that has a name
      final firstMeasurement = MeasurementResult.createMock().copyWith(
        name: 'Test End 1',
      );
      final secondMeasurement = MeasurementResult.createMock();

      // Configure the MockHistoryViewModel to return this list
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [firstMeasurement, secondMeasurement],
      );

      // Act: Pump the HistoryView widget using the test helper
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find a ListView widget
      expect(find.byType(ListView), findsOneWidget);

      // Assert: Expect to find ListTile widgets with a count equal to the mock list's length (2)
      expect(find.byType(ListTile), findsNWidgets(2));

      // Assert: Expect to find the measurement name
      expect(find.text('Test End 1'), findsOneWidget);

      // Assert: Expect to find Text widgets containing data from the mock measurements
      // Check for bowl count (each mock has 3 bowls)
      expect(find.textContaining('3'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'should call deleteMeasurement on ViewModel when item is swiped',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult with a known ID
      final mockMeasurement = MeasurementResult.createMock();
      final measurementId = mockMeasurement.id;

      // Arrange: Configure the MockHistoryViewModel to have isLoading = false and a measurements list containing this one mock item
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [mockMeasurement],
      );

      // Arrange: Pump the HistoryView using the test helper
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Verify the ListTile exists
      expect(find.byType(ListTile), findsOneWidget);

      // Act: Find the ListTile associated with the mock item
      final listTileFinder = find.byType(ListTile);

      // Act: Simulate a horizontal swipe gesture on that widget
      await tester.drag(listTileFinder, const Offset(-500.0, 0.0));

      // Act: Call pumpAndSettle() to allow animations to complete
      await tester.pumpAndSettle();

      // Assert: Verify that the MockHistoryViewModel's deleteMeasurement method was called once
      expect(mockNotifier.deleteMeasurementCallCount, equals(1));

      // Assert: Verify it was called with the correct measurementId
      expect(mockNotifier.deleteMeasurementCalls, contains(measurementId));
    });

    testWidgets('should show SnackBar with undo button when item is deleted',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult with a known ID
      final mockMeasurement = MeasurementResult.createMock();
      final measurementId = mockMeasurement.id;

      // Arrange: Configure the MockHistoryViewModel to have isLoading = false and a measurements list containing this one mock item
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [mockMeasurement],
      );

      // Arrange: Pump the HistoryView using the test helper (MaterialApp already includes ScaffoldMessenger)
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Verify the ListTile exists
      expect(find.byType(ListTile), findsOneWidget);

      // Act: Find the ListTile associated with the mock item
      final listTileFinder = find.byType(ListTile);

      // Act: Simulate a horizontal swipe gesture on that widget
      await tester.drag(listTileFinder, const Offset(-500.0, 0.0));

      // Act: Call pumpAndSettle() to allow animations to complete
      await tester.pumpAndSettle();

      // Assert: Expect to find one SnackBar widget
      expect(find.byType(SnackBar), findsOneWidget);

      // Assert: Expect the SnackBar to contain Text('Measurement deleted')
      expect(find.text('Measurement deleted'), findsOneWidget);

      // Assert: Expect the SnackBar to contain a TextButton (or similar) with Text('UNDO')
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets(
        'should call undoLastDelete on ViewModel when UNDO button is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult with a known ID
      final mockMeasurement = MeasurementResult.createMock();
      final measurementId = mockMeasurement.id;

      // Arrange: Configure the MockHistoryViewModel to have isLoading = false and a measurements list containing this one mock item
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [mockMeasurement],
      );

      // Arrange: Pump the HistoryView using the test helper (MaterialApp already includes ScaffoldMessenger)
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Verify the ListTile exists
      expect(find.byType(ListTile), findsOneWidget);

      // Act: Find the ListTile associated with the mock item
      final listTileFinder = find.byType(ListTile);

      // Act: Simulate a horizontal swipe gesture on that widget
      await tester.drag(listTileFinder, const Offset(-500.0, 0.0));

      // Act: Call pumpAndSettle() to allow animations to complete and show the SnackBar
      await tester.pumpAndSettle();

      // Assert: Verify the SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);

      // Act: Find the "UNDO" button by text
      final undoButton = find.text('UNDO');

      // Act: Tap the button
      await tester.tap(undoButton);

      // Act: Call pumpAndSettle() to allow animations to complete
      await tester.pumpAndSettle();

      // Assert: Expect mockViewModel.undoLastDeleteCallCount to be 1
      expect(mockNotifier.undoLastDeleteCallCount, equals(1));
    });

    testWidgets(
        'should navigate to ResultsView when measurement item is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult
      final mockMeasurement = MeasurementResult.createMock();

      // Arrange: Configure the MockHistoryViewModel with the mock measurement
      final mockNotifier = MockHistoryNotifier(
        mockIsLoading: false,
        mockErrorMessage: null,
        mockMeasurements: [mockMeasurement],
      );

      // Arrange: Pump the HistoryView using the test helper
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Verify the ListTile exists
      expect(find.byType(ListTile), findsOneWidget);

      // Act: Find and tap the ListTile
      final listTileFinder = find.byType(ListTile);
      await tester.tap(listTileFinder);
      await tester.pumpAndSettle();

      // Assert: Verify that ResultsView is now displayed
      expect(find.byType(ResultsView), findsOneWidget);

      // Assert: Verify that ResultsView received the correct measurement
      final resultsView = tester.widget<ResultsView>(find.byType(ResultsView));
      expect(resultsView.measurementResult.id, equals(mockMeasurement.id));
    });
  });
}
