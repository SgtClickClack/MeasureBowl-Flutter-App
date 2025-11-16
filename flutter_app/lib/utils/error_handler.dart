import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom exception classes for better error handling
class CameraException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CameraException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'CameraException: $message';
}

class ImageProcessingException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ImageProcessingException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'ImageProcessingException: $message';
}

class StorageException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const StorageException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'StorageException: $message';
}

/// Error handler utility class
class ErrorHandler {
  /// Handle and log errors with appropriate context
  static void handleError(
    dynamic error,
    String context, {
    String? userId,
    Map<String, dynamic>? additionalData,
    StackTrace? stackTrace,
  }) {
    final errorInfo = {
      'context': context,
      'error': error.toString(),
      'errorType': error.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'additionalData': additionalData,
    };

    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('ERROR in $context');
      debugPrint('Error type: ${error.runtimeType}');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      } else if (error is Error) {
        debugPrint('Stack trace: ${error.stackTrace}');
      }
      debugPrint('Error details: $errorInfo');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry
    _logErrorToService(errorInfo);
  }

  /// Log error to external service (implement based on your needs)
  static void _logErrorToService(Map<String, dynamic> errorInfo) {
    // TODO: Implement crash reporting service integration
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Show user-friendly error message
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error dialog with retry option
  static Future<bool> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String retryText = 'Retry',
    String cancelText = 'Cancel',
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(retryText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Convert exception to user-friendly message
  static String getErrorMessage(dynamic error) {
    // Log the full error details for debugging
    if (kDebugMode) {
      debugPrint(
          'ErrorHandler.getErrorMessage: Error type: ${error.runtimeType}');
      debugPrint('ErrorHandler.getErrorMessage: Error toString: $error');
      if (error is Error) {
        debugPrint(
            'ErrorHandler.getErrorMessage: Stack trace: ${error.stackTrace}');
      }
    }

    if (error is CameraException) {
      switch (error.code) {
        case 'CAMERA_PERMISSION_DENIED':
          return 'Camera permission is required to take photos. Please enable camera access in your device settings.';
        case 'CAMERA_NOT_AVAILABLE':
          return 'Camera is not available on this device.';
        case 'CAMERA_INITIALIZATION_FAILED':
          return 'Failed to initialize camera. Please try again.';
        case 'CAMERA_BUSY':
          return 'Camera is busy. Please wait a moment and try again.';
        case 'CAMERA_ERROR':
          return 'Camera encountered an error. Please try again.';
        case 'CAMERA_CAPTURE_FAILED':
          return 'Failed to capture image. Please try again.';
        case 'CAMERA_SAVE_FAILED':
          return 'Failed to save image. Please check storage permissions and try again.';
        default:
          return 'Camera error: ${error.message}';
      }
    }

    // Check for PlatformException (common for native errors)
    if (error is PlatformException) {
      final code = error.code;
      final message = error.message ?? '';
      if (kDebugMode) {
        debugPrint('PlatformException code: $code, message: $message');
      }

      if (code.contains('camera') ||
          code.contains('Camera') ||
          message.toLowerCase().contains('camera')) {
        if (message.toLowerCase().contains('permission')) {
          return 'Camera permission denied. Please enable camera access in Settings.';
        }
        if (message.toLowerCase().contains('in use') ||
            message.toLowerCase().contains('busy')) {
          return 'Camera is in use by another app. Please close other camera apps and try again.';
        }
        return 'Camera initialization failed: $message';
      }
      return 'System error: $message';
    }

    // Fallback: check string representation for PlatformException
    if (error.toString().contains('PlatformException')) {
      if (error.toString().toLowerCase().contains('camera')) {
        return 'Camera initialization failed. The camera may be in use by another app. Please close other camera apps and try again.';
      }
      return 'A system error occurred. Please try again.';
    }

    if (error is ImageProcessingException) {
      switch (error.code) {
        case 'OPENCV_NOT_LOADED':
          return 'Image processing library is not ready. Please wait a moment and try again.';
        case 'NO_JACK_DETECTED':
          return 'Could not detect the jack in the image. Please ensure the jack is clearly visible and well-lit.';
        case 'NO_BOWLS_DETECTED':
          return 'Could not detect any bowls in the image. Please ensure bowls are clearly visible.';
        case 'INVALID_IMAGE_FORMAT':
          return 'Invalid image format. Please try taking the photo again.';
        default:
          return 'Image processing error: ${error.message}';
      }
    }

    if (error is StorageException) {
      switch (error.code) {
        case 'STORAGE_PERMISSION_DENIED':
          return 'Storage permission is required to save photos. Please enable storage access in your device settings.';
        case 'INSUFFICIENT_STORAGE':
          return 'Insufficient storage space. Please free up some space and try again.';
        default:
          return 'Storage error: ${error.message}';
      }
    }

    // Generic error messages
    if (error.toString().contains('permission')) {
      return 'Permission denied. Please check your app permissions in device settings.';
    }

    if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Default fallback message - include error details in debug mode
    final errorString = error.toString();
    if (kDebugMode) {
      // In debug mode, include more details
      return 'An unexpected error occurred: ${errorString.length > 100 ? errorString.substring(0, 100) + "..." : errorString}. Please try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Wrap async operations with error handling
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation,
    String context, {
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        context,
        userId: userId,
        additionalData: additionalData,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a safe async operation that returns a result
  static Future<Result<T, String>> safeAsync<T>(
    Future<T> Function() operation,
    String context,
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      final message = getErrorMessage(error);
      handleError(error, context, stackTrace: stackTrace);
      return Result.failure(message);
    }
  }
}

/// Result class for handling success/failure states
class Result<T, E> {
  final T? _value;
  final E? _error;
  final bool _isSuccess;

  const Result._(this._value, this._error, this._isSuccess);

  factory Result.success(T value) => Result._(value, null, true);
  factory Result.failure(E error) => Result._(null, error, false);

  bool get isSuccess => _isSuccess;
  bool get isFailure => !_isSuccess;

  T get value {
    if (_isSuccess) return _value!;
    throw StateError('Cannot get value from failed result');
  }

  E get error {
    if (isFailure) return _error!;
    throw StateError('Cannot get error from successful result');
  }

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    if (_isSuccess) {
      return success(_value!);
    } else {
      return failure(_error!);
    }
  }
}
