import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/views/settings_view.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/providers/settings_notifier_provider.dart';
import 'package:lawn_bowls_measure/services/settings_service.dart';
import 'package:lawn_bowls_measure/widgets/settings_tile.dart';

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
    // Initialize state with mock settings
    state = mockSettings;
  }

  final AppSettings mockSettings;
  bool proAccuracyCallValue = false;
  int proAccuracyCallCount = 0;
  MeasurementUnit? unitCallValue;
  int unitCallCount = 0;
  AppThemeMode? themeModeCallValue;
  int themeModeCallCount = 0;
  bool? cameraGuidesCallValue;
  int cameraGuidesCallCount = 0;
  double? jackDiameterCallValue;
  int jackDiameterCallCount = 0;

  @override
  Future<void> updateProAccuracy(bool value) async {
    proAccuracyCallValue = value;
    proAccuracyCallCount++;
    state = state.copyWith(proAccuracyMode: value);
  }

  @override
  Future<void> updateMeasurementUnit(MeasurementUnit unit) async {
    unitCallValue = unit;
    unitCallCount++;
    state = state.copyWith(measurementUnit: unit);
  }

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {
    themeModeCallValue = mode;
    themeModeCallCount++;
    state = state.copyWith(themeMode: mode);
  }

  @override
  Future<void> updateShowCameraGuides(bool value) async {
    cameraGuidesCallValue = value;
    cameraGuidesCallCount++;
    state = state.copyWith(showCameraGuides: value);
  }

  @override
  Future<void> updateJackDiameter(double value) async {
    jackDiameterCallValue = value;
    jackDiameterCallCount++;
    state = state.copyWith(jackDiameterMm: value);
  }
}

/// NavigatorObserver to track navigation events
class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }
}

/// Mock AboutPage widget for testing navigation
class MockAboutPage extends StatelessWidget {
  const MockAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Stand \'n\' Measure')),
    );
  }
}

/// Mock AdvancedSettingsPage widget for testing navigation
class MockAdvancedSettingsPage extends StatelessWidget {
  const MockAdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Settings')),
      body: const Center(child: Text('Advanced Settings Page')),
    );
  }
}

