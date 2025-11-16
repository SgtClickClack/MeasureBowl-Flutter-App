import 'package:flutter/material.dart';

/// Widget that displays the app header with title and help button
class AppHeaderWidget extends StatelessWidget {
  final VoidCallback? onHelpPressed;

  const AppHeaderWidget({super.key, this.onHelpPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'Stand \'n\' Measure',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'One-shot measurement',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays the help button
class HelpButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;

  const HelpButtonWidget({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.help_outline, color: Colors.white, size: 28),
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
