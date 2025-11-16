import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../models/app_settings.dart';
import 'service_providers.dart';

/// Provider for SettingsNotifier that manages app settings state
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  // Get the SettingsService from the service provider
  final settingsService = ref.watch(settingsServiceProvider);

  // Create the notifier with the service
  final notifier = SettingsNotifier(settingsService);

  // Initialize asynchronously to load settings from storage
  // This will update the state once settings are loaded
  notifier.initialize();

  return notifier;
});
