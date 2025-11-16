import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_notifier_provider.dart';
import '../models/app_settings.dart';
import '../widgets/settings_tile.dart';
import '../styles/app_styles.dart';
import 'about_view.dart';
import 'advanced_settings_view.dart';

/// Settings view widget that displays app settings
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings state from Riverpod
    final settings = ref.watch(settingsNotifierProvider);
    // Get the notifier to call update methods
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.kSpacingMedium),
        children: [
          // Measurement Settings Section
          Text(
            'Measurement Settings',
            style: TextStyle(
              fontSize: AppStyles.kFontSizeTitle,
              fontWeight: AppStyles.kFontWeightBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppStyles.kSpacingSmall),
          SettingsTile(
            title: 'Pro Accuracy Mode',
            subtitle: 'slower, but more accurate for spread-out heads.',
            trailing: Switch(
              value: settings.proAccuracyMode,
              onChanged: (bool value) {
                notifier.updateProAccuracy(value);
              },
            ),
          ),
          SettingsTile(
            title: 'Measurement Unit',
            trailing: DropdownButton<MeasurementUnit>(
              value: settings.measurementUnit,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppStyles.kFontSizeTitle,
              ),
              items: MeasurementUnit.values.map((MeasurementUnit unit) {
                return DropdownMenuItem<MeasurementUnit>(
                  value: unit,
                  child: Text(
                    unit.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (MeasurementUnit? newValue) {
                if (newValue != null) {
                  notifier.updateMeasurementUnit(newValue);
                }
              },
            ),
          ),
          const SizedBox(height: AppStyles.kSpacingMedium),

          // Display Settings Section
          Text(
            'Display Settings',
            style: TextStyle(
              fontSize: AppStyles.kFontSizeTitle,
              fontWeight: AppStyles.kFontWeightBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppStyles.kSpacingSmall),
          SettingsTile(
            title: 'Theme Mode',
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: AppStyles.kFontSizeTitle,
              ),
              items: AppThemeMode.values.map((AppThemeMode mode) {
                return DropdownMenuItem<AppThemeMode>(
                  value: mode,
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (AppThemeMode? newValue) {
                if (newValue != null) {
                  notifier.updateThemeMode(newValue);
                }
              },
            ),
          ),
          SettingsTile(
            title: 'Show Camera Guides',
            trailing: Switch(
              value: settings.showCameraGuides,
              onChanged: (bool value) {
                notifier.updateShowCameraGuides(value);
              },
            ),
          ),
          const SizedBox(height: AppStyles.kSpacingMedium),

          // General Settings Section
          Text(
            'General Settings',
            style: TextStyle(
              fontSize: AppStyles.kFontSizeTitle,
              fontWeight: AppStyles.kFontWeightBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppStyles.kSpacingSmall),
          SettingsTile(
            title: 'Advanced Settings',
            onTap: () {
              Navigator.pushNamed(context, AdvancedSettingsView.routeName);
            },
          ),
          SettingsTile(
            title: 'About Stand \'n\' Measure',
            onTap: () {
              Navigator.pushNamed(context, AboutView.routeName);
            },
          ),
        ],
      ),
    );
  }
}
