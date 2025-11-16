import 'package:flutter/material.dart';
import '../widgets/settings_tile.dart';
import '../styles/app_styles.dart';

/// About page displaying app information
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  /// Route name for navigation
  static const String routeName = '/about';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Stand \'n\' Measure'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppStyles.kSpacingMedium),
        children: const [
          SettingsTile(
            title: 'App version 1.0.0',
          ),
          SettingsTile(
            title: 'Core Functionality',
            subtitle: 'AI-Assisted Measurement',
          ),
        ],
      ),
    );
  }
}
