import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/measurement_result.dart';
import '../services/cache_service.dart';
import '../services/camera_service.dart';
import '../services/image_compression_service.dart';
import '../services/image_processor.dart';
import '../utils/error_handler.dart';

/// Result object returned by [CameraViewModel.startImageProcessing].
class CameraCaptureResult {
  const CameraCaptureResult({
    this.measurement,
    this.message,
    this.isError = false,
    this.usedFallback = false,
  });

  final MeasurementResult? measurement;
  final String? message;
  final bool isError;
  final bool usedFallback;

  bool get hasMeasurement => measurement != null;
}

/// View model responsible for orchestrating camera lifecycle and measurement flow.
class CameraViewModel extends ChangeNotifier {
  CameraViewModel({CameraService? cameraService})
      : _cameraService = cameraService ?? CameraService();

  final CameraService _cameraService;

  bool _isInitialized = false;
  bool _isMeasuring = false;
  bool _isProcessing = false;
  bool _showCameraPreview = true;
  bool _isAppInForeground = true;
  bool _disposed = false;
  String? _statusMessage;
  bool _isOperationInProgress = false;

  CameraController? get controller => _cameraService.controller;
  Future<void>? get initializeControllerFuture =>
      _cameraService.initializeControllerFuture;

  bool get isInitialized => _isInitialized;
  bool get isMeasuring => _isMeasuring;
  bool get isProcessing => _isProcessing;
  bool get showCameraPreview => _showCameraPreview;
  bool get isAppInForeground => _isAppInForeground;
  String? get statusMessage => _statusMessage;

  /// Initialize cache and camera permission/camera controller.
  Future<void> initialize() async {
    try {
      await CacheService.initialize();
    } catch (error) {
      _setStatusMessage(ErrorHandler.getErrorMessage(error));
    }

    await _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      await _initializeCamera();
      return;
    }

