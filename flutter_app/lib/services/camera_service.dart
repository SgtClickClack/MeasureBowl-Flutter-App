import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart'
    show CameraException;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/error_handler.dart' hide CameraException;

/// Service class for managing camera operations
class CameraService {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;
  Future<void>? get initializeControllerFuture => _initializeControllerFuture;
  List<CameraDescription>? get cameras => _cameras;

  /// Initialize camera controller
  Future<void> initializeCamera() async {
    // Check if app is in foreground before initializing camera
    // Android blocks camera access when app is in background
    // In release builds, if we can't determine lifecycle state, proceed with initialization
    try {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      // Only block if we're CERTAIN the app is not in foreground
      // If lifecycleState is null or unavailable, proceed (app likely just started)
      if (lifecycleState != null &&
          lifecycleState != AppLifecycleState.resumed) {
        debugPrint(
            "CameraService: App is not in foreground, skipping initialization.");
        return;
      }
    } catch (e) {
      // If we can't check lifecycle state, proceed with initialization
      // This is safe because the camera will fail gracefully if not available
      if (kDebugMode) {
        debugPrint(
          'CameraService: Could not check app lifecycle state, proceeding: $e',
        );
      }
      // Continue with initialization - don't block on lifecycle check failure
    }

    return ErrorHandler.withErrorHandling(() async {
      debugPrint('CameraService: Starting camera initialization...');

      // Get list of available cameras with timeout
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('CameraService: availableCameras() timed out');
          throw CameraException(
            'CAMERA_NOT_AVAILABLE',
            'Failed to detect cameras. Please try again.',
          );
        },
      );

      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('CameraService: No cameras found');
        throw CameraException(
          'CAMERA_NOT_AVAILABLE',
          'No cameras available on this device',
        );
      }

      debugPrint('CameraService: Found ${_cameras!.length} camera(s)');

      // Select the first back camera (or first camera if no back camera)
      CameraDescription selectedCamera = _cameras!.first;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      debugPrint(
        'CameraService: Selected camera: ${selectedCamera.name} (${selectedCamera.lensDirection})',
      );

      // Create and initialize the camera controller
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false, // Don't need audio for photos
      );

      debugPrint(
        'CameraService: CameraController created, starting initialization...',
      );

      // Create and await the initialization future with timeout
      _initializeControllerFuture = _controller!.initialize();

      try {
        await _initializeControllerFuture!.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint(
              'CameraService: Camera initialization timed out after 15 seconds',
            );
            throw CameraException(
              'CAMERA_INITIALIZATION_FAILED',
              'Camera initialization timed out. The camera may be in use by another app.',
            );
          },
        );
        debugPrint('CameraService: Camera initialized successfully');
      } catch (e) {
        debugPrint('CameraService: Camera initialization failed: $e');
        // Dispose the controller if initialization failed
        try {
          await _controller?.dispose();
        } catch (_) {
          // Ignore disposal errors
        }
        _controller = null;
        _initializeControllerFuture = null;
        rethrow;
      }
    }, 'CameraService.initializeCamera');
  }

  /// Take a picture and save it to the app directory
  Future<String> takePicture() async {
    // Comprehensive state validation before taking picture
    if (_controller == null) {
      throw CameraException(
        'CAMERA_INITIALIZATION_FAILED',
        'Camera controller is null',
      );
    }

    // Wait for camera to fully initialize before proceeding
    if (_initializeControllerFuture != null) {
      try {
        await _initializeControllerFuture;
      } catch (e) {
        throw CameraException(
          'CAMERA_INITIALIZATION_FAILED',
          'Camera initialization failed: ${e.toString()}',
        );
      }
    }

    // Double-check controller state after waiting
    if (!_controller!.value.isInitialized) {
      throw CameraException(
        'CAMERA_INITIALIZATION_FAILED',
        'Camera controller not initialized after waiting',
      );
    }

    // Check if camera is already taking a picture (prevent concurrent captures)
    if (_controller!.value.isTakingPicture) {
      throw CameraException(
        'CAMERA_BUSY',
        'Camera is already taking a picture. Please wait.',
      );
    }

    // Additional validation: ensure camera is not disposed
    if (_controller!.value.hasError) {
      throw CameraException(
        'CAMERA_ERROR',
        'Camera has an error: ${_controller!.value.errorDescription}',
      );
    }

    return ErrorHandler.withErrorHandling(() async {
      // Get the pictures directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dirPath = path.join(appDir.path, 'Pictures');
      await Directory(dirPath).create(recursive: true);

      // Create unique filename with timestamp
      final String fileName =
          'lawn_bowls_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(dirPath, fileName);

      // Final state check right before native call
      if (_controller == null || !_controller!.value.isInitialized) {
        throw CameraException(
          'CAMERA_INITIALIZATION_FAILED',
          'Camera state changed before taking picture',
        );
      }

      // Take picture - this is the native call that might crash
      // NOTE: CameraPreview widget should be hidden BEFORE this call
      // to prevent accessing the closed stream during capture
      final XFile imageFile = await _controller!.takePicture();

      // Validate the captured image file exists
      if (!await File(imageFile.path).exists()) {
        throw CameraException(
          'CAMERA_CAPTURE_FAILED',
          'Captured image file does not exist',
        );
      }

      // Copy the image to our directory
      await imageFile.saveTo(filePath);

      // Verify the saved file exists
      final savedFile = File(filePath);
      if (!await savedFile.exists()) {
        throw CameraException(
          'CAMERA_SAVE_FAILED',
          'Failed to save image to app directory',
        );
      }

      return filePath;
    }, 'CameraService.takePicture');
  }

  /// Pause camera when app goes to background
  /// This prevents Android from blocking camera access when app is inactive
  Future<void> pauseCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Stop the camera preview to release resources
      // This helps prevent Android from blocking camera access when app is backgrounded
      await _controller!.pausePreview();
      debugPrint('Camera preview paused');
    } catch (e) {
      // Log but don't throw - pausing should be safe
      // Some camera controllers may not support pausePreview, which is fine
      if (kDebugMode) {
        debugPrint('Error pausing camera (may not be supported): $e');
      }
    }
  }

  /// Resume camera when app returns to foreground
  Future<void> resumeCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Resume the camera preview
      await _controller!.resumePreview();
      debugPrint('Camera preview resumed');
    } catch (e) {
      // Log but don't throw - resuming should be safe
      if (kDebugMode) {
        debugPrint('Error resuming camera: $e');
      }
      // If resume fails, try re-initializing
      try {
        debugPrint('Attempting to re-initialize camera after resume failure');
        await initializeCamera();
      } catch (initError) {
        if (kDebugMode) {
          debugPrint(
            'Error re-initializing camera after resume failure: $initError',
          );
        }
      }
    }
  }

  /// Dispose of the camera controller
  void dispose() {
    try {
      // Stop any ongoing picture capture if possible
      if (_controller != null && _controller!.value.isInitialized) {
        // Note: CameraController doesn't have a direct way to cancel takePicture()
        // but we can at least ensure proper cleanup
        _controller!.dispose();
      } else if (_controller != null) {
        _controller!.dispose();
      }
    } catch (e) {
      // Log but don't throw - disposal should be safe
      if (kDebugMode) {
        debugPrint('Error disposing camera controller: $e');
      }
    } finally {
      _controller = null;
      _initializeControllerFuture = null;
    }
  }
}
