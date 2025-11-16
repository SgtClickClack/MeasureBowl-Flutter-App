/// Data model representing a corrected measurement result
///
/// Contains the true, real-world distance of a bowl from the jack
/// after correcting for both lens distortion and perspective distortion.
class CorrectedMeasurement {
  /// Distance from jack in centimeters
  final double distanceInCm;

  /// Color of the bowl (e.g., 'Red', 'Blue', 'Yellow')
  final String bowlColor;

  /// Unique identifier for the bowl
  final int bowlId;

  const CorrectedMeasurement({
    required this.distanceInCm,
    required this.bowlColor,
    required this.bowlId,
  });

  /// Create from JSON map
  factory CorrectedMeasurement.fromJson(Map<String, dynamic> json) {
    return CorrectedMeasurement(
      distanceInCm: (json['distanceInCm'] as num).toDouble(),
      bowlColor: json['bowlColor'] as String,
      bowlId: json['bowlId'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'distanceInCm': distanceInCm,
      'bowlColor': bowlColor,
      'bowlId': bowlId,
    };
  }

  @override
  String toString() {
    return 'CorrectedMeasurement(bowlId: $bowlId, color: $bowlColor, '
        'distance: ${distanceInCm.toStringAsFixed(2)}cm)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CorrectedMeasurement &&
        other.distanceInCm == distanceInCm &&
        other.bowlColor == bowlColor &&
        other.bowlId == bowlId;
  }

  @override
  int get hashCode => Object.hash(distanceInCm, bowlColor, bowlId);
}