/// Helper function to create a test widget with SettingsView wrapped in providers
Widget createTestWidget(MockSettingsNotifier notifier,
    {Map<String, WidgetBuilder>? routes}) {
  return ProviderScope(
    overrides: [
      settingsNotifierProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(
      home: const SettingsView(),
      routes: routes ?? {},
    ),
  );
}

void main() {
  group('SettingsView', () {
    // Note: SettingsView doesn't have loading state - it directly displays settings
    // This test is skipped as the view structure has changed

    testWidgets('should display settings when loaded',
        (WidgetTester tester) async {
      // Arrange: Configure the mock SettingsNotifier with default settings
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Act: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find settings sections
      expect(find.text('Measurement Settings'), findsOneWidget);
      expect(find.text('Display Settings'), findsOneWidget);
      expect(find.text('General Settings'), findsOneWidget);
    });

    testWidgets('should update view model when Pro Accuracy switch is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock AppSettings with proAccuracyMode = false
      final mockSettings = AppSettings.defaults();
      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Act: Find the Switch widget within the SettingsTile for 'Pro Accuracy Mode'
      // First find the SettingsTile by its title text, then find the Switch within it
      final settingsTileFinder = find.ancestor(
        of: find.text('Pro Accuracy Mode'),
        matching: find.byType(SettingsTile),
      );
      final switchFinder = find.descendant(
        of: settingsTileFinder,
        matching: find.byType(Switch),
      );

      // Act: Tap the Switch
      await tester.tap(switchFinder);

      // Act: Call pumpAndSettle() to allow animations to complete
      await tester.pumpAndSettle();

      // Assert: Expect mockNotifier.proAccuracyCallCount to be 1
      expect(mockNotifier.proAccuracyCallCount, equals(1));

      // Assert: Expect mockNotifier.proAccuracyCallValue to be true
      expect(mockNotifier.proAccuracyCallValue, equals(true));
    });

    testWidgets('should display Pro Accuracy helper text',
        (WidgetTester tester) async {
      // Arrange: Set up SettingsView with the mock notifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Act: Pump the widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find a Text widget containing the key instructional words
      expect(
        find.textContaining('slower, but more accurate for spread-out heads.'),
        findsOneWidget,
      );
    });

    testWidgets('should update view model when Measurement Unit is changed',
        (WidgetTester tester) async {
      // Arrange: Create a mock AppSettings with measurementUnit = metric
      final mockSettings = AppSettings.defaults();
      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Act: Find the control for 'Measurement Unit' (DropdownButton or similar)
      final unitFinder = find.text('Measurement Unit');
      expect(unitFinder, findsOneWidget);

      // Act: Find and tap the DropdownButton to open it
      final dropdownFinder = find.byType(DropdownButton<MeasurementUnit>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Act: Find and tap the 'Imperial' option
      final imperialFinder = find.text('Imperial');
      await tester.tap(imperialFinder);
      await tester.pumpAndSettle();

      // Assert: Expect mockNotifier.unitCallCount to be 1
      expect(mockNotifier.unitCallCount, equals(1));

      // Assert: Expect mockNotifier.unitCallValue to be MeasurementUnit.imperial
      expect(mockNotifier.unitCallValue, equals(MeasurementUnit.imperial));
    });

    testWidgets('should NOT display the Team Color Calibration button',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect the Team Color Calibration button to NOT be displayed
      // This will fail (Red Phase) because the ListTile with that text still exists in SettingsView
      expect(find.text('Team Color Calibration'), findsNothing);
    });

    testWidgets('should update view model when Theme Mode is changed',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockSettings = AppSettings.defaults();
      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Act: Find the 'Theme Mode' control
      final themeModeFinder = find.text('Theme Mode');
      expect(themeModeFinder, findsOneWidget);

      // Act: Find and tap the DropdownButton for Theme Mode
      final dropdownFinder = find.byType(DropdownButton<AppThemeMode>);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Act: Tap the 'Dark' option
      final darkFinder = find.text('Dark');
      await tester.tap(darkFinder);
      await tester.pumpAndSettle();

      // Assert: Expect mockNotifier.themeModeCallCount to be 1
      expect(mockNotifier.themeModeCallCount, equals(1));

      // Assert: Expect mockNotifier.themeModeCallValue to be AppThemeMode.dark
      expect(mockNotifier.themeModeCallValue, equals(AppThemeMode.dark));
    });

    testWidgets(
        'should update view model when Show Camera Guides switch is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock AppSettings with showCameraGuides = false
      final mockSettings = AppSettings.defaults();
      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Act: Find the Switch widget within the SettingsTile for 'Show Camera Guides'
      // First find the SettingsTile by its title text, then find the Switch within it
      final settingsTileFinder = find.ancestor(
        of: find.text('Show Camera Guides'),
        matching: find.byType(SettingsTile),
      );
      final switchFinder = find.descendant(
        of: settingsTileFinder,
        matching: find.byType(Switch),
      );

      // Act: Tap the Switch
      await tester.tap(switchFinder);

      // Act: Call pumpAndSettle() to allow animations to complete
      await tester.pumpAndSettle();

      // Assert: Expect mockNotifier.cameraGuidesCallCount to be 1
      expect(mockNotifier.cameraGuidesCallCount, equals(1));

      // Assert: Expect mockNotifier.cameraGuidesCallValue to be true
      expect(mockNotifier.cameraGuidesCallValue, equals(true));
    });

    testWidgets('should navigate to AboutPage when About button is tapped',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(
        createTestWidget(
          mockNotifier,
          routes: {
            '/about': (context) => const MockAboutPage(),
          },
        ),
      );

      // Act: Scroll to bring the 'About Stand \'n\' Measure' item into view
      // Find the Scrollable widget (ListView contains a Scrollable)
      final scrollableFinder = find.byType(Scrollable);
      expect(scrollableFinder, findsOneWidget);

      // Scroll until the About item is visible
      await tester.scrollUntilVisible(
        find.text('About Stand \'n\' Measure'),
        500.0,
        scrollable: scrollableFinder,
      );
      await tester.pumpAndSettle();

      // Act: Find the ListTile with 'About Stand \'n\' Measure'
      final aboutFinder = find.text('About Stand \'n\' Measure');
      expect(aboutFinder, findsOneWidget);

      // Act: Tap the ListTile (with warnIfMissed: false to suppress the warning)
      await tester.tap(aboutFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert: Expect to find the MockAboutPage
      expect(find.byType(MockAboutPage), findsOneWidget);
    });

    testWidgets(
        'should NOT display Jack Diameter slider on the main settings page',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find *nothing* for the "Jack Diameter" text
      expect(find.textContaining('Jack Diameter'), findsNothing);
    });

    testWidgets('should display and navigate to Advanced Settings page',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Arrange: Pump the SettingsView widget with routes
      await tester.pumpWidget(
        createTestWidget(
          mockNotifier,
          routes: {
            '/advanced-settings': (context) => const MockAdvancedSettingsPage(),
          },
        ),
      );

      // Assert 1: Expect to find a ListTile with text 'Advanced Settings'
      expect(find.text('Advanced Settings'), findsOneWidget);

      // Act: Tap the 'Advanced Settings' ListTile
      await tester.tap(find.text('Advanced Settings'));
      await tester.pumpAndSettle();

      // Assert 2: Expect to be on the new page
      expect(find.byType(MockAdvancedSettingsPage), findsOneWidget);
    });

    testWidgets(
        'should display component styling and find the SettingsTile structure',
        (WidgetTester tester) async {
      // Arrange: Create a mock SettingsNotifier
      final mockNotifier = MockSettingsNotifier(AppSettings.defaults());

      // Arrange: Pump the SettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert: Expect to find the SettingsTile widget
      // This will fail (Red Phase) because SettingsView currently uses raw ListTile widgets,
      // not the new SettingsTile component
      expect(find.byType(SettingsTile), findsWidgets);
    });
  });
}
