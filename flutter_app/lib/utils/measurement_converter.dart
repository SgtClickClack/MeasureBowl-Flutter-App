import '../models/app_settings.dart';

/// Utility class for converting and formatting measurements
class MeasurementConverter {
  /// Format distance based on the selected unit
  /// Ensures the distance is properly formatted with only one decimal point
  static String formatDistance(double cm, MeasurementUnit unit) {
    // Ensure cm is a valid number and convert to double if needed
    final double distanceCm = cm.isFinite ? cm : 0.0;

    if (unit == MeasurementUnit.metric) {
      // Format with exactly one decimal place
      return '${distanceCm.toStringAsFixed(1)} cm';
    } else {
      // Imperial conversion
      const inchesPerCm = 0.393701;
      final totalInches = distanceCm * inchesPerCm;
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return '${feet} ft ${inches.toStringAsFixed(1)} in';
    }
  }
}
