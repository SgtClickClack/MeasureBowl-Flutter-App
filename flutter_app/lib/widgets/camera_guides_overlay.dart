import 'package:flutter/material.dart';

/// Custom painter for drawing camera guides (crosshairs)
class _GuidesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal line (center)
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw vertical line (center)
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GuidesPainter oldDelegate) => false;
}

/// Widget that displays camera guides overlay (crosshairs) on the camera preview
class CameraGuidesOverlay extends StatelessWidget {
  const CameraGuidesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          key: const Key('camera_guides'),
          painter: _GuidesPainter(),
        ),
      ),
    );
  }
}
