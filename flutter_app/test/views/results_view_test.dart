import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lawn_bowls_measure/views/results_view.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/models/measurement_result.dart';
import 'package:lawn_bowls_measure/services/measurement_history_service.dart';
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

/// Mock NavigatorObserver to track navigation events
class MockNavigatorObserver extends NavigatorObserver {
  bool hasPopped = false;
  Route<dynamic>? poppedRoute;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    hasPopped = true;
    poppedRoute = route;
    super.didPop(route, previousRoute);
  }
}

/// Helper function to create a test widget with ResultsView wrapped in providers
Widget createTestWidget(
  MockSettingsNotifier notifier,
  MeasurementResult measurementResult, {
  bool isNewResult = false,
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      settingsNotifierProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: ResultsView(
        measurementResult: measurementResult,
        isNewResult: isNewResult,
      ),
    ),
  );
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

  group('ResultsView', () {
    testWidgets('should show Save to History button when isNewResult is true',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with isNewResult: true
      await tester.pumpWidget(
        createTestWidget(mockNotifier, mockResult, isNewResult: true),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect to find the Save button (IconButton with Icons.save)
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets(
        'should NOT show Save to History button when isNewResult is false',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with isNewResult: false (the default)
      await tester.pumpWidget(
        createTestWidget(mockNotifier, mockResult, isNewResult: false),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect NOT to find the Save button
      expect(find.byIcon(Icons.save), findsNothing);
    });

    testWidgets(
        'should save measurement with name when dialog Save button is tapped',
        (WidgetTester tester) async {
      // Arrange: Initialize SharedPreferences with an empty map (already done in setUp)

      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement_save',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with isNewResult: true and the mock measurement
      await tester.pumpWidget(
        createTestWidget(mockNotifier, mockResult, isNewResult: true),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Act: Find the Save button (IconButton with Icons.save) and tap it to open the dialog
      final saveButton = find.byIcon(Icons.save);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Act: Find the TextField in the dialog and enter a name
      await tester.enterText(find.byType(TextField), 'My Test End');

      // Act: Find the 'Save' TextButton in the dialog and tap it
      final dialogSaveButton = find.text('Save');
      expect(dialogSaveButton, findsOneWidget);
      await tester.tap(dialogSaveButton);
      await tester.pumpAndSettle();

      // Assert: Instantiate MeasurementHistoryService and get all measurements
      final history = await MeasurementHistoryService.getAllMeasurements();

      // Assert: Expect history.length to be 1
      expect(history.length, equals(1));

      // Assert: Expect history.first.name to be 'My Test End'
      expect(history.first.name, equals('My Test End'));
    });

    testWidgets('should show Delete button when isNewResult is false',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with isNewResult: false (the default)
      await tester.pumpWidget(
        createTestWidget(mockNotifier, mockResult, isNewResult: false),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect to find the Delete button (IconButton with Icons.delete)
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should delete the measurement when Delete button is tapped',
        (WidgetTester tester) async {
      // Arrange: Initialize SharedPreferences with an empty map (already done in setUp)

      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement_delete',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Manually save this measurement to the history service so it exists
      await MeasurementHistoryService.saveMeasurement(mockResult);

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with isNewResult: false and the mockResult
      await tester.pumpWidget(
        createTestWidget(mockNotifier, mockResult, isNewResult: false),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Act: Find the Delete button (IconButton with Icons.delete)
      final deleteButton = find.byIcon(Icons.delete);
      expect(deleteButton, findsOneWidget);

      // Act: Tap the button
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Assert: Before checking the history, assert that a dialog is now open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Assert: Expect to find the confirmation text
      expect(find.text('Delete this measurement?'), findsOneWidget);

      // Act: Find and tap the 'Delete' button within the dialog
      await tester.tap(find.widgetWithText(TextButton, 'DELETE'));
      await tester.pumpAndSettle();

      // Assert: Instantiate MeasurementHistoryService and get all measurements
      final history = await MeasurementHistoryService.getAllMeasurements();

      // Assert: Expect history.length to be 0 (measurement should be deleted)
      expect(history.length, equals(0));
    });

    testWidgets(
        'should display measurement overlays at the correct coordinates',
        (WidgetTester tester) async {
      // Arrange: Create two mock BowlMeasurements with known coordinates
      // Bowl A: further from jack (20.0 cm)
      final mockBowlA = BowlMeasurement.mock(
        id: 'bowl_a',
        teamName: 'Team A',
        distance: 20.0,
        rank: 1,
        x: 150,
        y: 200,
      );

      // Bowl B: closer to jack (10.0 cm)
      final mockBowlB = BowlMeasurement.mock(
        id: 'bowl_b',
        teamName: 'Team B',
        distance: 10.0,
        rank: 1,
        x: 250,
        y: 300,
      );

      // Arrange: Create a mock MeasurementResult containing both bowls
      final mockResult = MeasurementResult(
        id: 'test_measurement',
        timestamp: DateTime.now(),
        bowls: [mockBowlA, mockBowlB],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the ResultsView with this mock measurement
      await tester.pumpWidget(createTestWidget(mockNotifier, mockResult));

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Assert: Expect find.byType(ListView) to find nothing
      // (ResultsView should not use ListView for measurements anymore)
      expect(find.byType(ListView), findsNothing);

      // Assert: Expect find.byType(Stack) to find at least one widget
      // (ResultsView uses Stack for layout, and we'll add another for overlays)
      expect(find.byType(Stack), findsWidgets);

      // Assert: Expect to find Positioned widgets
      // (These will be used to position measurement overlays on the image)
      expect(find.byType(Positioned), findsWidgets);

      // Assert: The overlays should display ranked text with ordinal format
      // Bowl B is closer (10.0 cm), so it should be rank 1st
      final rankedTextB = find.textContaining('1st');
      final rankedTextBWithDistance = find.textContaining('10.0 cm');
      expect(rankedTextB, findsWidgets);
      expect(rankedTextBWithDistance, findsWidgets);

      // Bowl A is further (20.0 cm), so it should be rank 2nd
      final rankedTextA = find.textContaining('2nd');
      final rankedTextAWithDistance = find.textContaining('20.0 cm');
      expect(rankedTextA, findsWidgets);
      expect(rankedTextAWithDistance, findsWidgets);

      // Assert: The measurement text should NOT be in a SingleChildScrollView
      // (In Green Phase, measurements are displayed as overlays, not in a scrollable list)
      final scrollViewFinder = find.byType(SingleChildScrollView);
      if (scrollViewFinder.evaluate().isNotEmpty) {
        final textInScrollViewB = find.descendant(
          of: scrollViewFinder,
          matching: rankedTextB,
        );
        final textInScrollViewA = find.descendant(
          of: scrollViewFinder,
          matching: rankedTextA,
        );
        // The text should not be in a SingleChildScrollView
        expect(textInScrollViewB, findsNothing);
        expect(textInScrollViewA, findsNothing);
      }

      // Assert: Verify that the ranked text IS in a Positioned widget
      // (In Green Phase, the text should be in a Positioned overlay at coordinates)
      final positionedWidgets = find.byType(Positioned);
      final textInPositionedB = find.descendant(
        of: positionedWidgets,
        matching: rankedTextB,
      );
      final textInPositionedA = find.descendant(
        of: positionedWidgets,
        matching: rankedTextA,
      );
      // This should find the ranked text in Positioned widgets
      expect(textInPositionedB, findsWidgets);
      expect(textInPositionedA, findsWidgets);
    });

    testWidgets('should navigate back when Measure Again button is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock MeasurementResult
      final mockBowl = BowlMeasurement.mock(
        id: 'bowl_1',
        teamName: 'Team A',
        distance: 50.0,
        rank: 1,
        x: 0,
        y: 0,
      );

      final mockResult = MeasurementResult(
        id: 'test_measurement',
        timestamp: DateTime.now(),
        bowls: [mockBowl],
      );

      // Arrange: Configure the MockSettingsViewModel
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.system,
      );

      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Create a MockNavigatorObserver to track navigation
      final mockObserver = MockNavigatorObserver();

      // Arrange: Pump the ResultsView with the navigator observer
      await tester.pumpWidget(
        createTestWidget(
          mockNotifier,
          mockResult,
          navigatorObserver: mockObserver,
        ),
      );

      // Act: Pump to allow the widget to build
      await tester.pump();

      // Act: Find the "Measure Again" button by its text
      final measureAgainButton = find.text('Measure Again');
      expect(measureAgainButton, findsOneWidget);

      // Act: Tap the button
      await tester.tap(measureAgainButton);
      await tester.pumpAndSettle();

      // Assert: Verify that the MockNavigatorObserver recorded a pop event
      expect(mockObserver.hasPopped, isTrue);
    });
  });
}
