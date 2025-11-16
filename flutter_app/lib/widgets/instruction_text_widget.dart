import 'package:flutter/material.dart';

/// Widget that displays instruction text at the bottom of the screen
class InstructionTextWidget extends StatelessWidget {
  final bool isProcessing;
  final bool isMeasuring;

  const InstructionTextWidget({
    super.key,
    required this.isProcessing,
    required this.isMeasuring,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Text(
        _getInstructionText(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInstructionText() {
    if (isProcessing) {
      return 'Processing with OpenCV...';
    } else if (isMeasuring) {
      return 'Capturing image...';
    } else {
      return 'Tap to measure distances';
    }
  }
}
