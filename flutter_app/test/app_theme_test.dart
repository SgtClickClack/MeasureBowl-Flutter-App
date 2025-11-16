import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/providers/settings_notifier_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'viewmodels/settings_viewmodel_test.dart';

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

  group('LawnBowlsMeasureApp Theme', () {
    testWidgets('should apply Dark theme when settings are set to Dark',
        (WidgetTester tester) async {
      // Arrange: Create mock settings with Dark theme
      final mockSettings = AppSettings(
        proAccuracyMode: false,
        measurementUnit: MeasurementUnit.metric,
        themeMode: AppThemeMode.dark,
      );

      // Arrange: Create MockSettingsService configured to return mockSettings
      final mockService = MockSettingsService(settingsToReturn: mockSettings);

      // Arrange: Create SettingsNotifier with mock service and initialize
      final settingsNotifier = SettingsNotifier(mockService);
      await settingsNotifier.initialize();

      // Arrange: Set up the widget tree with Riverpod ProviderScope
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsNotifierProvider.overrideWith((ref) => settingsNotifier),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(settingsNotifierProvider);
              return MaterialApp(
                title: 'Stand \'n\' Measure',
                debugShowCheckedModeBanner: false,
                themeMode: settings.themeMode.toFlutterThemeMode,
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  primaryColor: Colors.blue[700],
                  scaffoldBackgroundColor: Colors.black,
                ),
                home: const SizedBox(),
              );
            },
          ),
        ),
      );

      // Act: Pump and settle to ensure all frames are processed
      await tester.pumpAndSettle();

      // Assert: Find the MaterialApp widget
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      // Assert: Inspect the MaterialApp's themeMode property
      final materialApp = tester.widget<MaterialApp>(materialAppFinder);
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });
}
