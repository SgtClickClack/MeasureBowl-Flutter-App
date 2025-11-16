import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_notifier_provider.dart';

/// Advanced Settings view widget
class AdvancedSettingsView extends ConsumerWidget {
  const AdvancedSettingsView({super.key});

  static const String routeName = '/advanced-settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings state from Riverpod
    final settings = ref.watch(settingsNotifierProvider);
    // Get the notifier to call update methods
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jack Diameter (${settings.jackDiameterMm.toStringAsFixed(1)} mm)',
                  style: const TextStyle(fontSize: 16),
                ),
                Slider(
                  value: settings.jackDiameterMm,
                  min: 60.0,
                  max: 70.0,
                  divisions: 100,
                  label: '${settings.jackDiameterMm.toStringAsFixed(1)} mm',
                  onChanged: (double value) {
                    notifier.updateJackDiameter(value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
