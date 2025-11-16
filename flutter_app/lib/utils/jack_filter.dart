import 'dart:math' as math;
import '../models/detected_object.dart';

/// Calculates the standard deviation of a list of radii.
double _radiusStdDev(Iterable<double> radii) {
  if (radii.length <= 1) return 0.0;

  final mean = radii.reduce((a, b) => a + b) / radii.length;
  final variance =
      radii.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) /
          radii.length;

  return math.sqrt(variance);
}

/// Filters out objects that are too close to the jack candidate using Euclidean distance.
///
/// This function uses vector math to calculate the center-to-center distance between
/// the jack and each bowl, then excludes any bowl whose center falls within the
/// exclusion radius (jack radius + bowl radius + tolerance).
///
/// The tolerance is dynamically calculated as 2 standard deviations of all object
/// radii, ensuring robust filtering across varying object sizes.
///
/// @param detections List of all detected objects (including the jack)
/// @param jackCandidate The detected jack object
/// @param tolerancePixels Optional fixed tolerance in pixels. If null, uses 2σ of radii.
/// @return List of bowls with the jack and overlapping objects filtered out
List<DetectedObject> filterJack(
  List<DetectedObject> detections,
  DetectedObject jackCandidate, {
  double? tolerancePixels,
}) {
  if (detections.isEmpty) return const [];

  // Separate jack from other objects
  final others = detections
      .where(
        (obj) =>
            obj.centerX != jackCandidate.centerX ||
            obj.centerY != jackCandidate.centerY,
      )
      .toList(growable: false);

  if (others.isEmpty) return const [];

  // Calculate dynamic tolerance based on object size distribution
  final radii = [...others.map((obj) => obj.radius), jackCandidate.radius];

  final sigmaTerm = tolerancePixels ??
      math.max(
        jackCandidate.radius * 0.15, // Minimum 15% of jack radius
        _radiusStdDev(radii) * 2.0, // Or 2 standard deviations
      );

  // Filter out objects whose centers are too close to the jack
  return others.where((obj) {
    final dx = obj.centerX - jackCandidate.centerX;
    final dy = obj.centerY - jackCandidate.centerY;
    final centerDistance = math.sqrt(dx * dx + dy * dy);

    // Exclusion radius: jack radius + bowl radius + tolerance
    final exclusionRadius = jackCandidate.radius + obj.radius + sigmaTerm;

    return centerDistance > exclusionRadius;
  }).toList(growable: false);
}
