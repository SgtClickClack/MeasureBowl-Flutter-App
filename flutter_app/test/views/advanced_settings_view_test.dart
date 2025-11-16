import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/views/advanced_settings_view.dart';
import 'package:lawn_bowls_measure/viewmodels/settings_viewmodel.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
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
  double? jackDiameterCallValue;
  int jackDiameterCallCount = 0;

  @override
  Future<void> updateJackDiameter(double value) async {
    jackDiameterCallValue = value;
    jackDiameterCallCount++;
    state = state.copyWith(jackDiameterMm: value);
  }
}

/// Helper function to create a test widget with AdvancedSettingsView wrapped in providers
Widget createTestWidget(MockSettingsNotifier notifier) {
  return ProviderScope(
    overrides: [
      settingsNotifierProvider.overrideWith((ref) => notifier),
    ],
    child: const MaterialApp(
      home: AdvancedSettingsView(),
    ),
  );
}

void main() {
  group('AdvancedSettingsView', () {
    testWidgets('should display and update Jack Diameter slider',
        (WidgetTester tester) async {
      // Arrange: Create a mock AppSettings with jackDiameterMm = 63.5
      final mockSettings =
          AppSettings.defaults().copyWith(jackDiameterMm: 63.5);
      final mockNotifier = MockSettingsNotifier(mockSettings);

      // Arrange: Pump the AdvancedSettingsView widget
      await tester.pumpWidget(createTestWidget(mockNotifier));

      // Assert 1: Expect to find the "Jack Diameter" Slider widget
      final jackDiameterFinder = find.textContaining('Jack Diameter');
      expect(jackDiameterFinder, findsOneWidget);

      // Act: Find the Slider widget
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Act: Get the slider (Jack Diameter slider)
      final jackSlider = tester.widget<Slider>(sliderFinder);
      final min = jackSlider.min;
      final max = jackSlider.max;
      final targetValue = 64.0;

      // Calculate the tap position needed to reach the target value
      final valueRange = max - min;
      final normalizedValue = (targetValue - min) / valueRange;

      // Get the slider's render box to calculate the tap position
      final sliderBox = tester.getRect(sliderFinder);
      final tapX = sliderBox.left + (normalizedValue * sliderBox.width);

      await tester.tapAt(Offset(tapX, sliderBox.center.dy));
      await tester.pumpAndSettle();

      // Assert 2: Expect mockNotifier.jackDiameterCallCount to be 1
      expect(mockNotifier.jackDiameterCallCount, equals(1));

      // Assert 3: Expect mockNotifier.jackDiameterCallValue to be close to 64.0
      // Note: Due to slider divisions and tap position precision, allow a tolerance of 0.5
      expect(mockNotifier.jackDiameterCallValue, closeTo(64.0, 0.5));
    });
  });
}
