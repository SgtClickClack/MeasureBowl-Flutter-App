import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../services/measurement_history_service.dart';

/// Provider for SettingsService singleton
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// Provider for MeasurementHistoryService singleton
/// Note: MeasurementHistoryService uses static methods, but we provide
/// an instance for consistency and potential future refactoring
final historyServiceProvider = Provider<MeasurementHistoryService>((ref) {
  return MeasurementHistoryService();
});
