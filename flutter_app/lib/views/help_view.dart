import 'package:flutter/material.dart';

/// Help screen with usage instructions and tips for the lawn bowls measuring app
class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        title: const Text(
          'Help & Instructions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // How to Use Section
              _buildSectionTitle('How to Use'),
              const SizedBox(height: 16),
              _buildInstructionStep(
                '1.',
                'Hold your phone directly above the jack and bowls.',
                Icons.phone_android,
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                '2.',
                'Tap the large \'Measure\' button.',
                Icons.camera_alt,
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                '3.',
                'View the ranked results.',
                Icons.format_list_numbered,
              ),
              
              const SizedBox(height: 32),
              
              // Tips Section
              _buildSectionTitle('Tips for Best Results'),
              const SizedBox(height: 16),
              _buildTip(
                'Avoid strong shadows across the bowls.',
                Icons.wb_sunny_outlined,
              ),
              const SizedBox(height: 12),
              _buildTip(
                'Make sure the jack is clearly visible.',
                Icons.visibility,
              ),
              const SizedBox(height: 12),
              _buildTip(
                'Hold the phone steady while measuring.',
                Icons.pan_tool_outlined,
              ),
              
              const SizedBox(height: 40),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  /// Build an instruction step with number, text, and icon
  Widget _buildInstructionStep(String number, String instruction, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[200]!,
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
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Instruction Text
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Icon(
            icon,
            color: Colors.blue[600],
            size: 28,
          ),
        ],
      ),
    );
  }

  /// Build a tip with icon and text
  Widget _buildTip(String tip, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}