    if (status.isDenied || status.isRestricted) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        await _initializeCamera();
      } else {
        _setStatusMessage(
          'Camera permission is required. Please enable it in Settings.',
        );
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      _setStatusMessage(
        'Camera permission permanently denied. Enable it in Settings.',
      );
    }
  }

  Future<void> _initializeCamera() async {
    // Only skip if we're CERTAIN the app is not in foreground
    // On app startup, _isAppInForeground starts as true, so this won't block initial init
    if (!_isAppInForeground) {
      debugPrint(
          "CameraViewModel: App is not in foreground, skipping initialization.");
      return;
    }

    debugPrint("CameraViewModel: Starting camera initialization...");

    final initResult = await ErrorHandler.safeAsync(
      () => _cameraService.initializeCamera(),
      'CameraViewModel._initializeCamera',
    );

    if (initResult.isSuccess) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      _setInitialized(true);
      _setShowCameraPreview(true);
    } else {
      _setInitialized(false);
      _setShowCameraPreview(false);
      _setStatusMessage(initResult.error);
    }
  }

  /// Handle lifecycle changes from the hosting widget.
  Future<void> handleLifecycleChange(AppLifecycleState state) async {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      _setIsAppInForeground(true);
      debugPrint("App resumed - re-initializing camera");
      // This is the fix. Call initializeCamera() here.
      await _initializeCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setIsAppInForeground(false);
      // Pause camera when app goes to background to prevent access issues
      await _cameraService.pauseCamera();
    }
  }

  /// Start image processing with optional pro accuracy mode.
  ///
  /// [proAccuracyMode] enables high-accuracy processing when true.
  /// [manualJackPosition] is the manually selected jack position from user tap.
  /// [jackDiameterMm] is the jack diameter in millimeters for measurement calculations.
  Future<CameraCaptureResult> startImageProcessing({
    bool proAccuracyMode = false,
    Offset? manualJackPosition,
    double jackDiameterMm = 63.5,
  }) async {
    // Atomic check-and-set to prevent race condition
    if (_isOperationInProgress) {
      return const CameraCaptureResult(
        message: 'Measurement already in progress.',
        isError: true,
      );
    }
    _isOperationInProgress = true;

    try {
      if (!_isAppInForeground) {
        return const CameraCaptureResult(
          message:
              'Please bring the app to the foreground to take a measurement.',
          isError: true,
        );
      }

      final controller = _cameraService.controller;
      if (controller == null) {
        return const CameraCaptureResult(
          message: 'Camera not ready. Please wait for initialization.',
          isError: true,
        );
      }

      if (!controller.value.isInitialized) {
        try {
          await _cameraService.initializeControllerFuture;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        } catch (error) {
          return CameraCaptureResult(
            message: ErrorHandler.getErrorMessage(error),
            isError: true,
          );
        }
      }

      if (!(_cameraService.controller?.value.isInitialized ?? false)) {
        return const CameraCaptureResult(
          message: 'Camera still initializing. Please try again.',
          isError: true,
        );
      }

      _setShowCameraPreview(false);
      _setIsMeasuring(true);

      // Wait for UI to update and camera buffers to be released
      await _waitForNextFrame();
      // Increased delay to ensure camera preview buffers are fully released
      // This prevents "Unable to acquire buffer" crashes on some devices
      await Future<void>.delayed(const Duration(milliseconds: 300));

      String filePath;

      try {
        filePath = await _cameraService.takePicture();
      } catch (error) {
        _resetCaptureState();
        // Log the error for debugging
        debugPrint('Camera capture error: $error');
        return CameraCaptureResult(
          message: ErrorHandler.getErrorMessage(error),
          isError: true,
        );
      }

      _setIsMeasuring(false);
      _setIsProcessing(true);

      final cachedResult = await CacheService.getCachedMeasurementResult(
        filePath,
      );
      if (cachedResult != null) {
        _setIsProcessing(false);
        _setShowCameraPreview(true);
        return CameraCaptureResult(
          measurement: ImageProcessor.createMeasurementResult(cachedResult),
          message: 'Loaded cached measurement.',
        );
      }

      String processedImagePath = filePath;
      try {
        processedImagePath = await ImageCompressionService.compressImage(
          filePath,
        );
      } catch (error) {
        debugPrint('Image compression failed, using original image: $error');
        processedImagePath = filePath;
      }

      Map<String, dynamic>? processingResult;

      try {
        final Uint8List imageBytes =
            await File(processedImagePath).readAsBytes();
        processingResult = await ImageProcessor.processImageBytes(
          imageBytes,
          processedImagePath,
          proAccuracyMode: proAccuracyMode,
          manualJackPosition: manualJackPosition,
          jackDiameterMm: jackDiameterMm,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            return {
              'success': false,
              'error':
                  'Image processing timed out. The image may be too large or complex.',
            };
          },
        );
      } catch (error, stackTrace) {
        debugPrint('Image processing failed with exception: $error');
        debugPrint('Stack trace: $stackTrace');
        processingResult = {
          'success': false,
          'error': 'Image processing failed: ${error.toString()}',
        };
      }

      _setIsProcessing(false);

      final bool didSucceed =
          processingResult != null && processingResult['success'] == true;

      if (!didSucceed) {
        _setShowCameraPreview(true);
        final fallbackResult = MeasurementResult.fromCapturedImage(
          imagePath: filePath,
        );
        final String errorMessage =
            (processingResult != null && processingResult!['error'] != null)
                ? processingResult!['error'].toString()
                : 'Unknown error during processing.';

        return CameraCaptureResult(
          measurement: fallbackResult,
          message: 'Failed to process image: $errorMessage',
          isError: true,
          usedFallback: true,
        );
      }

      final Map<String, dynamic> successfulResult = processingResult!;
      await CacheService.cacheMeasurementResult(filePath, successfulResult);

      _setShowCameraPreview(true);
      return CameraCaptureResult(
        measurement: ImageProcessor.createMeasurementResult(successfulResult),
      );
    } finally {
      // Always reset the operation flag and state flags
      _isOperationInProgress = false;
      _setIsMeasuring(false);
      _setIsProcessing(false);
    }
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }

  void _resetCaptureState() {
    _setIsMeasuring(false);
    _setIsProcessing(false);
    _setShowCameraPreview(true);
  }

  void _setInitialized(bool value) {
    if (_isInitialized == value) return;
    _isInitialized = value;
    _notifyListeners();
  }

  void _setIsMeasuring(bool value) {
    if (_isMeasuring == value) return;
    _isMeasuring = value;
    _notifyListeners();
  }

  void _setIsProcessing(bool value) {
    if (_isProcessing == value) return;
    _isProcessing = value;
    _notifyListeners();
  }

  void _setShowCameraPreview(bool value) {
    if (_showCameraPreview == value) return;
    _showCameraPreview = value;
    _notifyListeners();
  }

  void _setIsAppInForeground(bool value) {
    if (_isAppInForeground == value) return;
    _isAppInForeground = value;
    _notifyListeners();
  }

  void _setStatusMessage(String? message) {
    _statusMessage = message;
    _notifyListeners();
  }

  void clearStatusMessage() {
    if (_statusMessage == null) {
      return;
    }
    _statusMessage = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cameraService.dispose();
    super.dispose();
  }
}
