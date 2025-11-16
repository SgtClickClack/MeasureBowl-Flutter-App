import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving team color calibration data.
///
/// Stores HSV color values for Team A and Team B using shared_preferences.
/// Colors are stored as JSON-encoded lists of doubles: [H, S, V]
class TeamColorService {
  // Storage keys for team colors
  static const String _keyTeamAColor = 'team_a_color_hsv';
  static const String _keyTeamBColor = 'team_b_color_hsv';

  /// Save Team A color HSV values
  ///
  /// [hsv] should be a list of 3 doubles: [H, S, V]
  /// H: 0-179, S: 0-255, V: 0-255 (OpenCV HSV format)
  static Future<void> saveTeamAColor(List<double> hsv) async {
    if (hsv.length != 3) {
      throw ArgumentError('HSV color must have exactly 3 values: [H, S, V]');
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(hsv);
    await prefs.setString(_keyTeamAColor, jsonString);
    debugPrint('[TeamColorService] Saved Team A color: $hsv');
  }

  /// Save Team B color HSV values
  ///
  /// [hsv] should be a list of 3 doubles: [H, S, V]
  /// H: 0-179, S: 0-255, V: 0-255 (OpenCV HSV format)
  static Future<void> saveTeamBColor(List<double> hsv) async {
    if (hsv.length != 3) {
      throw ArgumentError('HSV color must have exactly 3 values: [H, S, V]');
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(hsv);
    await prefs.setString(_keyTeamBColor, jsonString);
    debugPrint('[TeamColorService] Saved Team B color: $hsv');
  }

  /// Retrieve Team A color HSV values
  ///
  /// Returns null if Team A color has not been calibrated yet
  static Future<List<double>?> getTeamAColor() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyTeamAColor);
    if (jsonString == null) {
      return null;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      debugPrint('[TeamColorService] Error decoding Team A color: $e');
      return null;
    }
  }

  /// Retrieve Team B color HSV values
  ///
  /// Returns null if Team B color has not been calibrated yet
  static Future<List<double>?> getTeamBColor() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyTeamBColor);
    if (jsonString == null) {
      return null;
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      debugPrint('[TeamColorService] Error decoding Team B color: $e');
      return null;
    }
  }

  /// Check if both teams have been calibrated
  ///
  /// Returns true if both Team A and Team B colors are saved
  static Future<bool> hasCalibration() async {
    final teamA = await getTeamAColor();
    final teamB = await getTeamBColor();
    return teamA != null && teamB != null;
  }
}
