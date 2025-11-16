import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detection_config.dart';

/// Service for storing and retrieving detection configuration
///
/// Stores HSV color ranges for jack detection and other detection parameters
/// using shared preferences for persistence across app sessions.
class DetectionConfigService {
  // Keys for storing HSV ranges (only white for jack detection)
  static const String _keyWhiteLowerHsv = 'detection_white_lower_hsv';
  static const String _keyWhiteUpperHsv = 'detection_white_upper_hsv';
  static const String _keyHasCustomConfig = 'detection_has_custom_config';

  /// Load detection configuration from storage
  ///
  /// Returns the stored config, or default config if none exists
  static Future<DetectionConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCustomConfig = prefs.getBool(_keyHasCustomConfig) ?? false;

      if (!hasCustomConfig) {
        debugPrint('No custom detection config found, using defaults');
        return const DetectionConfig();
      }

      // Load HSV ranges (only white for jack detection)
      final whiteLowerHsv = _loadHsvRange(prefs, _keyWhiteLowerHsv);
      final whiteUpperHsv = _loadHsvRange(prefs, _keyWhiteUpperHsv);

      // Validate all ranges are loaded
      if (whiteLowerHsv == null || whiteUpperHsv == null) {
        debugPrint('Incomplete detection config found, using defaults');
        return const DetectionConfig();
      }

      final config = DetectionConfig(
        whiteLowerHsv: whiteLowerHsv,
        whiteUpperHsv: whiteUpperHsv,
      );

      debugPrint('Detection config loaded successfully');
      return config;
    } catch (e) {
      debugPrint('Error loading detection config: $e');
      return const DetectionConfig();
    }
  }

  /// Save detection configuration to storage
  ///
  /// [config] - The detection configuration to save
  /// Returns true if successful, false otherwise
  static Future<bool> saveConfig(DetectionConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save HSV ranges (only white for jack detection)
      await _saveHsvRange(prefs, _keyWhiteLowerHsv, config.whiteLowerHsv);
      await _saveHsvRange(prefs, _keyWhiteUpperHsv, config.whiteUpperHsv);

      // Mark that we have a custom config
      await prefs.setBool(_keyHasCustomConfig, true);

      debugPrint('Detection config saved successfully');
      return true;
    } catch (e) {
      debugPrint('Error saving detection config: $e');
      return false;
    }
  }

  /// Check if custom detection configuration exists
  ///
  /// Returns true if custom config exists, false otherwise
  static Future<bool> hasCustomConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyHasCustomConfig) ?? false;
    } catch (e) {
      debugPrint('Error checking detection config: $e');
      return false;
    }
  }

  /// Reset to default configuration
  ///
  /// Returns true if successful, false otherwise
  static Future<bool> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHasCustomConfig, false);
      debugPrint('Detection config reset to defaults');
      return true;
    } catch (e) {
      debugPrint('Error resetting detection config: $e');
      return false;
    }
  }

  /// Helper method to load HSV range from preferences
  static List<int>? _loadHsvRange(SharedPreferences prefs, String key) {
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      debugPrint('Error loading HSV range for $key: $e');
      return null;
    }
  }

  /// Helper method to save HSV range to preferences
  static Future<void> _saveHsvRange(
    SharedPreferences prefs,
    String key,
    List<int> range,
  ) async {
    try {
      final jsonString = jsonEncode(range);
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving HSV range for $key: $e');
      rethrow;
    }
  }
}
