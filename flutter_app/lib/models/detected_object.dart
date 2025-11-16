/// A data class to hold the detected object's properties.
/// All coordinates are in the 2D pixel space of the original image.
class DetectedObject {
  final double centerX;
  final double centerY;
  final double majorAxis;
  final double minorAxis;
  final double angle;
  final double aspectRatio;
  final double area;

  DetectedObject({
    required this.centerX,
    required this.centerY,
    required this.majorAxis,
    required this.minorAxis,
    required this.angle,
    required this.area,
  }) : aspectRatio = (minorAxis > 0) ? majorAxis / minorAxis : 1.0;

  /// Get the radius assuming a circular object (average of major and minor axes)
  double get radius => (majorAxis + minorAxis) / 2.0;

  @override
  String toString() {
    return 'DetectedObject(center: ($centerX, $centerY), '
        'axes: ($majorAxis, $minorAxis), aspectRatio: ${aspectRatio.toStringAsFixed(2)}, '
        'area: ${area.toStringAsFixed(1)})';
  }
}
