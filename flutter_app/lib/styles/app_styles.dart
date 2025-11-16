import 'package:flutter/material.dart';

/// Global style constants for consistent spacing, typography, and design
/// across the application.
class AppStyles {
  AppStyles._(); // Private constructor to prevent instantiation

  // Spacing constants
  /// Small spacing (8.0) - used for section header spacing
  static const double kSpacingSmall = 8.0;

  /// Medium spacing (16.0) - used for list padding and section spacing
  static const double kSpacingMedium = 16.0;

  /// Large spacing (24.0) - used for larger gaps
  static const double kSpacingLarge = 24.0;

  // Font size constants
  /// Title font size (18.0) - used for section headers and ListTile titles
  static const double kFontSizeTitle = 18.0;

  /// Subtitle font size (14.0) - used for ListTile subtitles
  static const double kFontSizeSubtitle = 14.0;

  /// Body font size (16.0) - used for body text
  static const double kFontSizeBody = 16.0;

  // Font weight constants
  /// Bold font weight - used for section headers
  static const FontWeight kFontWeightBold = FontWeight.bold;

  /// Normal font weight - used for regular text
  static const FontWeight kFontWeightNormal = FontWeight.normal;
}
