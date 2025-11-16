import 'package:flutter/material.dart';

/// Measurement unit options
enum MeasurementUnit {
  metric,
  imperial;

  /// Get the display label for the measurement unit
  String get label {
    switch (this) {
      case MeasurementUnit.metric:
        return 'Metric';
      case MeasurementUnit.imperial:
        return 'Imperial';
    }
  }
}

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system;

  /// Get the display label for the theme mode
  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  /// Convert AppThemeMode to Flutter's ThemeMode
  ThemeMode get toFlutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Model representing application settings
class AppSettings {
  final bool proAccuracyMode;
  final MeasurementUnit measurementUnit;
  final AppThemeMode themeMode;
  final bool showCameraGuides;
  final double jackDiameterMm;

  AppSettings({
    this.proAccuracyMode = false,
    this.measurementUnit = MeasurementUnit.metric,
    this.themeMode = AppThemeMode.system,
    this.showCameraGuides = false,
    this.jackDiameterMm = 63.5,
  });

  /// Create default settings
  static AppSettings defaults() {
    return AppSettings(
      jackDiameterMm: 63.5,
    );
  }

  /// Create a copy with updated values
  AppSettings copyWith({
    bool? proAccuracyMode,
    MeasurementUnit? measurementUnit,
    AppThemeMode? themeMode,
    bool? showCameraGuides,
    double? jackDiameterMm,
  }) {
    return AppSettings(
      proAccuracyMode: proAccuracyMode ?? this.proAccuracyMode,
      measurementUnit: measurementUnit ?? this.measurementUnit,
      themeMode: themeMode ?? this.themeMode,
      showCameraGuides: showCameraGuides ?? this.showCameraGuides,
      jackDiameterMm: jackDiameterMm ?? this.jackDiameterMm,
    );
  }

  /// Convert AppSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'proAccuracyMode': proAccuracyMode,
      'measurementUnit': measurementUnit.name,
      'themeMode': themeMode.name,
      'showCameraGuides': showCameraGuides,
      'jackDiameterMm': jackDiameterMm,
    };
  }

  /// Create AppSettings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      proAccuracyMode: json['proAccuracyMode'] ?? false,
      measurementUnit: MeasurementUnit.values.byName(
        json['measurementUnit'] ?? 'metric',
      ),
      themeMode: AppThemeMode.values.byName(
        json['themeMode'] ?? 'system',
      ),
      showCameraGuides: json['showCameraGuides'] ?? false,
      jackDiameterMm: (json['jackDiameterMm'] as num?)?.toDouble() ?? 63.5,
    );
  }
}
