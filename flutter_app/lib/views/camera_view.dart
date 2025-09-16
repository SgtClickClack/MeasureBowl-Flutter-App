import 'package:flutter/material.dart';
import '../models/measurement_result.dart';
import 'results_view.dart';

/// Camera view widget that displays the camera feed placeholder and measure button
class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  bool _isMeasuring = false;

  /// Handle the measure button press
  void _onMeasurePressed() async {
    // Prevent multiple simultaneous measurements
    if (_isMeasuring) return;

    setState(() {
      _isMeasuring = true;
    });

    // Simulate processing time (remove when actual camera/processing is implemented)
    await Future.delayed(const Duration(milliseconds: 800));

    // Create mock measurement results
    final mockResults = MeasurementResult.createMock();

    setState(() {
      _isMeasuring = false;
    });

    // Navigate to results view
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsView(
            measurementResult: mockResults,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Camera feed placeholder (black background)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white54,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Camera Feed Placeholder',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Point camera at lawn bowls',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // App title overlay at top
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Lawn Bowls Measure',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'One-shot measurement',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Measure button at bottom center
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _onMeasurePressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _isMeasuring ? 100 : 120,
                    height: _isMeasuring ? 100 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isMeasuring 
                          ? Colors.blue[300] 
                          : Colors.blue[600],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isMeasuring
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),

            // Instructions at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                _isMeasuring ? 'Measuring...' : 'Tap to measure distances',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}