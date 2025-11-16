import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/measurement_result.dart';

/// Service for managing measurement history (persistent storage of measurements)
class MeasurementHistoryService {
  static const String _historyKey = 'measurement_history';
  static const int _maxHistorySize =
      100; // Maximum number of measurements to store

  /// Save a measurement to history
  /// Returns true if successful, false otherwise
  static Future<bool> saveMeasurement(MeasurementResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current list of measurement strings
      final existingList = prefs.getStringList(_historyKey) ?? [];

      // Convert result to JSON string
      final jsonString = jsonEncode(result.toJson());

      // Add new measurement to the list
      existingList.add(jsonString);

      // Enforce max history size (remove oldest if needed)
      if (existingList.length > _maxHistorySize) {
        existingList.removeAt(0); // Remove oldest (first in list)
      }

      // Save updated list back to SharedPreferences
      final success = await _saveHistory(existingList);

      if (success) {
        debugPrint(
          '[MeasurementHistoryService] Saved measurement: ${result.id}',
        );
      }

      return success;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error saving measurement: $e',
      );
      return false;
    }
  }

  /// Private helper: Get and parse measurement history from SharedPreferences
  /// Returns unsorted list of MeasurementResult objects
  static Future<List<MeasurementResult>> _getParsedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get list of measurement strings
      final measurementStrings = prefs.getStringList(_historyKey);

      // If null or empty, return empty list
      if (measurementStrings == null || measurementStrings.isEmpty) {
        return [];
      }

      // Parse each string and create MeasurementResult objects
      final measurements = <MeasurementResult>[];
      for (final jsonString in measurementStrings) {
        try {
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          final measurement = MeasurementResult.fromJson(jsonMap);
          measurements.add(measurement);
        } catch (e) {
          debugPrint(
            '[MeasurementHistoryService] Error parsing measurement: $e',
          );
          // Skip invalid entries
        }
      }

      return measurements;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error retrieving measurements: $e',
      );
      return [];
    }
  }

  /// Private helper: Save measurement history string list to SharedPreferences
  /// Returns true if successful, false otherwise
  static Future<bool> _saveHistory(List<String> measurementStrings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success =
          await prefs.setStringList(_historyKey, measurementStrings);
      return success;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error saving history: $e',
      );
      return false;
    }
  }

  /// Get all saved measurements, sorted by timestamp (newest first)
  static Future<List<MeasurementResult>> getAllMeasurements() async {
    try {
      final measurements = await _getParsedHistory();
      // Sort by timestamp (newest first)
      measurements.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return measurements;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error retrieving measurements: $e',
      );
      return [];
    }
  }

  /// Get a specific measurement by ID
  /// Returns null if not found
  static Future<MeasurementResult?> getMeasurement(String id) async {
    try {
      // Get parsed measurements and find the one with matching ID
      final measurements = await _getParsedHistory();
      try {
        return measurements.firstWhere((measurement) => measurement.id == id);
      } catch (e) {
        // firstWhere throws if no match found, return null
        return null;
      }
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error getting measurement by ID: $e',
      );
      return null;
    }
  }

  /// Delete a measurement by ID
  /// Returns true if deleted, false if not found
  static Future<bool> deleteMeasurement(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current list of measurement strings
      final measurementStrings = prefs.getStringList(_historyKey);

      // If null or empty, nothing to delete
      if (measurementStrings == null || measurementStrings.isEmpty) {
        return false;
      }

      // Use parsed history to check if measurement exists
      final parsedMeasurements = await _getParsedHistory();
      final measurementExists = parsedMeasurements.any(
        (measurement) => measurement.id == id,
      );

      // If measurement doesn't exist, return false
      if (!measurementExists) {
        return false;
      }

      // Find the index in the string list by parsing and comparing IDs
      int? indexToDelete;
      for (int i = 0; i < measurementStrings.length; i++) {
        try {
          final jsonMap =
              jsonDecode(measurementStrings[i]) as Map<String, dynamic>;
          final measurement = MeasurementResult.fromJson(jsonMap);
          if (measurement.id == id) {
            indexToDelete = i;
            break;
          }
        } catch (e) {
          // Skip invalid entries
          debugPrint(
            '[MeasurementHistoryService] Error parsing measurement during delete: $e',
          );
        }
      }

      // If not found in string list (shouldn't happen if parsed history found it), return false
      if (indexToDelete == null) {
        return false;
      }

      // Remove the measurement from the list
      measurementStrings.removeAt(indexToDelete);

      // Save the updated list back to SharedPreferences
      final success = await _saveHistory(measurementStrings);

      if (success) {
        debugPrint(
          '[MeasurementHistoryService] Deleted measurement: $id',
        );
      }

      return success;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error deleting measurement: $e',
      );
      return false;
    }
  }

  /// Clear all measurement history
  static Future<void> clearAllMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      debugPrint('[MeasurementHistoryService] Cleared all measurements');
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error clearing all measurements: $e',
      );
    }
  }

  /// Get the count of saved measurements
  static Future<int> getMeasurementCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final measurementStrings = prefs.getStringList(_historyKey);
      return measurementStrings?.length ?? 0;
    } catch (e) {
      debugPrint(
        '[MeasurementHistoryService] Error getting measurement count: $e',
      );
      return 0;
    }
  }
}
