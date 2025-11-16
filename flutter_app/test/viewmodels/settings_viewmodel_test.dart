import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lawn_bowls_measure/services/settings_service.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:lawn_bowls_measure/providers/settings_notifier_provider.dart';
import 'package:lawn_bowls_measure/providers/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock service for testing SettingsNotifier
class MockSettingsService extends SettingsService {
  final bool shouldThrowError;
  final Exception? errorToThrow;
  AppSettings? _settingsToReturn;
  final List<AppSettings> _saveSettingsCalls = [];

  MockSettingsService({
    this.shouldThrowError = false,
    this.errorToThrow,
    AppSettings? settingsToReturn,
  }) : _settingsToReturn = settingsToReturn;

  /// Set the settings to return when loadSettings is called
  void setSettingsToReturn(AppSettings settings) {
    _settingsToReturn = settings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    if (shouldThrowError) {
      throw errorToThrow ?? Exception('Mock error: Failed to save settings');
    }
    _saveSettingsCalls.add(settings);
  }

  @override
  Future<AppSettings> loadSettings() async {
    if (shouldThrowError) {
      throw errorToThrow ?? Exception('Mock error: Failed to load settings');
    }
    return _settingsToReturn ?? AppSettings.defaults();
  }

  /// Get the list of settings that saveSettings was called with
  List<AppSettings> get saveSettingsCalls => List.from(_saveSettingsCalls);

  /// Get the number of times saveSettings was called
  int get saveSettingsCallCount => _saveSettingsCalls.length;
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

  group('SettingsNotifier', () {
    test('should load settings from service on initialize', () async {
      // Arrange: Create mock settings to return
      final mockSettings = AppSettings(
        proAccuracyMode: true,
        measurementUnit: MeasurementUnit.imperial,
        themeMode: AppThemeMode.dark,
      );

      // Arrange: Create MockSettingsService configured to return mockSettings
      final mockService = MockSettingsService(settingsToReturn: mockSettings);

      // Arrange: Create ProviderContainer with overridden service provider
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Arrange: Get the notifier from the container
      final notifier = container.read(settingsNotifierProvider.notifier);

      // Act: Initialize the notifier
      await notifier.initialize();

      // Assert: Expect the state to match the settings from the mock service
      final state = container.read(settingsNotifierProvider);
      expect(state.proAccuracyMode, equals(mockSettings.proAccuracyMode));
      expect(state.measurementUnit, equals(mockSettings.measurementUnit));
      expect(state.themeMode, equals(mockSettings.themeMode));

      // Cleanup
      container.dispose();
    });

    test('should update notifier when Pro Accuracy switch is tapped', () async {
      // Arrange: Create MockSettingsService
      final mockService = MockSettingsService();

      // Arrange: Create ProviderContainer with overridden service provider
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Arrange: Get the notifier and initialize it
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.initialize();

      // Act: Call updateProAccuracy
      await notifier.updateProAccuracy(true);

      // Assert: Verify that mockService.saveSettings() was called once
      expect(mockService.saveSettingsCallCount, equals(1));

      // Assert: Verify that the AppSettings object passed to saveSettings has proAccuracyMode = true
      final savedSettings = mockService.saveSettingsCalls.first;
      expect(savedSettings.proAccuracyMode, equals(true));

      // Assert: Verify the state was updated
      final state = container.read(settingsNotifierProvider);
      expect(state.proAccuracyMode, equals(true));

      // Cleanup
      container.dispose();
    });

    test('should update and save showCameraGuides setting', () async {
      // Arrange: Create MockSettingsService
      final mockService = MockSettingsService();

      // Arrange: Create ProviderContainer with overridden service provider
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Arrange: Get the notifier and initialize it
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.initialize();

      // Act: Call updateShowCameraGuides
      await notifier.updateShowCameraGuides(true);

      // Assert: Expect the state to have showCameraGuides = true
      final state = container.read(settingsNotifierProvider);
      expect(state.showCameraGuides, equals(true));

      // Assert: Expect the MockSettingsService to have saveSettings called once
      expect(mockService.saveSettingsCallCount, equals(1));

      // Assert: Verify the saved settings object has showCameraGuides = true
      final savedSettings = mockService.saveSettingsCalls.first;
      expect(savedSettings.showCameraGuides, equals(true));

      // Cleanup
      container.dispose();
    });

    test('should update and save jackDiameterMm setting', () async {
      // Arrange: Create MockSettingsService
      final mockService = MockSettingsService();

      // Arrange: Create ProviderContainer with overridden service provider
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(mockService),
        ],
      );

      // Arrange: Get the notifier and initialize it
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.initialize();

      // Act: Call updateJackDiameter
      await notifier.updateJackDiameter(63.5);

      // Assert: Expect the state to have jackDiameterMm = 63.5
      final state = container.read(settingsNotifierProvider);
      expect(state.jackDiameterMm, equals(63.5));

      // Assert: Expect the MockSettingsService to have saveSettings called once
      expect(mockService.saveSettingsCallCount, equals(1));

      // Assert: Verify the saved settings object has jackDiameterMm = 63.5
      final savedSettings = mockService.saveSettingsCalls.first;
      expect(savedSettings.jackDiameterMm, equals(63.5));

      // Cleanup
      container.dispose();
    });
  });
}
