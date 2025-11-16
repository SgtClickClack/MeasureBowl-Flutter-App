import 'package:flutter/material.dart';

/// Widget that displays the measure button with loading states
class MeasureButtonWidget extends StatelessWidget {
  final bool isMeasuring;
  final bool isProcessing;
  final VoidCallback onPressed;

  const MeasureButtonWidget({
    super.key,
    required this.isMeasuring,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: (isMeasuring || isProcessing) ? 100 : 120,
        height: (isMeasuring || isProcessing) ? 100 : 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isMeasuring || isProcessing)
              ? Colors.blue[300]
              : Colors.blue[600],
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: (isMeasuring || isProcessing)
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
            : const Icon(Icons.camera_alt, color: Colors.white, size: 40),
      ),
    );
  }
}
