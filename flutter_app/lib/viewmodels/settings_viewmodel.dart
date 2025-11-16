import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

/// Notifier responsible for managing settings state and operations
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _settingsService;

  SettingsNotifier(this._settingsService) : super(AppSettings.defaults());

  /// Initialize the notifier by loading settings from storage
  Future<void> initialize() async {
    try {
      final loadedSettings = await _settingsService.loadSettings();
      state = loadedSettings;
    } catch (e) {
      // On error, keep default settings (already set in super constructor)
      // Could add error handling/logging here if needed
    }
  }

  /// Update pro accuracy mode setting
  Future<void> updateProAccuracy(bool value) async {
    state = state.copyWith(proAccuracyMode: value);
    await _settingsService.saveSettings(state);
  }

  /// Update measurement unit setting
  Future<void> updateMeasurementUnit(MeasurementUnit unit) async {
    state = state.copyWith(measurementUnit: unit);
    await _settingsService.saveSettings(state);
  }

  /// Update theme mode setting
  Future<void> updateThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _settingsService.saveSettings(state);
  }

  /// Update show camera guides setting
  Future<void> updateShowCameraGuides(bool value) async {
    state = state.copyWith(showCameraGuides: value);
    await _settingsService.saveSettings(state);
  }

  /// Update jack diameter setting
  Future<void> updateJackDiameter(double value) async {
    state = state.copyWith(jackDiameterMm: value);
    await _settingsService.saveSettings(state);
  }
}
