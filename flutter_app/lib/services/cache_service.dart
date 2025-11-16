import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/error_handler.dart';

/// Service for caching processed measurement results
class CacheService {
  static const String _cacheDirName = 'measurement_cache';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxCacheAge =
      7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

  static Directory? _cacheDir;

  /// Initialize cache directory
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory(path.join(appDir.path, _cacheDirName));

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Clean up old cache entries
      await _cleanupOldCache();

      debugPrint('Cache initialized: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('Error initializing cache: $e');
    }
  }

  /// Cache measurement result
  static Future<void> cacheMeasurementResult(
    String imagePath,
    Map<String, dynamic> result,
  ) async {
    if (_cacheDir == null) await initialize();

    try {
      final cacheKey = _generateCacheKey(imagePath);
      final cacheFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));

      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'imagePath': imagePath,
        'result': result,
      };

      await cacheFile.writeAsString(jsonEncode(cacheData));
      debugPrint('Cached measurement result: $cacheKey');
    } catch (e) {
      debugPrint('Error caching measurement result: $e');
    }
  }

  /// Get cached measurement result
  static Future<Map<String, dynamic>?> getCachedMeasurementResult(
    String imagePath,
  ) async {
    if (_cacheDir == null) await initialize();

    try {
      final cacheKey = _generateCacheKey(imagePath);
      final cacheFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));

      if (!await cacheFile.exists()) {
        return null;
      }

      final cacheData = jsonDecode(await cacheFile.readAsString());
      final timestamp = cacheData['timestamp'] as int;

      // Check if cache is still valid
      if (DateTime.now().millisecondsSinceEpoch - timestamp > _maxCacheAge) {
        await cacheFile.delete();
        return null;
      }

      debugPrint('Retrieved cached measurement result: $cacheKey');
      return cacheData['result'] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error retrieving cached measurement result: $e');
      return null;
    }
  }

  /// Check if measurement result is cached
  static Future<bool> isCached(String imagePath) async {
    if (_cacheDir == null) await initialize();

    try {
      final cacheKey = _generateCacheKey(imagePath);
      final cacheFile = File(path.join(_cacheDir!.path, '$cacheKey.json'));

      if (!await cacheFile.exists()) {
        return false;
      }

      final cacheData = jsonDecode(await cacheFile.readAsString());
      final timestamp = cacheData['timestamp'] as int;

      // Check if cache is still valid
      return DateTime.now().millisecondsSinceEpoch - timestamp <= _maxCacheAge;
    } catch (e) {
      debugPrint('Error checking cache: $e');
      return false;
    }
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    if (_cacheDir == null) await initialize();

    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
        debugPrint('Cache cleared');
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  static Future<CacheStats> getCacheStats() async {
    if (_cacheDir == null) await initialize();

    try {
      final files = await _cacheDir!.list().toList();
      int totalSize = 0;
      int fileCount = 0;
      int validEntries = 0;

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          fileCount++;
          totalSize += await file.length();

          try {
            final cacheData = jsonDecode(await file.readAsString());
            final timestamp = cacheData['timestamp'] as int;

            if (DateTime.now().millisecondsSinceEpoch - timestamp <=
                _maxCacheAge) {
              validEntries++;
            }
          } catch (e) {
            // Invalid cache file, will be cleaned up
          }
        }
      }

      return CacheStats(
        totalSize: totalSize,
        fileCount: fileCount,
        validEntries: validEntries,
        maxSize: _maxCacheSize,
        maxAge: _maxCacheAge,
      );
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return CacheStats(
        totalSize: 0,
        fileCount: 0,
        validEntries: 0,
        maxSize: _maxCacheSize,
        maxAge: _maxCacheAge,
      );
    }
  }

  /// Generate cache key from image path
  static String _generateCacheKey(String imagePath) {
    // Use file modification time and path to generate unique key
    final fileName = path.basename(imagePath);
    final fileStat = File(imagePath).statSync();
    return '${fileName}_${fileStat.modified.millisecondsSinceEpoch}';
  }

  /// Clean up old cache entries
  static Future<void> _cleanupOldCache() async {
    try {
      final files = await _cacheDir!.list().toList();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final cacheData = jsonDecode(await file.readAsString());
            final timestamp = cacheData['timestamp'] as int;

            if (now - timestamp > _maxCacheAge) {
              await file.delete();
              debugPrint('Cleaned up old cache entry: ${file.path}');
            }
          } catch (e) {
            // Invalid cache file, delete it
            await file.delete();
            debugPrint('Deleted invalid cache file: ${file.path}');
          }
        }
      }

      // Check total cache size and clean up if necessary
      await _enforceCacheSizeLimit();
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }

  /// Enforce cache size limit
  static Future<void> _enforceCacheSizeLimit() async {
    try {
      final stats = await getCacheStats();

      if (stats.totalSize > _maxCacheSize) {
        // Delete oldest files first
        final files = await _cacheDir!.list().toList();
        final fileInfos = <FileInfo>[];

        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            try {
              final cacheData = jsonDecode(await file.readAsString());
              final timestamp = cacheData['timestamp'] as int;
              final size = await file.length();

              fileInfos.add(
                FileInfo(file: file, timestamp: timestamp, size: size),
              );
            } catch (e) {
              // Invalid file, delete it
              await file.delete();
            }
          }
        }

        // Sort by timestamp (oldest first)
        fileInfos.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Delete files until under size limit
        int currentSize = stats.totalSize;
        for (final fileInfo in fileInfos) {
          if (currentSize <= _maxCacheSize) break;

          await fileInfo.file.delete();
          currentSize -= fileInfo.size;
          debugPrint(
            'Deleted cache file to enforce size limit: ${fileInfo.file.path}',
          );
        }
      }
    } catch (e) {
      debugPrint('Error enforcing cache size limit: $e');
    }
  }
}

/// Cache statistics
class CacheStats {
  final int totalSize;
  final int fileCount;
  final int validEntries;
  final int maxSize;
  final int maxAge;

  const CacheStats({
    required this.totalSize,
    required this.fileCount,
    required this.validEntries,
    required this.maxSize,
    required this.maxAge,
  });

  String get totalSizeFormatted {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get maxSizeFormatted {
    if (maxSize < 1024) return '${maxSize}B';
    if (maxSize < 1024 * 1024)
      return '${(maxSize / 1024).toStringAsFixed(1)}KB';
    return '${(maxSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  double get usagePercentage => (totalSize / maxSize) * 100;

  @override
  String toString() {
    return 'CacheStats(size: $totalSizeFormatted/$maxSizeFormatted, files: $fileCount, valid: $validEntries, usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}

/// File information for cache management
class FileInfo {
  final File file;
  final int timestamp;
  final int size;

  const FileInfo({
    required this.file,
    required this.timestamp,
    required this.size,
  });
}
