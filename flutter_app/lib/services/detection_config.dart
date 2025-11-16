/// Configuration class for tuning the detection pipeline parameters.
/// These "magic numbers" can be adjusted to adapt to different lighting
/// conditions, camera angles, and environments.
class DetectionConfig {
  // HSV Color Ranges for White Jack
  // White has low saturation and high value. Hue can be anything.
  final List<int> whiteLowerHsv;
  final List<int> whiteUpperHsv;

  // Gaussian Blur Parameters
  final int blurKernelSize; // Must be odd (e.g., 7, 9, 11)

  // Contour Filtering Parameters
  final double minContourArea; // Minimum pixels to be considered valid
  final double maxContourArea; // Maximum pixels to avoid large patches

  // Jack Detection Parameters
  final double
      maxAspectRatioForJack; // Objects with aspect ratio > this are filtered out

  const DetectionConfig({
    // Default HSV ranges for white (H: 0-179, S: 0-255, V: 0-255)
    // White is achromatic: low Saturation (S_Max=25) and high Value (V_Min=200)
    // Hue can be anything (0-179). S_Max=25 ensures nearly colorless, V_Min=200 ensures brightness.
    this.whiteLowerHsv = const [0, 0, 200],
    this.whiteUpperHsv = const [179, 25, 255],
    // Default blur kernel size (must be odd)
    this.blurKernelSize = 7,
    // Default contour area thresholds
    // Lowered to 30.0 to catch real bowls while Hue filter (30-42) blocks background noise
    this.minContourArea = 30.0,
    this.maxContourArea = 50000.0,
    // Default aspect ratio threshold
    this.maxAspectRatioForJack = 1.8,
  });

  /// Create a config optimized for bright, sunny conditions
  factory DetectionConfig.brightSunny() {
    return const DetectionConfig(
      whiteLowerHsv: [0, 0, 200], // High minimum value for bright conditions
      whiteUpperHsv: [179, 25, 255], // Low max saturation for achromatic white
    );
  }

  /// Create a config optimized for shadow/low-light conditions
  factory DetectionConfig.shadow() {
    return const DetectionConfig(
      whiteLowerHsv: [
        0,
        0,
        150
      ], // Lower minimum value for shadows (but still bright enough)
      whiteUpperHsv: [
        179,
        30,
        255
      ], // Slightly higher max saturation for dimmer whites
    );
  }

  /// Create a config with more aggressive noise filtering
  factory DetectionConfig.highNoise() {
    return const DetectionConfig(
      blurKernelSize: 11, // Larger blur for more noise reduction
      minContourArea: 600.0, // Higher minimum area to filter small noise
    );
  }

  /// Create a config for detecting small, distant objects
  factory DetectionConfig.distantObjects() {
    return const DetectionConfig(
      blurKernelSize: 5, // Smaller blur to preserve small objects
      minContourArea: 200.0, // Lower minimum area for small objects
    );
  }
}
