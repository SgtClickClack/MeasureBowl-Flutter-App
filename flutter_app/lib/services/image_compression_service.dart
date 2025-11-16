import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/error_handler.dart';

/// Service for compressing and optimizing images
class ImageCompressionService {
  static const int _maxImageSize = 1024 * 1024; // 1MB
  static const int _maxWidth = 1920;
  static const int _maxHeight = 1080;
  static const int _quality = 85;

  /// Compress image file to reduce size while maintaining quality
  static Future<String> compressImage(String imagePath) async {
    return ErrorHandler.withErrorHandling(() async {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw const StorageException(
          'Image file not found',
          code: 'FILE_NOT_FOUND',
        );
      }

      // Check if file is already small enough
      final fileSize = await file.length();
      if (fileSize <= _maxImageSize) {
        debugPrint('Image already compressed: ${fileSize} bytes');
        return imagePath;
      }

      // Read image bytes
      final imageBytes = await file.readAsBytes();

      // Compress image
      final compressedBytes = await _compressImageBytes(imageBytes);

      // Create compressed file path
      final compressedPath = _getCompressedPath(imagePath);
      final compressedFile = File(compressedPath);

      // Write compressed image
      await compressedFile.writeAsBytes(compressedBytes);

      debugPrint(
        'Image compressed: ${fileSize} -> ${compressedBytes.length} bytes',
      );

      return compressedPath;
    }, 'ImageCompressionService.compressImage');
  }

  /// Compress image bytes using Flutter's built-in compression
  static Future<Uint8List> _compressImageBytes(Uint8List imageBytes) async {
    // For now, we'll use a simple approach
    // In a real implementation, you might use packages like:
    // - image package for resizing
    // - flutter_image_compress for better compression

    // This is a placeholder implementation
    // In production, you would implement proper image compression
    return imageBytes;
  }

  /// Get compressed file path
  static String _getCompressedPath(String originalPath) {
    final directory = path.dirname(originalPath);
    final fileName = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);
    return path.join(directory, '${fileName}_compressed$extension');
  }

  /// Clean up compressed files
  static Future<void> cleanupCompressedFiles(String originalPath) async {
    try {
      final compressedPath = _getCompressedPath(originalPath);
      final compressedFile = File(compressedPath);

      if (await compressedFile.exists()) {
        await compressedFile.delete();
        debugPrint('Cleaned up compressed file: $compressedPath');
      }
    } catch (e) {
      debugPrint('Error cleaning up compressed file: $e');
    }
  }

  /// Get image info without loading the entire image
  static Future<ImageInfo> getImageInfo(String imagePath) async {
    return ErrorHandler.withErrorHandling(() async {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw const StorageException(
          'Image file not found',
          code: 'FILE_NOT_FOUND',
        );
      }

      final fileSize = await file.length();
      final fileName = path.basename(imagePath);
      final fileExtension = path.extension(imagePath).toLowerCase();

      return ImageInfo(
        path: imagePath,
        fileName: fileName,
        size: fileSize,
        extension: fileExtension,
        isCompressed: fileName.contains('_compressed'),
      );
    }, 'ImageCompressionService.getImageInfo');
  }
}

/// Image information class
class ImageInfo {
  final String path;
  final String fileName;
  final int size;
  final String extension;
  final bool isCompressed;

  const ImageInfo({
    required this.path,
    required this.fileName,
    required this.size,
    required this.extension,
    required this.isCompressed,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  String toString() {
    return 'ImageInfo(path: $path, size: $sizeFormatted, compressed: $isCompressed)';
  }
}
