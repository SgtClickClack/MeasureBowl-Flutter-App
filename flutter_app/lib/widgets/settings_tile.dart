import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// A reusable settings tile widget that provides consistent styling
/// across the application for settings list items.
///
/// This widget wraps a [ListTile] with predefined styles from [AppStyles]
/// to ensure design consistency.
class SettingsTile extends StatelessWidget {
  /// The title text displayed in the tile
  final String title;

  /// Optional subtitle text displayed below the title
  final String? subtitle;

  /// Optional leading icon displayed before the title
  final IconData? icon;

  /// Optional callback when the tile is tapped
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., dropdown, custom icon)
  /// If not provided and [onTap] is set, defaults to [Icons.chevron_right]
  final Widget? trailing;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme colors to ensure proper contrast
    final textColor = Theme.of(context).colorScheme.onSurface;
    final iconColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    // Determine trailing widget
    Widget? trailingWidget = trailing;
    if (trailingWidget == null && onTap != null) {
      trailingWidget = Icon(Icons.chevron_right, color: iconColor);
    }

    return ListTile(
      textColor: textColor, // Set ListTile's textColor property
      iconColor: iconColor, // Set ListTile's iconColor property
      leading: icon != null ? Icon(icon, color: iconColor) : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppStyles.kFontSizeTitle,
          color: textColor, // Explicitly use theme color
          fontWeight: FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: AppStyles.kFontSizeSubtitle,
                color: textColor.withValues(
                    alpha: 0.7), // Slightly lighter for subtitles
              ),
            )
          : null,
      trailing: trailingWidget,
      onTap: onTap,
    );
  }
}
