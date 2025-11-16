import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv.dart' as cv;
import '../services/camera_service.dart';
import '../services/detection_config.dart';
import '../services/detection_config_service.dart';

/// ViewModel for one-tap white jack calibration
///
/// Manages camera service and calibration state for white jack detection.
/// When user taps the calibration button, it samples the center pixel and generates
/// HSV ranges automatically for white jack detection.
class TapCalibrationViewModel extends ChangeNotifier {
  final CameraService _cameraService;

  // Calibration state (only white jack)
  List<int>? _whiteLowerHsv;
  List<int>? _whiteUpperHsv;

  // UI state
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _statusMessage;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  CameraController? get controller => _cameraService.controller;
  Future<void>? get initializeControllerFuture =>
      _cameraService.initializeControllerFuture;

  bool get hasWhiteCalibration =>
      _whiteLowerHsv != null && _whiteUpperHsv != null;

  TapCalibrationViewModel({CameraService? cameraService})
      : _cameraService = cameraService ?? CameraService();

  /// Initialize camera for calibration
  Future<void> initialize() async {
    try {
      await _cameraService.initializeCamera();
      _isInitialized = true;
      _errorMessage = null;
      _statusMessage =
          'Point the crosshair at the white jack and tap the button';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Calibrate white jack by sampling center pixel
  Future<void> calibrateWhiteJack() async {
    await _calibrateColor(
      'White Jack',
      (h, s, v) {
        // White has low saturation and high value
        // Hue can be anything, so we keep full range
        _whiteLowerHsv = [
          0, // H: full range
          (s - 25).clamp(0, 255), // S: allow some tolerance
          (v - 30).clamp(0, 255), // V: high value
        ];
        _whiteUpperHsv = [
          179, // H: full range
          (s + 25).clamp(0, 255), // S: low max
          255, // V: max
        ];
      },
    );
  }

  /// Internal method to calibrate a color by sampling center pixel
  Future<void> _calibrateColor(
    String colorName,
    void Function(int h, int s, int v) setRanges,
  ) async {
    if (_isProcessing || !_isInitialized) return;

    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      _errorMessage = 'Camera not ready';
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    _statusMessage = 'Capturing image...';
    notifyListeners();

    final matsToDispose = <cv.Mat>[];

    try {
      // Take picture
      final image = await controller.takePicture();
      final imageBytes = await image.readAsBytes();

      // Decode image
      final originalImage = cv.imdecode(imageBytes, cv.IMREAD_COLOR);
      if (originalImage.isEmpty) {
        throw Exception('Failed to decode image');
      }
      matsToDispose.add(originalImage);

      // Get center coordinates
      final centerX = originalImage.cols ~/ 2;
      final centerY = originalImage.rows ~/ 2;

      // Convert whole image to HSV first
      final hsvImage = cv.cvtColor(originalImage, cv.COLOR_BGR2HSV);
      matsToDispose.add(hsvImage);

      // Sample a 3x3 region around center for better accuracy
      // Calculate mean HSV from a small region to reduce noise
      const roiSize = 3;
      final x1 = (centerX - roiSize ~/ 2).clamp(0, hsvImage.cols - 1);
      final y1 = (centerY - roiSize ~/ 2).clamp(0, hsvImage.rows - 1);
      final x2 = (x1 + roiSize).clamp(0, hsvImage.cols);
      final y2 = (y1 + roiSize).clamp(0, hsvImage.rows);

      // Create a mask for the ROI
      final mask =
          cv.Mat.zeros(hsvImage.rows, hsvImage.cols, cv.MatType.CV_8UC1);
      matsToDispose.add(mask);

      // Draw filled rectangle on mask using Rect
      final rect = cv.Rect(x1, y1, x2 - x1, y2 - y1);
      final color = cv.Scalar.all(255);
      cv.rectangle(mask, rect, color, thickness: cv.FILLED);
      color.dispose();

      // Calculate mean HSV values from the masked region
      final meanScalar = cv.mean(hsvImage, mask: mask);
      final h = meanScalar.val[0].round();
      final s = meanScalar.val[1].round();
      final v = meanScalar.val[2].round();

      debugPrint(
        'Sampled $colorName - Center pixel HSV: H=$h, S=$s, V=$v',
      );

      // Generate HSV ranges
      setRanges(h, s, v);

      _statusMessage = '$colorName calibrated successfully!';
      notifyListeners();

      // Clean up temporary image file
      try {
        final file = File(image.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp image: $e');
      }
    } catch (e) {
      _errorMessage = 'Failed to calibrate $colorName: ${e.toString()}';
      _statusMessage = null;
      debugPrint('Error calibrating $colorName: $e');
      notifyListeners();
    } finally {
      // Dispose all Mat objects
      for (final mat in matsToDispose) {
        try {
          if (!mat.isEmpty) {
            mat.dispose();
          }
        } catch (e) {
          debugPrint('Error disposing Mat: $e');
        }
      }
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Save calibration to DetectionConfigService
  Future<bool> saveCalibration() async {
    if (!hasWhiteCalibration) {
      _errorMessage = 'Please calibrate the white jack before saving';
      notifyListeners();
      return false;
    }

    try {
      // Load existing config or use defaults
      final existingConfig = await DetectionConfigService.loadConfig();
      final hasCustom = await DetectionConfigService.hasCustomConfig();

      // Create new config with calibrated white jack HSV ranges
      // Preserve other detection parameters from existing config if available
      final config = hasCustom
          ? DetectionConfig(
              // Use calibrated white jack HSV values
              whiteLowerHsv: _whiteLowerHsv!,
              whiteUpperHsv: _whiteUpperHsv!,
              // Preserve other detection parameters
              blurKernelSize: existingConfig.blurKernelSize,
              minContourArea: existingConfig.minContourArea,
              maxContourArea: existingConfig.maxContourArea,
              maxAspectRatioForJack: existingConfig.maxAspectRatioForJack,
            )
          : DetectionConfig(
              // Use calibrated white jack HSV values with defaults for other parameters
              whiteLowerHsv: _whiteLowerHsv!,
              whiteUpperHsv: _whiteUpperHsv!,
            );

      final saved = await DetectionConfigService.saveConfig(config);
      if (saved) {
        _statusMessage = 'White jack calibration saved successfully!';
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to save calibration';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error saving calibration: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
