import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/app_settings.dart';

/// Service for managing application settings persistence
class SettingsService {
  static const String _settingsKey = 'app_settings';

  /// Save settings to persistent storage
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, jsonString);
  }

  /// Load settings from persistent storage
  /// Returns default settings if none are saved
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString == null) {
      return AppSettings.defaults();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // Return defaults if data is corrupt
      return AppSettings.defaults();
    }
  }
}
