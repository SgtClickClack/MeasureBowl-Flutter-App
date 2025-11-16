import 'package:flutter_test/flutter_test.dart';
import 'package:lawn_bowls_measure/services/settings_service.dart';
import 'package:lawn_bowls_measure/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('SettingsService', () {
    test('should save and load settings', () async {
      // Arrange: Create a mock AppSettings object
      final mockSettings = AppSettings(
        proAccuracyMode: true,
        measurementUnit: MeasurementUnit.imperial,
        themeMode: AppThemeMode.dark,
      );

      // Act: Instantiate SettingsService and save settings
      final service = SettingsService();
      await service.saveSettings(mockSettings);

      // Act: Load settings
      final loadedSettings = await service.loadSettings();

      // Assert: Expect loadedSettings.themeMode to be AppThemeMode.dark
      expect(loadedSettings.themeMode, equals(AppThemeMode.dark));
      expect(loadedSettings.proAccuracyMode, equals(true));
      expect(loadedSettings.measurementUnit, equals(MeasurementUnit.imperial));
    });

    test('should return default settings if none are saved', () async {
      // Arrange: Ensure SharedPreferences is empty (already done in setUp)

      // Act: Load settings
      final service = SettingsService();
      final loadedSettings = await service.loadSettings();

      // Assert: Expect loadedSettings.themeMode to be AppThemeMode.system (the default)
      expect(loadedSettings.themeMode, equals(AppThemeMode.system));
      expect(loadedSettings.proAccuracyMode, equals(false));
      expect(loadedSettings.measurementUnit, equals(MeasurementUnit.metric));
    });
  });
}
