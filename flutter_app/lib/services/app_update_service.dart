import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for checking if app updates are available by comparing
/// local version against a remote version string.
class AppUpdateService {
  final PackageInfo? _packageInfo;
  final String _versionUrl;

  /// Creates an AppUpdateService instance.
  ///
  /// If [packageInfo] is provided, it will be used instead of fetching
  /// from platform. This is useful for testing.
  ///
  /// If [versionUrl] is provided, it will be used instead of the default URL.
  /// This is useful for testing or custom endpoints.
  AppUpdateService({
    PackageInfo? packageInfo,
    String? versionUrl,
  })  : _packageInfo = packageInfo,
        _versionUrl = versionUrl ??
            'https://example.com/standnmeasure/latest_version.json';

  /// Fetches the latest remote version from the configured URL.
  ///
  /// Expects a JSON response with a 'version' field containing the version string.
  /// Example JSON: `{"version": "1.0.0+2"}`
  ///
  /// Throws an exception if the network request fails or the response is invalid.
  Future<String> getLatestRemoteVersion() async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch version: HTTP ${response.statusCode}',
        );
      }

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final version = jsonData['version'] as String?;

      if (version == null || version.isEmpty) {
        throw Exception(
            'Invalid version response: missing or empty version field');
      }

      return version;
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Failed to parse version response: ${e.message}');
      }
      rethrow;
    }
  }

  /// Checks if an update is available by comparing the local app version
  /// against the provided remote version string.
  ///
  /// Returns `true` if the local version is older than the remote version,
  /// `false` if the local version is the same or newer.
  ///
  /// Version strings should follow semantic versioning format:
  /// `major.minor.patch+build` (e.g., "1.0.0+1")
  ///
  /// The comparison follows standard pubspec versioning rules:
  /// - First compares major.minor.patch (semantic version)
  /// - If equal, compares build number
  /// - Returns true if remote version is greater than local version
  Future<bool> isUpdateAvailable(String latestRemoteVersion) async {
    final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;

    return _compareVersions(localVersion, latestRemoteVersion) < 0;
  }

  /// Compares two version strings following pubspec versioning rules.
  ///
  /// Returns:
  /// - Negative value if version1 < version2
  /// - Zero if version1 == version2
  /// - Positive value if version1 > version2
  int _compareVersions(String version1, String version2) {
    // Parse versions into semantic version and build number
    final v1Parts = _parseVersion(version1);
    final v2Parts = _parseVersion(version2);

    // Compare semantic version (major.minor.patch)
    final semanticComparison = _compareSemanticVersion(
      v1Parts['semantic']!,
      v2Parts['semantic']!,
    );

    // If semantic versions differ, return that comparison
    if (semanticComparison != 0) {
      return semanticComparison;
    }

    // If semantic versions are equal, compare build numbers
    final build1 = v1Parts['build'] ?? 0;
    final build2 = v2Parts['build'] ?? 0;
    return build1.compareTo(build2);
  }

  /// Parses a version string into semantic version and build number.
  ///
  /// Returns a map with 'semantic' (String) and 'build' (int) keys.
  Map<String, dynamic> _parseVersion(String version) {
    // Split on '+' to separate semantic version from build number
    final parts = version.split('+');
    final semantic = parts[0].trim();
    final build = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;

    return {
      'semantic': semantic,
      'build': build,
    };
  }

  /// Compares two semantic version strings (major.minor.patch).
  ///
  /// Returns:
  /// - Negative value if v1 < v2
  /// - Zero if v1 == v2
  /// - Positive value if v1 > v2
  int _compareSemanticVersion(String v1, String v2) {
    final v1Parts =
        v1.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final v2Parts =
        v2.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();

    // Ensure both lists have at least 3 parts (major.minor.patch)
    while (v1Parts.length < 3) {
      v1Parts.add(0);
    }
    while (v2Parts.length < 3) {
      v2Parts.add(0);
    }

    // Compare major version
    if (v1Parts[0] != v2Parts[0]) {
      return v1Parts[0].compareTo(v2Parts[0]);
    }

    // Compare minor version
    if (v1Parts[1] != v2Parts[1]) {
      return v1Parts[1].compareTo(v2Parts[1]);
    }

    // Compare patch version
    return v1Parts[2].compareTo(v2Parts[2]);
  }
}
