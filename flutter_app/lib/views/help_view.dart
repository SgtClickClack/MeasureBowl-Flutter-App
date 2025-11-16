import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';

/// Help screen with usage instructions and tips for the lawn bowls measuring app
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Help & Instructions'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppStyles.kSpacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // How to Use Section
              _buildSectionTitle(context, 'How to Use'),
              const SizedBox(height: AppStyles.kSpacingMedium),
              _buildInstructionStep(
                context,
                '1.',
                'Hold your phone directly above the jack and bowls.',
                Icons.phone_android,
              ),
              const SizedBox(height: AppStyles.kSpacingSmall),
              _buildInstructionStep(
                context,
                '2.',
                'Tap the large \'Measure\' button.',
                Icons.camera_alt,
              ),
              const SizedBox(height: AppStyles.kSpacingSmall),
              _buildInstructionStep(
                context,
                '3.',
                'View the ranked results.',
                Icons.format_list_numbered,
              ),

              const SizedBox(height: AppStyles.kSpacingLarge),

              // Tips Section
              _buildSectionTitle(context, 'Tips for Best Results'),
              const SizedBox(height: AppStyles.kSpacingMedium),
              _buildTip(
                context,
                'Avoid strong shadows across the bowls.',
                Icons.wb_sunny_outlined,
              ),
              const SizedBox(height: AppStyles.kSpacingSmall),
              _buildTip(
                context,
                'Make sure the jack is clearly visible.',
                Icons.visibility,
              ),
              const SizedBox(height: AppStyles.kSpacingSmall),
              _buildTip(
                context,
                'Hold the phone steady while measuring.',
                Icons.pan_tool_outlined,
              ),

              const SizedBox(height: AppStyles.kSpacingLarge * 2),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppStyles.kSpacingMedium),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: AppStyles.kFontSizeTitle,
                      fontWeight: AppStyles.kFontWeightBold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a section title with large, bold text
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize:
            AppStyles.kFontSizeTitle + 6, // Slightly larger for section headers
        fontWeight: AppStyles.kFontWeightBold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Build an instruction step with number, text, and icon
  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String instruction,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppStyles.kSpacingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Step Number Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: AppStyles.kFontSizeTitle,
                  fontWeight: AppStyles.kFontWeightBold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppStyles.kSpacingMedium),
          // Instruction Text
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: AppStyles.kFontSizeTitle,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: AppStyles.kSpacingSmall),
          // Icon
          Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            size: 28,
          ),
        ],
      ),
    );
  }

  /// Build a tip with icon and text
  Widget _buildTip(BuildContext context, String tip, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppStyles.kSpacingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(width: AppStyles.kSpacingSmall),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: AppStyles.kFontSizeBody,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
